import Foundation

private final class FakeClock {
    var now: TimeInterval
    init(_ now: TimeInterval) { self.now = now }
    func read() -> TimeInterval { now }
}

private func corpus(_ text: String, extra: [String] = []) -> TypingTestCorpus {
    TypingTestCorpus(languages: [
        .english: TypingTestLanguageCorpus(
            easyWords: ["alpha"],
            mediumFragments: [text] + extra,
            advancedFragments: [text] + extra
        )
    ])
}

private func makeEngine(
    _ text: String,
    extras: [String] = [],
    clock: FakeClock,
    minimum: Int = 1
) throws -> TypingSpeedTestEngine {
    let builder = TypingTestPromptBuilder(corpus: corpus(text, extra: extras), minimumGraphemes: minimum)
    let prompt = try builder.makePrompt(language: .english, level: .medium, seed: 1)
    return TypingSpeedTestEngine(prompt: prompt, builder: builder, duration: 30, clock: clock.read)
}

private func type(_ engine: TypingSpeedTestEngine, _ old: String, _ new: String, at now: TimeInterval) {
    guard let edit = TypingTestEdit.between(old, new) else { return }
    engine.apply(edit, now: now)
}

private func graphemes(_ string: String) -> [Character] {
    Array(string.precomposedStringWithCanonicalMapping)
}

@main
struct TypingSpeedTestChecks {
    static func main() throws {
        try bundledCorpusAndValidation()
        try allModesAndVariation()
        try metricsFixtures()
        try engineLifecycleAndDeadline()
        try accuracyAndCorrections()
        try rangeAndLowAccuracyPolicy()
        try refillAndAvoidance()
        try performanceMeasurement()
        print("PASS typing-speed production model fixtures")
    }

    private static func bundledCorpusAndValidation() throws {
        let bundled = TypingTestCorpus.bundled
        try bundled.validate()
        let bytes = bundled.authoredUTF8ByteCount
        precondition(bytes > 10_000 && bytes < 100_000, "Corpus size out of budget: \(bytes) bytes")
        for language in TypingTestLanguage.allCases {
            guard let corpus = bundled.languageCorpus(for: language) else {
                preconditionFailure("Missing bundled \(language.rawValue) corpus")
            }
            precondition(corpus.easyWords.count >= 150, "Easy corpus is too small")
            precondition((40...60).contains(corpus.mediumFragments.count), "Medium corpus outside 40–60")
            precondition((40...60).contains(corpus.advancedFragments.count), "Advanced corpus outside 40–60")
        }
        print("MEASURE corpus bytes=\(bytes) ru_easy=\(bundled.languageCorpus(for: .russian)!.easyWords.count) en_easy=\(bundled.languageCorpus(for: .english)!.easyWords.count)")

        let bad = TypingTestCorpus(languages: [
            .english: TypingTestLanguageCorpus(
                easyWords: ["Good"], mediumFragments: ["Sentence."], advancedFragments: ["Advanced, 2."]
            ),
        ])
        do {
            try bad.validate()
            preconditionFailure("Missing language must fail validation")
        } catch let error as TypingTestCorpus.ValidationError {
            precondition(error == .missingLanguage(.russian))
        }
        let badWord = TypingTestCorpus(languages: [
            .russian: TypingTestLanguageCorpus(easyWords: ["дом"], mediumFragments: ["Фраза."], advancedFragments: ["Фраза."]),
            .english: TypingTestLanguageCorpus(easyWords: ["Bad1"], mediumFragments: ["Sentence."], advancedFragments: ["Sentence."]),
        ])
        do {
            try badWord.validate()
            preconditionFailure("Non-lowercase easy word must fail")
        } catch let error as TypingTestCorpus.ValidationError {
            precondition(error == .easyWordNotLowercase(.english, "Bad1"))
        }
        let missingLevel = TypingTestCorpus(languages: [
            .english: TypingTestLanguageCorpus(easyWords: ["a"], mediumFragments: [], advancedFragments: ["x."]),
        ])
        let builder = TypingTestPromptBuilder(corpus: missingLevel, minimumGraphemes: 10)
        do {
            _ = try builder.makePrompt(language: .english, level: .medium, seed: 1)
            preconditionFailure("Empty corpus must throw")
        } catch let error as TypingTestModelError {
            precondition(error == .emptyCorpus(.english, .medium))
        }
        do {
            _ = try builder.makePrompt(language: .russian, level: .easy, seed: 1)
            preconditionFailure("Unsupported language must throw")
        } catch let error as TypingTestModelError {
            precondition(error == .unsupportedCorpus(.russian, .easy))
        }
        print("PASS bundled corpus validation, size \(bytes) UTF-8 bytes, unsupported/malformed corpus errors")
    }

