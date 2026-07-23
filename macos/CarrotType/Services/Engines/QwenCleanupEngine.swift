import Foundation
import HuggingFace
import MLX
import MLXHuggingFace
import MLXLLM
import MLXLMCommon
import Tokenizers

enum CleanupEngineError: LocalizedError {
    case modelMissing
    case generationFailed
    case notAppleSilicon

    var errorDescription: String? {
        switch self {
        case .modelMissing: return L10n.t("error.cleanup_model_missing")
        case .generationFailed: return L10n.t("error.cleanup_failed")
        case .notAppleSilicon: return L10n.t("error.cleanup_not_silicon")
        }
    }
}

actor QwenCleanupEngine: CleanupEngine {
    private var container: ModelContainer?
    private var loadedDirectory: String?

    func cleanup(text: String, mode: CleanupMode, modelDirectory: URL?) async throws -> String {
        switch mode {
        case .off:
            return text
        case .light:
            return TextCleanup.apply(text, mode: .light)
        case .smart, .smartPlus:
            break
        }

        #if arch(arm64)
        try await ensureLoaded(modelDirectory: modelDirectory)
        guard let container else { throw CleanupEngineError.modelMissing }

        // Qwen3 defaults to chain-of-thought (`<think>…</think>`). Disable it for cleanup.
        let session = ChatSession(
            container,
            instructions: """
            Ты редактор диктовки. Исправляй пунктуацию, капитализацию и слова-паразиты. \
            Не меняй смысл и язык. Отвечай только исправленным текстом — без пояснений и рассуждений.
            """,
            generateParameters: GenerateParameters(maxTokens: 256, temperature: 0.1),
            additionalContext: ["enable_thinking": false]
        )
        let prompt = "Исправь текст диктовки:\n\(text)"
        let raw = try await session.respond(to: prompt)
        let result = Self.stripModelExtras(raw)
        if result.isEmpty { throw CleanupEngineError.generationFailed }
        return result
        #else
        throw CleanupEngineError.notAppleSilicon
        #endif
    }

    func unload() async {
        container = nil
        loadedDirectory = nil
        // Drop MLX Metal working set; nil alone leaves IOAccelerator resident.
        Memory.clearCache()
    }

    /// Drop Qwen thinking blocks / wrappers if the template still emits them.
    static func stripModelExtras(_ text: String) -> String {
        var result = text
        if let regex = try? NSRegularExpression(
            pattern: #"(?s)<think>.*?</think>"#,
            options: []
        ) {
            let range = NSRange(result.startIndex..<result.endIndex, in: result)
            result = regex.stringByReplacingMatches(in: result, range: range, withTemplate: "")
        }
        if let start = result.range(of: "<think>") {
            result.removeSubrange(start.lowerBound...)
        }
        return result
            .replacingOccurrences(of: "</think>", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

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
        // Weights: either single safetensors or sharded index.
        let contents = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
        let hasWeights = contents.contains { $0.hasSuffix(".safetensors") || $0 == "model.safetensors.index.json" }
        return hasWeights
    }

    private func ensureLoaded(modelDirectory: URL?) async throws {
        guard let modelDirectory else { throw CleanupEngineError.modelMissing }
        let path = modelDirectory.path
        if loadedDirectory == path, container != nil { return }

        await unload()

        let configuration = ModelConfiguration(directory: modelDirectory)
        container = try await #huggingFaceLoadModelContainer(configuration: configuration)
        loadedDirectory = path
    }
}
