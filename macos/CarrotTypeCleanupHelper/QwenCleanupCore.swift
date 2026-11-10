import Foundation
import HuggingFace
import MLX
import MLXHuggingFace
import MLXLLM
import MLXLMCommon
import Tokenizers

/// MLX cleanup inference for Qwen3 Smart/Smart+ and optional Gemma 4 (ADR-005 / ADR-009 / ADR-010).
enum QwenCleanupCore {
    #if arch(arm64)
    static func cleanup(
        text: String,
        modelDirectory: URL,
        mode: String,
        instructions: String? = nil,
        rules: DictationRules? = nil
    ) async throws -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return ""
        }

        let configuration = ModelConfiguration(directory: modelDirectory)
        let container = try await #huggingFaceLoadModelContainer(configuration: configuration)
        defer {
            Memory.clearCache()
        }

        let customInstructions = instructions?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let useCustom = !(customInstructions?.isEmpty ?? true)
        let sessionInstructions = useCustom ? customInstructions! : DictationPrompt.instructions(rules ?? DictationRules())

        let isQwen = mode == "smart" || mode == "smartPlus"
        let prompt = useCustom ? "Текст:\n\(trimmed)" : "Транскрипт (данные):\n\(trimmed)"
        let maxTokens: Int
        if useCustom {
            maxTokens = min(2048, max(256, trimmed.split { $0.isWhitespace }.count * 2))
        } else {
            let tokenizer = await container.tokenizer
            let sourceCount = tokenizer.encode(text: trimmed).count
            let input = try await container.prepare(input: UserInput(
                chat: [.system(sessionInstructions), .user(prompt)],
                additionalContext: isQwen ? ["enable_thinking": false] : nil))
            let config = try Data(contentsOf: modelDirectory.appendingPathComponent("config.json"))
            guard let budget = FormattingBudget.outputLimit(sourceTokens: sourceCount,
                promptTokens: input.text.tokens.size, contextLimit: FormattingBudget.contextLimit(configuration: config))
            else { throw DictationModelFailure.contextLimit }
            maxTokens = budget
        }
        let params = GenerateParameters(maxTokens: maxTokens, temperature: 0)
        let session: ChatSession
        if isQwen {
            // Qwen3 defaults to chain-of-thought (`<think>…</think>`). Disable it for cleanup.
            session = ChatSession(
                container,
                instructions: sessionInstructions,
                generateParameters: params,
                additionalContext: ["enable_thinking": false]
            )
        } else {
            session = ChatSession(
                container,
                instructions: sessionInstructions,
                generateParameters: params
            )
        }
        let raw: String
        if useCustom {
            raw = try await session.respond(to: prompt)
        } else {
            var output = ""
            var completed = false
            for try await event in session.streamDetails(to: prompt) {
                try Task.checkCancellation()
                switch event {
                case .chunk(let text): output += text
                case .info(let info): completed = info.stopReason == .stop
                case .toolCall: throw DictationModelFailure.rejected
                }
            }
            guard completed else { throw DictationModelFailure.incomplete }
            raw = output
        }
        let result = useCustom ? stripModelExtras(raw, isQwen: isQwen) : raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if result.isEmpty || (!useCustom && !DictationIntegrity.accepts(source: trimmed, result: result,
            exactQuestionCount: rules?.businessStyle == true)) {
            throw DictationModelFailure.rejected
        }
        return result
    }
    #endif

    /// Drop Qwen thinking blocks / wrappers if the template still emits them.
    static func stripModelExtras(_ text: String, isQwen: Bool = true) -> String {
        var result = text
        if isQwen {
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
            result = result
                .replacingOccurrences(of: "</think>", with: "")
        }
        // Strip common markdown fences some instruction models add.
        if result.hasPrefix("```") {
            result = result
                .replacingOccurrences(of: #"^```(?:\w+)?\n?"#, with: "", options: .regularExpression)
                .replacingOccurrences(of: #"\n?```$"#, with: "", options: .regularExpression)
        }
        // Strip common preambles (literal cleanup must not leak chat wrappers).
        let preamblePatterns = [
            #"^(?i)вот\s+(исправленный|очищенный|готовый)\s+текст\s*[:\-—]?\s*"#,
            #"^(?i)исправленный\s+текст\s*[:\-—]?\s*"#,
            #"^(?i)(here('s| is)|cleaned|corrected)\s+(is\s+)?(the\s+)?(cleaned|corrected)?\s*(transcript|text|version)?\s*[:\-—]?\s*"#,
        ]
        for pattern in preamblePatterns {
            result = result.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
        }
        if result.hasPrefix("\"") && result.hasSuffix("\"") && result.count >= 2 {
            result = String(result.dropFirst().dropLast())
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    enum CoreError: Error {
        case generationFailed
        case notAppleSilicon
    }
}
