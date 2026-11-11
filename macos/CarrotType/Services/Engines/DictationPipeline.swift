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

struct DictationPipelineConfiguration {
    let packageID: String
    let modelPath: String?
    let supportsStreaming: Bool
    let cleanupMode: CleanupMode
    let cleanupDirectory: URL?
    var rules: DictationRules = DictationRules()
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
    private let parakeet = ParakeetSTTEngine()
    private let streamingBox = ParakeetStreamingBox()
    private let lightCleanup = LightCleanupEngine()
    private let qwenCleanup = QwenCleanupEngine()

    /// True while a live-draft streaming session is accepting audio.
    private(set) var isLiveDraftActive = false

    private var previewFeed: (@Sendable (AVAudioPCMBuffer) -> Void)?

    private var parakeetStreaming: ParakeetStreamingEngine { streamingBox.engine }

    init(modelManager: ModelManager) {
        self.modelManager = modelManager
    }

    func snapshotConfiguration() -> DictationPipelineConfiguration {
        DictationPipelineConfiguration(packageID: modelManager.activeSTTID,
            modelPath: modelManager.selectedSTTModelPath(), supportsStreaming: modelManager.selectedSTTSupportsStreaming,
            cleanupMode: modelManager.cleanupMode, cleanupDirectory: modelManager.cleanupModelDirectory())
    }

    /// Start full-buffer preview for the active Parakeet package when possible.
    /// On failure, logs and returns false so the caller keeps the file-only path.
    func startLiveDraftIfPossible(
        languageCode: String?,
        configuration: DictationPipelineConfiguration? = nil,
        onUpdate: @escaping @Sendable (LiveTranscript) -> Void
    ) async -> Bool {
        await cancelLiveDraft()
        let configuration = configuration ?? snapshotConfiguration()
        guard configuration.supportsStreaming, let modelPath = configuration.modelPath else { return false }
        let packageID = configuration.packageID
        do {
            try await parakeetStreaming.start(
                modelDirectory: URL(fileURLWithPath: modelPath, isDirectory: true),
                packageID: packageID,
                languageCode: languageCode,
                onUpdate: onUpdate
            )
            previewFeed = await parakeetStreaming.makeFeedHandler()
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

    /// The recorder holds this generation-bound handler, never a mutable current-session lookup.
    func liveDraftAudioHandler() -> ((AVAudioPCMBuffer) -> Void)? { previewFeed }

    func cancelLiveDraft() async {
        previewFeed = nil
        isLiveDraftActive = false
        await parakeetStreaming.cancel()
    }

    func run(
        audioURL: URL,
        onPhase: @escaping @Sendable (DictationPhase) -> Void
    ) async throws -> FormattedDictation {
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
        configuration: DictationPipelineConfiguration? = nil,
        onPhase: @escaping @Sendable (DictationPhase) -> Void
    ) async throws -> FormattedDictation {
        let configuration = configuration ?? snapshotConfiguration()
        let mode = configuration.cleanupMode
        let directory = configuration.cleanupDirectory
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
            let stt = parakeet
            let modelPath = configuration.modelPath
            raw = try await stt.transcribe(audioURL: audioURL, modelPath: modelPath)
        }

        await parakeetStreaming.unload()

        guard let raw else { throw STTEngineError.emptyResult }

        onPhase(.cleaning)
        return try await DictationFormatting.perform(
            text: raw, mode: mode, directory: directory,
            engine: selectedCleanupEngine(for: mode), lightEngine: lightCleanup, rules: configuration.rules
        )
    }

    func formatText(_ text: String, mode: CleanupMode, directory: URL?, rules: DictationRules) async throws -> FormattedDictation {
        try await DictationFormatting.perform(text: text, mode: mode, directory: directory,
            engine: selectedCleanupEngine(for: mode), lightEngine: lightCleanup, rules: rules)
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
        previewFeed = nil
        isLiveDraftActive = false
        await parakeet.unload()
        await parakeetStreaming.unload()
        await qwenCleanup.unload()
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
