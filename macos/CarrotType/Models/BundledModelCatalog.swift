import Foundation

enum BundledModelCatalog {
    static let recommendedSTTID = "stt.whisper-base-ggml"
    static let smartCleanupID = "cleanup.qwen3-0.6b-4bit"
    static let smartPlusCleanupID = "cleanup.qwen3-1.7b-4bit"

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
        version: 4,
        packages: [
            CatalogPackage(
                id: "stt.whisper-base-ggml",
                role: .stt,
                displayName: "Whisper Base",
                approximateBytes: 148_000_000,
                languagesBlurb: "catalog.blurb.stt.whisper-base-ggml",
                license: "MIT",
                recommended: true,
                downloadURL: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin",
                runtimeHint: "whisper-cpp-ggml",
                artifactFileName: "ggml-base.bin",
                downloadable: true,
                sha256: "60ed5bc3dd14eea856493d334349b405782ddcaf0028d4b5df4088345fba2efe"
            ),
            CatalogPackage(
                id: "stt.whisper-small-ggml",
                role: .stt,
                displayName: "Whisper Small",
                approximateBytes: 488_000_000,
                languagesBlurb: "catalog.blurb.stt.whisper-small-ggml",
                license: "MIT",
                recommended: false,
                downloadURL: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin",
                runtimeHint: "whisper-cpp-ggml",
                artifactFileName: "ggml-small.bin",
                downloadable: true,
                sha256: "1be3a9b2063867b937e64e2ec7483364a79917e157fa98c5d94b5c1fffea987b"
            ),
            CatalogPackage(
                id: "stt.whisper-large-v3-turbo-q5",
                role: .stt,
                displayName: "Whisper Turbo q5",
                approximateBytes: 574_000_000,
                languagesBlurb: "catalog.blurb.stt.whisper-large-v3-turbo-q5",
                license: "MIT",
                recommended: false,
                downloadURL: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo-q5_0.bin",
                runtimeHint: "whisper-cpp-ggml",
                artifactFileName: "ggml-large-v3-turbo-q5_0.bin",
                downloadable: true,
                sha256: "394221709cd5ad1f40c46e6031ca61bce88931e6e088c188294c6d5a55ffa7e2"
            ),
            CatalogPackage(
                id: "stt.parakeet-tdt-0.6b-v3",
                role: .stt,
                displayName: "Parakeet TDT 0.6B v3",
                approximateBytes: 700_000_000,
                languagesBlurb: "catalog.blurb.stt.parakeet-tdt-0.6b-v3",
                license: "CC-BY-4.0",
                recommended: false,
                downloadURL: "https://huggingface.co/FluidInference/parakeet-tdt-0.6b-v3-coreml",
                runtimeHint: "parakeet-fluidaudio",
                hubRepoID: "FluidInference/parakeet-tdt-0.6b-v3-coreml",
                downloadable: true
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
                downloadable: true
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
                downloadable: true
            ),
        ]
    )
}
