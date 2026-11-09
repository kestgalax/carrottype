import Foundation

enum BundledModelCatalog {
    static let recommendedSTTID = "stt.parakeet-ultra"
    static let parakeetUltraSTTID = "stt.parakeet-ultra"
    static let smartCleanupID = "cleanup.qwen3-0.6b-4bit"
    static let smartPlusCleanupID = "cleanup.qwen3-1.7b-4bit"
    static let gemmaCleanupID = "cleanup.gemma4-e2b-4bit"

    static func load(from bundle: Bundle = .main) -> ModelCatalogFile {
        if let url = bundle.url(forResource: "ModelCatalog", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let catalog = try? JSONDecoder().decode(ModelCatalogFile.self, from: data),
           !catalog.packages.isEmpty {
            return catalog
        }
        return fallback
    }

    static let fallback = ModelCatalogFile(
        version: 11,
        packages: [
            CatalogPackage(
                id: parakeetUltraSTTID,
                role: .stt,
                displayName: "Parakeet Ultra",
                approximateBytes: 630_000_000,
                languagesBlurb: "catalog.blurb.stt.parakeet-ultra",
                license: "CC-BY-4.0",
                recommended: true,
                downloadURL: "https://huggingface.co/FluidInference/parakeet-ultra-coreml",
                runtimeHint: "parakeet-fluidaudio",
                hubRepoID: "FluidInference/parakeet-ultra-coreml",
                downloadable: true,
                supportsStreaming: true
            ),
            CatalogPackage(
                id: "cleanup.qwen3-0.6b-4bit",
                role: .cleanup,
                displayName: "Qwen3 0.6B (Smart)",
                approximateBytes: 335_000_000,
                languagesBlurb: "catalog.blurb.cleanup.qwen3-0.6b-4bit",
                license: "Apache-2.0",
                recommended: false,
                downloadURL: "https://huggingface.co/mlx-community/Qwen3-0.6B-4bit",
                runtimeHint: "mlx-lm",
                hubRepoID: "mlx-community/Qwen3-0.6B-4bit",
                downloadable: true,
                hubRevision: "73e3e38d981303bc594367cd910ea6eb48349da8"
            ),
            CatalogPackage(
                id: "cleanup.qwen3-1.7b-4bit",
                role: .cleanup,
                displayName: "Qwen3 1.7B (Smart+)",
                approximateBytes: 1_000_000_000,
                languagesBlurb: "catalog.blurb.cleanup.qwen3-1.7b-4bit",
                license: "Apache-2.0",
                recommended: false,
                downloadURL: "https://huggingface.co/mlx-community/Qwen3-1.7B-4bit",
                runtimeHint: "mlx-lm",
                hubRepoID: "mlx-community/Qwen3-1.7B-4bit",
                downloadable: true,
                hubRevision: "3b1b1768f8f8cf8351c712464f906e86c2b8269e"
            ),
            CatalogPackage(
                id: "cleanup.gemma4-e2b-4bit",
                role: .cleanup,
                displayName: "Gemma 4 E2B",
                approximateBytes: 3_550_000_000,
                languagesBlurb: "catalog.blurb.cleanup.gemma4-e2b-4bit",
                license: "Apache-2.0",
                recommended: false,
                downloadURL: "https://huggingface.co/mlx-community/gemma-4-e2b-it-4bit",
                runtimeHint: "mlx-lm",
                hubRepoID: "mlx-community/gemma-4-e2b-it-4bit",
                downloadable: true,
                hubRevision: "238767527555cb75a05732a84dff5d6ba0dd6809"
            ),
        ]
    )
}
