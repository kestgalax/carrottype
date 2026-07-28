import Foundation
import HuggingFace

/// Host-side Hub download + readiness for MLX cleanup packages (Qwen / Gemma; no inference).
enum QwenCleanupPackage {
    /// Download an MLX Hub snapshot into `directory`.
    /// - Parameter onProgress: fraction in `[0, 1]` — same signature / hop style as Parakeet STT.
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

        // Run Hub I/O off the caller's actor (ModelManager is @MainActor). FluidAudio/Parakeet
        // already yields off-main; without this, Hub work on MainActor starves the UI.
        _ = try await Task.detached {
            try await HubClient.default.downloadSnapshot(
                of: id,
                to: directory,
                progressHandler: { progress in
                    // Hub handler is @MainActor sync (like FluidAudio); forward like Parakeet.
                    onProgress?(Self.fraction(from: progress))
                }
            )
        }.value

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

    private static func fraction(from progress: Progress) -> Double {
        let raw = progress.fractionCompleted
        if raw.isFinite, raw > 0 {
            return min(max(raw, 0), 1)
        }
        let total = progress.totalUnitCount
        let completed = progress.completedUnitCount
        if total > 0, completed > 0 {
            return min(max(Double(completed) / Double(total), 0), 1)
        }
        if raw.isFinite {
            return min(max(raw, 0), 1)
        }
        return 0
    }
}
