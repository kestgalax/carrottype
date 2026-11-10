import Foundation

actor RuleEngine: CleanupEngine {
    var received: DictationRules?
    func cleanup(text: String, mode: CleanupMode, modelDirectory: URL?, instructions: String?) async throws -> String {
        preconditionFailure("Dictation must use its distinct rules path")
    }
    func formatDictation(text: String, mode: CleanupMode, modelDirectory: URL?, rules: DictationRules) async throws -> String {
        received = rules
        return text
    }
    func unload() async {}
}

@main struct FormattingRulesChecks {
    static func main() async throws {
        let name = "carrottype.rules-check.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        precondition(DictationRules.load(defaults: defaults) == DictationRules())
        defaults.set(Data("invalid".utf8), forKey: DictationRules.defaultsKey)
        precondition(DictationRules.load(defaults: defaults) == DictationRules())
        var rules = DictationRules()
        rules.customRules = String(repeating: "🌱", count: 1200)
        rules.removeFillers = false; rules.paragraphs = true
        rules.save(defaults: defaults)
        precondition(DictationRules.load(defaults: defaults).customRules.count == 1000)
        let prompt = DictationPrompt.instructions(rules)
        precondition(prompt.contains("Сохраняй слова-паразиты") && prompt.contains("смысловые абзацы"))
        precondition(prompt.contains("не отвечай") && prompt.contains("Не переводи"))
        precondition(prompt.components(separatedBy: "🌱").count == 1001)
        let snapshot = rules
        rules.customRules = "next session"
        precondition(snapshot.customRules != rules.customRules)
        let engine = RuleEngine()
        _ = try await DictationFormatting.perform(text: "fixture", mode: .gemma,
            directory: URL(fileURLWithPath: "/fixture"), engine: engine, lightEngine: LightCleanupEngine(), rules: rules)
        let received = await engine.received
        precondition(received == rules)
        print("PASS rules: defaults/corruption, Unicode limit, persistence, prompt constraints, captured value and actual engine dispatch")

        precondition(FormattingBudget.outputLimit(sourceTokens: 800, promptTokens: 1400, contextLimit: 8192) == 1728)
        precondition(FormattingBudget.outputLimit(sourceTokens: 5000, promptTokens: 5600, contextLimit: 8192) == nil)
        precondition(FormattingBudget.outputLimit(sourceTokens: -1, promptTokens: 1, contextLimit: 8192) == nil)
        precondition(FormattingBudget.outputLimit(sourceTokens: Int.max, promptTokens: 1, contextLimit: 8192) == nil)
        precondition(FormattingBudget.contextLimit(configuration: Data(#"{"text_config":{"max_position_embeddings":4096}}"#.utf8)) == 4096)
        precondition(FormattingBudget.contextLimit(configuration: Data(#"{"max_position_embeddings":131072}"#.utf8)) == 16384)
        print("PASS budget: token reserve, context overflow, malicious counts, nested model context and bounded workload")

        for input in ["I like this design", "Ну ты и молодец", "Это типа данных", "Первая строка\nВторая строка", "\"Keep this quoted\"", "```swift\nlet x = 1\n```"] {
            precondition(TextCleanup.apply(input, mode: .light) == input, input)
        }
        precondition(TextCleanup.apply("```swift\n    let X = 1\n```", mode: .light) == "```swift\n    let X = 1\n```")
        precondition(TextCleanup.apply("эм привет\nuh world", mode: .light) == "Привет\nworld")
        precondition(TextCleanup.apply("эм", mode: .light).isEmpty)
        precondition(TextCleanup.apply("raw\n  source", mode: .off) == "raw\n  source")
        print("PASS real Light: meaningful fillers, newlines, quotes/code, unambiguous hesitations and Off preserved")

        precondition(!DictationIntegrity.accepts(source: "Не согласен на 15 процентов до 17:30", result: "Не согласен до 17:30"))
        precondition(!DictationIntegrity.accepts(source: "Температура -15", result: "Температура 15"))
        precondition(!DictationIntegrity.accepts(source: "Не более 15%", result: "Не более 15"))
        precondition(!DictationIntegrity.accepts(source: "Это 15", result: "Это 16"))
        precondition(!DictationIntegrity.accepts(source: "Мы не готовы?", result: "Мы не готовы."))
        precondition(DictationIntegrity.accepts(source: "Мы не готовы?", result: "мы не готовы?"))
        precondition(!DictationIntegrity.accepts(source: "Я не согласен", result: "Я согласен"))
        precondition(!DictationIntegrity.accepts(source: "\"I like this design.\"", result: "I like this design."))
        precondition(!DictationIntegrity.accepts(source: "um I like this", result: "Ум, I like this"))
        precondition(!DictationIntegrity.accepts(source: "https://example.com/path", result: "https://example.com"))
        precondition(!DictationIntegrity.accepts(source: "```swift\nlet x = 1\n```", result: "let x = 1"))
        precondition(!DictationIntegrity.accepts(source: "```swift\nlet X = 1\n```", result: "```swift\nlet x = 1\n```"))
        precondition(DictationIntegrity.accepts(source: "эм я не согласен на 15 процентов", result: "Я не согласен на 15 процентов."))
        print("PASS conservative output guards: missing/changed numbers, negations, question/quote/code/URL loss and introduced Cyrillic")

        let request = CleanupHelperRequest(text: "fixture", mode: "smart", modelDirectory: "/fixture",
            purpose: "dictation", dictationRules: rules)
        let decoded = try JSONDecoder().decode(CleanupHelperRequest.self, from: JSONEncoder().encode(request))
        precondition(decoded.v == 3 && decoded.purpose == "dictation" && decoded.dictationRules == rules && decoded.instructions == nil)
        let transform = CleanupHelperRequest(text: "fixture", mode: "gemma", modelDirectory: "/fixture", instructions: "Translate")
        precondition(transform.purpose == "transform" && transform.dictationRules == nil)
        print("PASS helper contract: explicit purpose/rules distinct from transform instructions")

        precondition(AppTheme.load(defaults: defaults) == .system)
        defaults.set("unknown", forKey: AppTheme.defaultsKey)
        precondition(AppTheme.load(defaults: defaults) == .system)
        for theme in AppTheme.allCases {
            defaults.set(theme.rawValue, forKey: AppTheme.defaultsKey)
            precondition(AppTheme.load(defaults: defaults) == theme)
        }
        precondition(AppTheme.system.appearance == nil && AppTheme.light.appearance != nil && AppTheme.dark.appearance != nil)
        precondition(defaults.object(forKey: AppLanguage.defaultsKey) == nil)
        print("PASS theme: persisted choice, invalid/system fallback, native appearance reset and independent language preference")
    }
}
