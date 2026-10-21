import Foundation
import FluidAudio

actor ParakeetSTTEngine: STTEngine {
    private var manager: AsrManager?
    private var loadedDirectory: String?

    /// Which FluidAudio Parakeet checkpoint a catalog id uses.
    /// v3 and Ultra share `AsrManager` but must not share a cache folder.
    struct PackageKind: Sendable, Equatable {
        let version: AsrModelVersion
        let folderName: String
        /// v3 installs once used a misnamed sibling; Ultra never did.
        let removesLegacyCoreMLSibling: Bool

        static let v3 = PackageKind(
            version: .v3,
            folderName: Repo.parakeetV3.folderName,
            removesLegacyCoreMLSibling: true
        )
        static let ultra = PackageKind(
            version: .ultra,
            folderName: Repo.parakeetUltra.folderName,
            removesLegacyCoreMLSibling: false
        )

        static func resolve(packageID: String) -> PackageKind {
            if packageID == BundledModelCatalog.parakeetUltraSTTID {
                return .ultra
            }
            return .v3
        }

        static func resolve(cacheDirectory: URL) -> PackageKind {
            if cacheDirectory.lastPathComponent == ultra.folderName {
                return .ultra
            }
            return .v3
        }
    }

    /// Where CoreML bundles actually live under CarrotType `models/`.
    /// FluidAudio's `AsrModels.download(to:)` writes into `parent/folderName`.
    static func fluidCacheDirectory(modelsRoot: URL, packageID: String) -> URL {
        let kind = PackageKind.resolve(packageID: packageID)
        return modelsRoot.appendingPathComponent(kind.folderName, isDirectory: true)
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
        let kind = PackageKind.resolve(packageID: packageID)
        try FileManager.default.createDirectory(at: packageDirectory, withIntermediateDirectories: true)
        let cacheDir = fluidCacheDirectory(modelsRoot: modelsRoot, packageID: packageID)
        _ = try await AsrModels.download(
            to: cacheDir,
            version: kind.version,
            progressHandler: { progress in
                onProgress?(progress.fractionCompleted)
            }
        )
        onProgress?(1)
        let marker = ModelPackageLayout.readyMarker(in: packageDirectory)
        try Data().write(to: marker, options: .atomic)
    }

    static func isPackageReady(modelsRoot: URL, packageDirectory: URL, packageID: String) -> Bool {
        let kind = PackageKind.resolve(packageID: packageID)
        let cacheDir = fluidCacheDirectory(modelsRoot: modelsRoot, packageID: packageID)
        let modelsPresent = AsrModels.modelsExist(at: cacheDir, version: kind.version)
        guard modelsPresent else { return false }
        // Marker is optional for installs that predate this layout helper.
        _ = packageDirectory
        return true
    }

    /// Removes the catalog marker dir and this variant's FluidAudio cache.
    /// v3 also removes the legacy misnamed sibling. Ultra does not touch the v3 cache.
    static func removeInstalled(modelsRoot: URL, packageDirectory: URL, packageID: String) throws {
        let kind = PackageKind.resolve(packageID: packageID)
        let fm = FileManager.default
        var errors: [Error] = []
        var urls = [
            packageDirectory,
            fluidCacheDirectory(modelsRoot: modelsRoot, packageID: packageID),
        ]
        if kind.removesLegacyCoreMLSibling {
            urls.append(modelsRoot.appendingPathComponent("parakeet-tdt-0.6b-v3-coreml", isDirectory: true))
        }

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
            let version = PackageKind.resolve(cacheDirectory: url).version
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
