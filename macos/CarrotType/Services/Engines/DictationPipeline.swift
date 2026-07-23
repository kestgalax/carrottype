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
    func cleanup(text: String, mode: CleanupMode, modelDirectory: URL?) async throws -> String
    func unload() async
}

/// Orchestrates STT → cleanup with engine selection from ModelManager.
@MainActor
final class DictationPipeline {
    private let modelManager: ModelManager
    private let whisper = WhisperSTTEngine()
    private let parakeet = ParakeetSTTEngine()
    private let lightCleanup = LightCleanupEngine()
    private let qwenCleanup = QwenCleanupEngine()

    init(modelManager: ModelManager) {
        self.modelManager = modelManager
    }

    func run(
        audioURL: URL,
        onPhase: @escaping @Sendable (DictationPhase) -> Void
    ) async throws -> String {
        onPhase(.transcribing)
        let stt = selectedSTTEngine()
        let modelPath = modelManager.selectedSTTModelPath()
        let raw = try await stt.transcribe(audioURL: audioURL, modelPath: modelPath)

        onPhase(.cleaning)
        let mode = modelManager.cleanupMode
        if (mode == .smart || mode == .smartPlus), modelManager.cleanupModelDirectory() == nil {
            // Package still downloading / missing — keep STT result via Light (download offered on select).
            return try await lightCleanup.cleanup(text: raw, mode: .light, modelDirectory: nil)
        }
        do {
            let directory = modelManager.cleanupModelDirectory()
            return try await selectedCleanupEngine(for: mode)
                .cleanup(text: raw, mode: mode, modelDirectory: directory)
        } catch {
            // Never lose the STT result if Smart cleanup fails.
            return try await lightCleanup.cleanup(text: raw, mode: .light, modelDirectory: nil)
        }
    }

    func unloadAll() async {
        await whisper.unload()
        await parakeet.unload()
        await qwenCleanup.unload()
    }

    private func selectedSTTEngine() -> STTEngine {
        let id = modelManager.activeSTTID
        if id.hasPrefix("stt.parakeet") {
            return parakeet
        }
        return whisper
    }

    private func selectedCleanupEngine(for mode: CleanupMode) -> CleanupEngine {
        switch mode {
        case .smart, .smartPlus:
            return qwenCleanup
        case .off, .light:
            return lightCleanup
        }
    }
}
