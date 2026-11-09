import Foundation
import FluidAudio

actor ParakeetSTTEngine: STTEngine {
    private var manager: AsrManager?
    private var loadedDirectory: String?

    static let modelVersion = AsrModelVersion.ultra

    /// Where CoreML bundles actually live under CarrotType `models/`.
    /// FluidAudio's `AsrModels.download(to:)` writes into `parent/folderName`.
    static func fluidCacheDirectory(modelsRoot: URL, packageID: String) -> URL {
        modelsRoot.appendingPathComponent(Repo.parakeetUltra.folderName, isDirectory: true)
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

    /// Download a CoreML Parakeet package into the FluidAudio layout under `modelsRoot`.
    /// - Parameter packageDirectory: catalog package id folder (holds `.ready` marker).
    /// - Parameter onProgress: fraction in `[0, 1]` (may include CoreML compile phase).
    static func downloadPackage(
        modelsRoot: URL,
        packageDirectory: URL,
        packageID: String,
        onProgress: (@Sendable (Double) -> Void)? = nil
    ) async throws {
        guard packageID == BundledModelCatalog.parakeetUltraSTTID else { throw STTEngineError.modelMissing }
        try FileManager.default.createDirectory(at: packageDirectory, withIntermediateDirectories: true)
        let cacheDir = fluidCacheDirectory(modelsRoot: modelsRoot, packageID: packageID)
        _ = try await AsrModels.download(
            to: cacheDir,
            version: modelVersion,
            progressHandler: { progress in
                onProgress?(progress.fractionCompleted)
            }
        )
        onProgress?(1)
        let marker = ModelPackageLayout.readyMarker(in: packageDirectory)
        try Data().write(to: marker, options: .atomic)
    }

    static func isPackageReady(modelsRoot: URL, packageDirectory: URL, packageID: String) -> Bool {
        guard packageID == BundledModelCatalog.parakeetUltraSTTID else { return false }
        let cacheDir = fluidCacheDirectory(modelsRoot: modelsRoot, packageID: packageID)
        let modelsPresent = AsrModels.modelsExist(at: cacheDir, version: modelVersion)
        guard modelsPresent else { return false }
        // Marker is optional for installs that predate this layout helper.
        _ = packageDirectory
        return true
    }

    /// Removes only Ultra's catalog marker and CoreML cache. Retired packages use LegacySTTStorage.
    static func removeInstalled(modelsRoot: URL, packageDirectory: URL, packageID: String) throws {
        guard packageID == BundledModelCatalog.parakeetUltraSTTID else { throw STTEngineError.modelMissing }
        let fm = FileManager.default
        var errors: [Error] = []
        let urls = [
            packageDirectory,
            fluidCacheDirectory(modelsRoot: modelsRoot, packageID: packageID),
        ]

        for url in urls {
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
            guard url.lastPathComponent == Repo.parakeetUltra.folderName else { throw STTEngineError.modelMissing }
            let version = Self.modelVersion
            if AsrModels.modelsExist(at: url, version: version) {
                models = try await AsrModels.load(from: url, version: version)
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