    private static func allModesAndVariation() throws {
        let builder = TypingTestPromptBuilder()
        for language in TypingTestLanguage.allCases {
            for level in TypingTestLevel.allCases {
                let first = try builder.makePrompt(language: language, level: level, seed: 42)
                let second = try builder.makePrompt(language: language, level: level, seed: 42)
                let other = try builder.makePrompt(language: language, level: level, seed: 43)
                precondition(first.text == second.text, "Seeded prompt must be reproducible")
                precondition(first.text != other.text, "A different seed must vary the prompt")
                precondition(first.graphemes.count >= 650, "Prompt must cover 200 WPM × 30 s with margin")
                precondition(first.language == language && first.level == level)
                if level == .easy {
                    precondition(first.text == first.text.lowercased())
                    precondition(first.text.allSatisfy { $0.isLetter || $0.isWhitespace })
                }
                if let firstCharacter = first.text.first, level != .easy {
                    precondition(firstCharacter.isUppercase, "Medium/advanced prompt should start a sentence")
                }
                let avoiding = try builder.makePrompt(
                    language: language, level: level, seed: 42, avoiding: first.text
                )
                precondition(avoiding.text != first.text, "Immediate whole-prompt repeat must be avoided")
                print("PASS mode \(language.rawValue)/\(level.rawValue): \(first.graphemes.count) graphemes")
            }
        }
    }

    private static func metricsFixtures() throws {
        func credited(_ typed: String, _ expected: String) -> Int {
            TypingTestMetrics.creditedCharacters(typed: graphemes(typed), expected: graphemes(expected))
        }
        precondition(credited("alpha beta gam", "alpha beta gamma delta") == 14)
        precondition(credited("alpha bx gam", "alpha beta gamma delta") == 9)
        precondition(credited("alpha beta gammx", "alpha beta gamma delta") == 15)
        precondition(credited("alpha bx ", "alpha beta gamma delta") == 6)
        precondition(credited("alpha beta", "alpha beta") == 10)
        precondition(credited("alpha  beta", "alpha beta") == 9, "Extra separator is not credited")
        precondition(credited("", "alpha beta") == 0)
        precondition(credited("café 🌟", "café 🌟") == 6, "NFC extended graphemes count once")
        precondition(credited("cafe\u{301} 🌟", "café 🌟") == 6, "Decomposed input compares as NFC")
        precondition(credited("ёлка ёж", "Ёлка ёж") == 2, "Case and ё are not folded")
        precondition(credited("alpha beta gamma delta", "alpha beta gamma delta") == 22)
        print("PASS metric fixtures: words/separators/last partial/wrong words/case/ё/NFC")
    }

    private static func engineLifecycleAndDeadline() throws {
        let clock = FakeClock(100)
        let engine = try makeEngine("alpha beta gamma delta", clock: clock)
        precondition(engine.phase == .ready)
        type(engine, "", "a", at: 100)
        precondition(engine.phase == .running)
        precondition(engine.startedAt == 100 && engine.deadline == 130)
        clock.now = 129.99
        precondition(!engine.tick(now: clock.now))
        clock.now = 130
        precondition(engine.tick(now: clock.now))
        precondition(engine.phase == .completed)
        guard let result = engine.result else { preconditionFailure("Missing result") }
        precondition(abs(result.rawCPM - 2) < 0.0001) // one credited character / 30 s
        precondition(abs(result.rawWPM - 0.4) < 0.0001)
        precondition(result.duration == 30 && result.accuracyPercent == 100)
        precondition(!result.canApply) // below the existing 10–200 WPM range
        type(engine, "a", "ab", at: 140)
        precondition(engine.typedText == "a", "Late event must not be credited")

        // Deadline is fixed by the first committed grapheme, not by tick count.
        let clock2 = FakeClock(500)
        let engine2 = try makeEngine("alpha beta gamma delta", clock: clock2)
        type(engine2, "", "alpha beta gamma delta", at: 500)
        for offset in stride(from: 500.0, through: 530.0, by: 3.0) {
            _ = engine2.tick(now: offset)
            clock2.now = offset
        }
        precondition(engine2.phase == .completed)
        guard let exact = engine2.result else { preconditionFailure("Missing exact result") }
        precondition(abs(exact.rawCPM - 44) < 0.0001)
        precondition(abs(exact.rawWPM - 8.8) < 0.0001)
        precondition(exact.creditedCharacters == 22)
        print("PASS deadline: first grapheme starts 30 s, late events ignored, ticks never define duration")
    }

    private static func accuracyAndCorrections() throws {
        let clock = FakeClock(200)
        let engine = try makeEngine("alpha beta", clock: clock)
        type(engine, "", "alphx", at: 200)
        precondition(engine.attempts == 5 && engine.correctAttempts == 4)
        type(engine, "alphx", "alph", at: 201)
        precondition(engine.attempts == 5, "Backspace is not an attempt")
        type(engine, "alph", "alpha", at: 202)
        precondition(engine.attempts == 6 && engine.correctAttempts == 5)
        clock.now = 230
        precondition(engine.tick(now: 230))
        guard let result = engine.result else { preconditionFailure("Missing correction result") }
        precondition(result.creditedCharacters == 5)
        precondition(abs(result.accuracyPercent - (5.0 / 6.0 * 100)) < 0.0001)
        print("PASS accuracy denominator: corrected mistakes remain, backspace/modifiers/navigation do not count")
    }

