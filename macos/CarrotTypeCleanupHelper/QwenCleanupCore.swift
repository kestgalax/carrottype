import Foundation
import HuggingFace
import MLX
import MLXHuggingFace
import MLXLLM
import MLXLMCommon
import Tokenizers

/// MLX Qwen cleanup inference (no IPC). Future XPC entrypoints should call this core (ADR-009).
enum QwenCleanupCore {
    #if arch(arm64)
    static func cleanup(text: String, modelDirectory: URL) async throws -> String {
        let configuration = ModelConfiguration(directory: modelDirectory)
        let container = try await #huggingFaceLoadModelContainer(configuration: configuration)
        defer {
            Memory.clearCache()
        }

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
        let result = stripModelExtras(raw)
        if result.isEmpty {
            throw CoreError.generationFailed
        }
        return result
    }
    #endif

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

    enum CoreError: Error {
        case generationFailed
        case notAppleSilicon
    }
}
