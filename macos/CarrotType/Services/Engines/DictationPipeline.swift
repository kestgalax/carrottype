import AVFoundation
import Foundation

enum DictationPhase: Sendable {
    case transcribing
    case cleaning
}

protocol STTEngine: Sendable {
    func transcribe(audioURL: URL, modelPath: String?) async throws -> String
    func unload() async
}

protocol CleanupEngine: Sendable {
    func cleanup(
        text: String,
        mode: CleanupMode,
        modelDirectory: URL?,
        instructions: String?
    ) async throws -> String
    func unload() async
}

/// Holds the streaming actor so the audio tap can call `feed` without hopping to the main actor.
private final class ParakeetStreamingBox: @unchecked Sendable {
    let engine = ParakeetStreamingEngine()
}

/// Orchestrates STT → cleanup with engine selection from ModelManager.
/// Live draft (ADR-014) uses Parakeet streaming when the active package supports it.
@MainActor
final class DictationPipeline {
    private let modelManager: ModelManager
    private let whisper = WhisperSTTEngine()
    private let parakeet = ParakeetSTTEngine()
    private let streamingBox = ParakeetStreamingBox()
    private let appleSpeech = AppleSpeechSTTEngine()
    private let lightCleanup = LightCleanupEngine()
    private let qwenCleanup = QwenCleanupEngine()

    /// True while a live-draft streaming session is accepting audio.
    private(set) var isLiveDraftActive = false

    private var parakeetStreaming: ParakeetStreamingEngine { streamingBox.engine }

    init(modelManager: ModelManager) {
        self.modelManager = modelManager
    }

    /// Start SlidingWindow streaming for the active Parakeet package when possible.
    /// On failure, logs and returns false so the caller keeps the file-only path.
    func startLiveDraftIfPossible(
        languageCode: String?,
        onUpdate: @escaping @Sendable (LiveTranscript) -> Void
    ) async -> Bool {
        await cancelLiveDraft()
        guard modelManager.selectedSTTSupportsStreaming else { return false }
        guard let modelPath = modelManager.selectedSTTModelPath() else { return false }

        let packageID = modelManager.activeSTTID
        do {
            try await parakeetStreaming.start(
                modelDirectory: URL(fileURLWithPath: modelPath, isDirectory: true),
                packageID: packageID,
                languageCode: languageCode,
                onUpdate: onUpdate
            )
            isLiveDraftActive = true
            return true
        } catch is CancellationError {
            // Start lost the race (cancel or a newer start) and did not publish.
            // Unload here would invalidate that newer session.
            return false
        } catch {
            NSLog("CarrotType: live draft streaming failed to start: %@", error.localizedDescription)
            isLiveDraftActive = false
            await parakeetStreaming.unload()
            return false
        }
    }

    /// Safe from the audio tap: ordered sync yield into the streaming feed bridge.
    nonisolated func feedLiveDraft(_ buffer: AVAudioPCMBuffer) {
        streamingBox.engine.feed(buffer)
    }

    func cancelLiveDraft() async {
        isLiveDraftActive = false
        await parakeetStreaming.cancel()
    }

    func run(
        audioURL: URL,
        onPhase: @escaping @Sendable (DictationPhase) -> Void
    ) async throws -> String {
        try await run(
            audioURL: audioURL,
            useLiveDraftResult: false,
            offlineSecondPass: false,
            onPhase: onPhase
        )
    }

    /// Prefer streaming `finish()` when live draft was active; optionally re-run offline on the WAV.
    /// If streaming finish fails, falls back silently to the file STT path.
    func run(
        audioURL: URL,
        useLiveDraftResult: Bool,
        offlineSecondPass: Bool,
        onPhase: @escaping @Sendable (DictationPhase) -> Void
    ) async throws -> String {
        onPhase(.transcribing)

        var raw: String?
        if useLiveDraftResult, isLiveDraftActive {
            do {
                let streamed = try await parakeetStreaming.finish()
                isLiveDraftActive = false
                if offlineSecondPass {
                    do {
                        raw = try await parakeetStreaming.transcribeOffline(audioURL: audioURL)
                    } catch {
                        NSLog(
                            "CarrotType: live draft offline second pass failed, using stream finish: %@",
                            error.localizedDescription
                        )
                        raw = streamed
                    }
                } else {
                    raw = streamed
                }
            } catch {
                NSLog(
                    "CarrotType: live draft finish failed, falling back to file STT: %@",
                    error.localizedDescription
                )
                isLiveDraftActive = false
                await parakeetStreaming.unload()
                raw = nil
            }
        } else if isLiveDraftActive {
            isLiveDraftActive = false
            await parakeetStreaming.cancel()
        }

        if raw == nil {
            let stt = selectedSTTEngine()
            let modelPath = modelManager.selectedSTTModelPath()
            raw = try await stt.transcribe(audioURL: audioURL, modelPath: modelPath)
        }

        await parakeetStreaming.unload()

        guard let raw else { throw STTEngineError.emptyResult }

        onPhase(.cleaning)
        let mode = modelManager.cleanupMode
        if mode.usesMLXHelper, modelManager.cleanupModelDirectory() == nil {
            // Package still downloading / missing — keep STT result via Light (download offered on select).
            return try await lightCleanup.cleanup(text: raw, mode: .light, modelDirectory: nil, instructions: nil)
        }
        do {
            let directory = modelManager.cleanupModelDirectory()
            return try await selectedCleanupEngine(for: mode)
                .cleanup(text: raw, mode: mode, modelDirectory: directory, instructions: nil)
        } catch {
            // Never lose the STT result if Smart/Gemma cleanup fails.
            return try await lightCleanup.cleanup(text: raw, mode: .light, modelDirectory: nil, instructions: nil)
        }
    }

    /// Selection transform (ADR-012): custom instructions + explicit MLX mode/package.
    func transform(
        text: String,
        mode: CleanupMode,
        modelDirectory: URL,
        instructions: String
    ) async throws -> String {
        guard mode.usesMLXHelper else {
            throw CleanupEngineError.modelMissing
        }
        return try await qwenCleanup.cleanup(
            text: text,
            mode: mode,
            modelDirectory: modelDirectory,
            instructions: instructions
        )
    }

    func unloadAll() async {
        isLiveDraftActive = false
        await whisper.unload()
        await parakeet.unload()
        await parakeetStreaming.unload()
        await appleSpeech.unload()
        await qwenCleanup.unload()
    }

    private func selectedSTTEngine() -> STTEngine {
        let id = modelManager.activeSTTID
        if id == BundledModelCatalog.appleSpeechSTTID || id.hasPrefix("stt.apple-speechanalyzer") {
            return appleSpeech
        }
        if id.hasPrefix("stt.parakeet") {
            return parakeet
        }
        return whisper
    }

    private func selectedCleanupEngine(for mode: CleanupMode) -> CleanupEngine {
        switch mode {
        case .smart, .smartPlus, .gemma:
            return qwenCleanup
        case .off, .light:
            return lightCleanup
        }
    }
}
