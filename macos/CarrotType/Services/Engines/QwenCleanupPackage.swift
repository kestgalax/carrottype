import Foundation
import HuggingFace

/// Host-side Hub download + readiness for Qwen cleanup packages (no MLX inference).
enum QwenCleanupPackage {
    /// Download MLX Qwen snapshot into `directory`.
    /// - Parameter onProgress: fraction in `[0, 1]` from Hub snapshot download.
    static func downloadPackage(
        repoID: String,
        to directory: URL,
        onProgress: (@Sendable (Double) -> Void)? = nil
    ) async throws {
        #if arch(arm64)
        guard let id = Repo.ID(rawValue: repoID) else {
            throw CleanupEngineError.modelMissing
        }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        _ = try await HubClient.default.downloadSnapshot(
            of: id,
            to: directory,
            progressHandler: { progress in
                onProgress?(progress.fractionCompleted)
            }
        )
        onProgress?(1)
        let marker = ModelPackageLayout.readyMarker(in: directory)
        try Data().write(to: marker, options: .atomic)
        #else
        throw CleanupEngineError.notAppleSilicon
        #endif
    }

    static func isPackageReady(at directory: URL) -> Bool {
        let config = directory.appendingPathComponent("config.json")
        guard FileManager.default.fileExists(atPath: config.path) else { return false }
        let contents = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
        let hasWeights = contents.contains { $0.hasSuffix(".safetensors") || $0 == "model.safetensors.index.json" }
        return hasWeights
    }
}
