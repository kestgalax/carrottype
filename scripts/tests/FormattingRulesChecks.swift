import Foundation

actor RuleEngine: CleanupEngine {
    var received: DictationRules?
    var source: String?
    let replacement: String?
    init(_ replacement: String? = nil) { self.replacement = replacement }
    func cleanup(text: String, mode: CleanupMode, modelDirectory: URL?, instructions: String?) async throws -> String {
        preconditionFailure("Dictation must use its distinct rules path")
    }
    func formatDictation(text: String, mode: CleanupMode, modelDirectory: URL?, rules: DictationRules) async throws -> String {
        received = rules
        source = text
        return replacement ?? text
    }
    func unload() async {}
}

actor TypedFailureEngine: CleanupEngine {
    let failure: DictationModelFailure
    init(_ failure: DictationModelFailure) { self.failure = failure }
    func cleanup(text: String, mode: CleanupMode, modelDirectory: URL?, instructions: String?) async throws -> String { throw failure }
    func unload() async {}
}

@main struct FormattingRulesChecks {
    static func main() async throws {
        let name = "carrottype.rules-check.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        precondition(DictationRules.load(defaults: defaults) == DictationRules())
        let legacy = Data(#"{"removeFillers":false,"removeRepetitions":false,"applySelfCorrections":true,"paragraphs":true,"customRules":"keep my rules"}"#.utf8)
        defaults.set(legacy, forKey: DictationRules.defaultsKey)
        let migrated = DictationRules.load(defaults: defaults)
        precondition(!migrated.removeFillers && migrated.paragraphs && migrated.customRules == "keep my rules")
        precondition(!migrated.lowercase && !migrated.omitFinalPeriod && migrated.removedWords.isEmpty && !migrated.businessStyle)
        defaults.removeObject(forKey: DictationRules.defaultsKey)
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

        var exact = DictationRules()
        exact.removedWords = "ну, UM\nну"
        exact.lowercase = true; exact.omitFinalPeriod = true
        exact.save(defaults: defaults)
        precondition(DictationRules.load(defaults: defaults) == exact)
        let exactCases: [(String, String)] = [
            ("Ну, Нам нужен Отчёт. Это Последняя Фраза.", "нам нужен отчёт. это последняя фраза"),
            ("НУ нужен ну отчёт!", "нужен отчёт!"),
            ("Ну, Мы не готовы?", "мы не готовы?"),
            ("Ну-ка, Проверь!", "ну-ка, проверь!"),
            ("Um, Hello Jane. Are You Ready?", "hello jane. are you ready?"),
            ("Первая Строка.\nВторая Строка.", "первая строка.\nвторая строка"),
            ("Ну, «Нам нужен Отчёт.»", "«нам нужен отчёт»"),
            ("Ну, Ждём...", "ждём..."),
            ("Версия 1.2.", "версия 1.2"),
            ("Число 1.2", "число 1.2"),
            ("Привет.Мир.", "привет.мир"),
            ("Адрес: ул.", "адрес: ул."),
            ("Mr. Smith.", "mr. smith"),
            ("НУ", ""),
            ("Ну.", ""),
            ("Ну?", ""),
            ("Ну, Ссылка https://EXAMPLE.com/Nu?Token=AbC", "ссылка https://EXAMPLE.com/Nu?Token=AbC"),
            ("Ну, Почта User@Example.COM", "почта User@Example.COM"),
            ("Ну, Код `let Nu = \"ABC\"`.", "код `let Nu = \"ABC\"`"),
            ("Ну, Путь File.Name и some_ID.", "путь File.Name и some_ID"),
            ("```swift\nlet Nu = \"ABC\"\n```", "```swift\nlet Nu = \"ABC\"\n```"),
        ]
        for (input, expected) in exactCases {
            let actual = ExactDictationRules.apply(input, rules: exact)
            precondition(actual == expected, "Exact mismatch: \(input) → \(actual), expected \(expected)")
            precondition(ExactDictationRules.apply(actual, rules: exact) == actual, "Must be idempotent")
        }
        precondition(ExactDictationRules.apply("Raw  Text.", rules: DictationRules()) == "Raw  Text.")
        for mode in [CleanupMode.off, .light, .gemma] {
            let result = try await DictationFormatting.perform(text: "Ну, Нужен Отчёт.", mode: mode,
                directory: nil, engine: LightCleanupEngine(), lightEngine: LightCleanupEngine(), rules: exact)
            precondition(result.text == "нужен отчёт" && result.formatting.exactRulesApplied)
            precondition(result.formatting.usedFallback == mode.usesMLXHelper)
        }
        for failure in [DictationModelFailure.contextLimit, .timedOut, .incomplete, .rejected, .generationFailed] {
            let result = try await DictationFormatting.perform(text: "Ну, Нужен Отчёт.", mode: .gemma,
                directory: URL(fileURLWithPath: "/fixture"), engine: TypedFailureEngine(failure), lightEngine: LightCleanupEngine(), rules: exact)
            precondition(result.text == "нужен отчёт" && result.formatting.fallbackReason == failure)
        }
        let empty = try await DictationFormatting.perform(text: "Ну", mode: .gemma, directory: nil,
            engine: engine, lightEngine: LightCleanupEngine(), rules: exact)
        precondition(empty.text.isEmpty && !empty.formatting.usedFallback)
        exact.businessStyle = true
        precondition(DictationPrompt.instructions(exact).contains("professional business tone"))
        let styled = try await DictationFormatting.perform(text: "Ну, Отчёт.", mode: .gemma,
            directory: URL(fileURLWithPath: "/fixture"), engine: engine, lightEngine: LightCleanupEngine(), rules: exact)
        let filteredSource = await engine.source
        precondition(filteredSource == "Отчёт." && styled.text == "отчёт" && styled.formatting.style == .unchanged)
        let punctuationOnly = try await DictationFormatting.perform(text: "Проверь отчёт", mode: .gemma,
            directory: URL(fileURLWithPath: "/fixture"), engine: RuleEngine("Проверь отчёт."), lightEngine: LightCleanupEngine(), rules: exact)
        precondition(punctuationOnly.formatting.style == .unchanged)
        let failedStyle = try await DictationFormatting.perform(text: "Ну, Отчёт.", mode: .gemma, directory: nil,
            engine: engine, lightEngine: LightCleanupEngine(), rules: exact)
        precondition(failedStyle.formatting.style == .failed && failedStyle.text == "отчёт")
        print("PASS exact rules: legacy migration, whole words, prose casing, protected literals, terminal punctuation, idempotence, Off/Light/model/fallback/empty and separate style status")

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
        precondition(TextCleanup.apply("`let X =  1`", mode: .light) == "`let X =  1`")
        precondition(TextCleanup.apply("https://EXAMPLE.com/Nu", mode: .light) == "https://EXAMPLE.com/Nu")
        precondition(TextCleanup.apply("эм привет\nuh world", mode: .light) == "Привет\nworld")
        precondition(TextCleanup.apply("эм", mode: .light).isEmpty)
        precondition(TextCleanup.apply("raw\n  source", mode: .off) == "raw\n  source")
        print("PASS real Light: meaningful fillers, newlines, quotes/code, unambiguous hesitations and Off preserved")

        precondition(!DictationIntegrity.accepts(source: "Не согласен на 15 процентов до 17:30", result: "Не согласен до 17:30"))
        precondition(!DictationIntegrity.accepts(source: "Температура -15", result: "Температура 15"))
        precondition(!DictationIntegrity.accepts(source: "Не более 15%", result: "Не более 15"))
        precondition(!DictationIntegrity.accepts(source: "Это 15", result: "Это 16"))
        precondition(!DictationIntegrity.accepts(source: "Мы не готовы?", result: "Мы не готовы."))
        precondition(!DictationIntegrity.accepts(source: "Мы не готовы.", result: "Мы не готовы?", exactQuestionCount: true))
        precondition(DictationIntegrity.accepts(source: "Мы не готовы", result: "Мы не готовы?"))
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