    private static func rangeAndLowAccuracyPolicy() throws {
        let lowAccuracy = TypingTestResult(
            rawWPM: 50, rawCPM: 250, accuracyPercent: 8,
            duration: 30, language: .russian, level: .medium,
            creditedCharacters: 125, attempts: 100, correctAttempts: 8
        )
        precondition(lowAccuracy.canApply, "Accuracy is informational, never an acceptance threshold")
        let tooSlow = TypingTestResult(
            rawWPM: 5, rawCPM: 25, accuracyPercent: 100,
            duration: 30, language: .english, level: .easy,
            creditedCharacters: 12, attempts: 12, correctAttempts: 12
        )
        precondition(!tooSlow.canApply)
        let tooFast = TypingTestResult(
            rawWPM: 250, rawCPM: 1250, accuracyPercent: 100,
            duration: 30, language: .english, level: .advanced,
            creditedCharacters: 625, attempts: 625, correctAttempts: 625
        )
        precondition(!tooFast.canApply)
        let justBelow = TypingTestResult(
            rawWPM: 9.99, rawCPM: 49.95, accuracyPercent: 100,
            duration: 30, language: .english, level: .easy,
            creditedCharacters: 25, attempts: 25, correctAttempts: 25
        )
        precondition(!justBelow.canApply, "The raw result, not its rounded display, defines the range")
        let justAbove = TypingTestResult(
            rawWPM: 200.01, rawCPM: 1000.05, accuracyPercent: 100,
            duration: 30, language: .english, level: .advanced,
            creditedCharacters: 500, attempts: 500, correctAttempts: 500
        )
        precondition(!justAbove.canApply)

        let clock = FakeClock(300)
        let engine = try makeEngine("alpha beta", clock: clock)
        type(engine, "", "a", at: 300)
        type(engine, "a", "", at: 301)
        clock.now = 330
        precondition(engine.tick(now: 330))
        guard let empty = engine.result else { preconditionFailure("Missing empty result") }
        precondition(empty.creditedCharacters == 0 && !empty.canApply)
        print("PASS low accuracy does not block Apply; out-of-range/empty results are not applicable")
    }

    private static func refillAndAvoidance() throws {
        let builder = TypingTestPromptBuilder(
            corpus: corpus("one two", extra: ["three four"]),
            minimumGraphemes: 1
        )
        let prompt = try builder.makePrompt(language: .english, level: .medium, seed: 3)
        let clock = FakeClock(400)
        let engine = TypingSpeedTestEngine(prompt: prompt, builder: builder, duration: 30, clock: clock.read)
        let before = engine.promptText.count
        type(engine, "", String(repeating: "one two three four ", count: 10), at: 400)
        precondition(engine.promptText.count > before, "Prompt must refill when the prepared text runs out")
        precondition(engine.deadline == 430, "Refill must not move the fixed deadline")
        clock.now = 430
        precondition(engine.tick(now: 430))
        precondition(engine.result != nil)

        var previous = prompt.text
        let multiBuilder = TypingTestPromptBuilder(
            corpus: corpus("one two", extra: ["three four", "five six"]),
            minimumGraphemes: 12
        )
        for seed in 4...8 {
            let next = try multiBuilder.makePrompt(
                language: .english, level: .medium, seed: UInt64(seed), avoiding: previous
            )
            precondition(next.text != previous)
            precondition(zip(next.segments, next.segments.dropFirst()).allSatisfy { $0 != $1 },
                         "Adjacent duplicate fragment at refill boundary")
            previous = next.text
        }
        print("PASS refill extends in RAM without shortening 30 s; no adjacent duplicate/whole-prompt repeat")
    }

    private static func performanceMeasurement() throws {
        let clock = FakeClock(0)
        let engine = try makeEngine(
            "alpha beta gamma delta epsilon zeta eta theta iota kappa lambda mu",
            clock: clock,
            minimum: 650
        )
        let start = CFAbsoluteTimeGetCurrent()
        var typed = ""
        for character in engine.promptText.prefix(650) {
            let next = typed + String(character)
            if let edit = TypingTestEdit.between(typed, next) {
                engine.apply(edit, now: 0)
            }
            typed = next
        }
        let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
        precondition(engine.typedGraphemes.count == 650)
        print(String(format: "MEASURE event processing 650 committed graphemes: %.2f ms total (%.3f ms/event)", elapsed, elapsed / 650))

        let taskStart = CFAbsoluteTimeGetCurrent()
        for _ in 0..<20 {
            let localClock = FakeClock(0)
            _ = try makeEngine("alpha beta gamma", clock: localClock, minimum: 650)
        }
        let taskElapsed = (CFAbsoluteTimeGetCurrent() - taskStart) * 1000
        print(String(format: "MEASURE 20 prompt builds: %.2f ms total (%.3f ms/build)", taskElapsed, taskElapsed / 20))
    }
}
