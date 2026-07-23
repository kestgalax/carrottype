import Foundation
import FluidAudio

actor ParakeetSTTEngine: STTEngine {
    private var manager: AsrManager?
    private var loadedDirectory: String?

    /// FluidAudio on-disk folder name (`parakeet-tdt-0.6b-v3`, `-coreml` stripped).
    static var fluidFolderName: String { Repo.parakeetV3.folderName }

    /// Where CoreML bundles actually live under CarrotType `models/`.
    /// FluidAudio's `AsrModels.download(to:)` writes into `parent/folderName`.
    static func fluidCacheDirectory(modelsRoot: URL) -> URL {
        modelsRoot.appendingPathComponent(fluidFolderName, isDirectory: true)
    }

    func transcribe(audioURL: URL, modelPath: String?) async throws -> String {
        try await ensureLoaded(modelDirectoryHint: modelPath)
        guard let manager else { throw STTEngineError.modelMissing }

        var decoderState = TdtDecoderState.make()
        let result = try await manager.transcribe(audioURL, decoderState: &decoderState)
        let text = result.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw STTEngineError.emptyResult }
        return text
    }

    func unload() async {
        if let manager {
            await manager.cleanup()
        }
        manager = nil
        loadedDirectory = nil
    }

    /// Download CoreML Parakeet v3 into FluidAudio layout under `modelsRoot`.
    /// - Parameter packageDirectory: catalog package id folder (holds `.ready` marker).
    /// - Parameter onProgress: fraction in `[0, 1]` (may include CoreML compile phase).
    static func downloadPackage(
        modelsRoot: URL,
        packageDirectory: URL,
        onProgress: (@Sendable (Double) -> Void)? = nil
    ) async throws {
        try FileManager.default.createDirectory(at: packageDirectory, withIntermediateDirectories: true)
        let cacheDir = fluidCacheDirectory(modelsRoot: modelsRoot)
        _ = try await AsrModels.download(
            to: cacheDir,
            version: .v3,
            progressHandler: { progress in
                onProgress?(progress.fractionCompleted)
            }
        )
        onProgress?(1)
        let marker = ModelPackageLayout.readyMarker(in: packageDirectory)
        try Data().write(to: marker, options: .atomic)
    }

    static func isPackageReady(modelsRoot: URL, packageDirectory: URL) -> Bool {
        let cacheDir = fluidCacheDirectory(modelsRoot: modelsRoot)
        let modelsPresent = AsrModels.modelsExist(at: cacheDir, version: .v3)
        guard modelsPresent else { return false }
        // Marker is optional for installs that predate this layout helper.
        _ = packageDirectory
        return true
    }

    /// Removes catalog marker dir + FluidAudio cache (+ legacy misnamed sibling).
    static func removeInstalled(modelsRoot: URL, packageDirectory: URL) throws {
        let fm = FileManager.default
        var errors: [Error] = []

        for url in [
            packageDirectory,
            fluidCacheDirectory(modelsRoot: modelsRoot),
            // Old delete path mistakenly targeted this name; clean if present.
            modelsRoot.appendingPathComponent("parakeet-tdt-0.6b-v3-coreml", isDirectory: true),
        ] {
            guard fm.fileExists(atPath: url.path) else { continue }
            do {
                try fm.removeItem(at: url)
            } catch {
                errors.append(error)
            }
        }

        if let first = errors.first {
            throw first
        }
    }

    private func ensureLoaded(modelDirectoryHint: String?) async throws {
        let hint = modelDirectoryHint ?? ""
        if loadedDirectory == hint, manager != nil { return }

        await unload()

        let models: AsrModels
        if !hint.isEmpty {
            let url = URL(fileURLWithPath: hint, isDirectory: true)
            if AsrModels.modelsExist(at: url, version: .v3) {
                models = try await AsrModels.load(from: url, version: .v3)
            } else {
                throw STTEngineError.modelMissing
            }
        } else {
            throw STTEngineError.modelMissing
        }

        let asr = AsrManager(config: .default)
        try await asr.loadModels(models)
        manager = asr
        loadedDirectory = hint
    }
}
