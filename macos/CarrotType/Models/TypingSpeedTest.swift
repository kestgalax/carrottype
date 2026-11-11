import Foundation

struct SplitMix64: RandomNumberGenerator, Sendable, Equatable {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

struct TypingTestPrompt: Equatable, Sendable {
    let language: TypingTestLanguage
    let level: TypingTestLevel
    fileprivate(set) var text: String
    fileprivate(set) var segments: [String]
    fileprivate(set) var graphemes: [Character]
    fileprivate var source: [String]
    fileprivate var queue: [String]
    fileprivate var generator: SplitMix64
    fileprivate var lastSegment: String?

    fileprivate init(
        language: TypingTestLanguage,
        level: TypingTestLevel,
        source: [String],
        seed: UInt64
    ) {
        self.language = language
        self.level = level
        self.text = ""
        self.segments = []
        self.graphemes = []
        self.source = source
        self.generator = SplitMix64(seed: seed)
        self.queue = []
        self.lastSegment = nil
    }
}

enum TypingTestModelError: Error, Equatable, CustomStringConvertible {
    case unsupportedCorpus(TypingTestLanguage, TypingTestLevel)
    case emptyCorpus(TypingTestLanguage, TypingTestLevel)

    var description: String {
        switch self {
        case .unsupportedCorpus(let language, let level):
            return "No corpus for \(language.rawValue)/\(level.rawValue)"
        case .emptyCorpus(let language, let level):
            return "Empty corpus for \(language.rawValue)/\(level.rawValue)"
        }
    }
}

/// Builds a fresh prompt from the bundled (or injected) corpus. All randomness is
/// injectable for deterministic production-model tests.
struct TypingTestPromptBuilder {
    let corpus: TypingTestCorpus
    let minimumGraphemes: Int

    init(corpus: TypingTestCorpus = .bundled, minimumGraphemes: Int = 650) {
        self.corpus = corpus
        self.minimumGraphemes = minimumGraphemes
    }

    func makePrompt(
        language: TypingTestLanguage,
        level: TypingTestLevel,
        seed: UInt64,
        avoiding previousPrompt: String? = nil
    ) throws -> TypingTestPrompt {
        guard let raw = corpus.fragments(for: language, level: level) else {
            throw TypingTestModelError.unsupportedCorpus(language, level)
        }
        let source = raw
            .map { $0.precomposedStringWithCanonicalMapping.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !source.isEmpty else {
            throw TypingTestModelError.emptyCorpus(language, level)
        }

        var prompt = TypingTestPrompt(language: language, level: level, source: source, seed: seed)
        extend(&prompt, toAtLeast: max(1, minimumGraphemes))
        // A new attempt inside one sheet must not repeat the immediately previous
        // whole prompt even if a caller injects the same seed twice.
        if let previousPrompt, prompt.text == previousPrompt {
            extend(&prompt, toAtLeast: prompt.graphemes.count + 1)
        }
        return prompt
    }

    /// Append only the next corpus fragment(s); the existing prompt and its deadline
    /// remain unchanged. Refill never shortens a 30-second attempt.
    func extend(_ prompt: inout TypingTestPrompt, toAtLeast minimumCount: Int) {
        while prompt.graphemes.count < minimumCount {
            let segment = nextSegment(&prompt)
            guard !segment.isEmpty else { return }
            if prompt.text.isEmpty {
                prompt.text = segment
            } else {
                prompt.text += " " + segment
            }
            prompt.segments.append(segment)
            prompt.lastSegment = segment
            prompt.graphemes = Array(prompt.text)
        }
    }

    private func nextSegment(_ prompt: inout TypingTestPrompt) -> String {
        if prompt.queue.isEmpty {
            prompt.queue = prompt.source.shuffled(using: &prompt.generator)
            // Do not place the same fragment immediately next to itself at a
            // refill boundary when the corpus has another option.
            if prompt.queue.count > 1, prompt.queue.first == prompt.lastSegment {
                prompt.queue.swapAt(0, 1)
            }
        }
        guard !prompt.queue.isEmpty else { return "" }
        var next = prompt.queue.removeFirst()
        if next == prompt.lastSegment, !prompt.queue.isEmpty {
            let alternative = prompt.queue.removeFirst()
            prompt.queue.insert(next, at: 0)
            next = alternative
        }
        return next
    }
}

struct TypingTestEdit: Equatable, Sendable {
    var replacedRange: Range<Int>
    var replacement: [Character]

    /// Diff of committed text. Uses a linear common-prefix/suffix scan rather than
    /// expensive edit distance; marked IME text is deliberately not passed here.
    static func between(_ old: String, _ new: String) -> TypingTestEdit? {
        let oldGraphemes = Array(old.precomposedStringWithCanonicalMapping)
        let newGraphemes = Array(new.precomposedStringWithCanonicalMapping)

        var prefix = 0
        while prefix < oldGraphemes.count,
              prefix < newGraphemes.count,
              oldGraphemes[prefix] == newGraphemes[prefix] {
            prefix += 1
        }
        var suffix = 0
        while suffix < oldGraphemes.count - prefix,
              suffix < newGraphemes.count - prefix,
              oldGraphemes[oldGraphemes.count - 1 - suffix] == newGraphemes[newGraphemes.count - 1 - suffix] {
            suffix += 1
        }

        let range = prefix..<(oldGraphemes.count - suffix)
        let replacement = Array(newGraphemes[prefix..<(newGraphemes.count - suffix)])
        guard !range.isEmpty || !replacement.isEmpty else { return nil }
        return TypingTestEdit(replacedRange: range, replacement: replacement)
    }
}

enum TypingTestMetrics {
    /// Characters from fully correct words plus their typed separators, plus the
    /// correct prefix of the current unfinished last word. Wrong words and wrong
    /// tails do not earn speed. A separator is credited only when it matches the
    /// expected separator (the bundled prompts use one space).
    static func creditedCharacters(typed: [Character], expected: [Character]) -> Int {
        let typedWords = words(in: typed)
        let expectedWords = words(in: expected)
        var credited = 0

        for index in typedWords.indices {
            guard index < expectedWords.count else { break }
            let typedWord = typedWords[index]
            let expectedWord = expectedWords[index]
            let isUnfinishedLastWord = index == typedWords.count - 1 && typedWord.separator.isEmpty

            if isUnfinishedLastWord {
                credited += commonPrefixLength(typedWord.characters, expectedWord.characters)
            } else if typedWord.characters == expectedWord.characters {
                credited += typedWord.characters.count
                if typedWord.separator == expectedWord.separator {
                    credited += typedWord.separator.count
                }
            }
        }
        return credited
    }

    private struct Word {
        var characters: [Character]
        var separator: [Character]
    }

    private static func words(in graphemes: [Character]) -> [Word] {
        var result: [Word] = []
        var index = 0
        while index < graphemes.count {
            while index < graphemes.count, graphemes[index].isWhitespace { index += 1 }
            guard index < graphemes.count else { break }
            var characters: [Character] = []
            while index < graphemes.count, !graphemes[index].isWhitespace {
                characters.append(graphemes[index])
                index += 1
            }
            var separator: [Character] = []
            while index < graphemes.count, graphemes[index].isWhitespace {
                separator.append(graphemes[index])
                index += 1
            }
            result.append(Word(characters: characters, separator: separator))
        }
        return result
    }

    private static func commonPrefixLength(_ lhs: [Character], _ rhs: [Character]) -> Int {
        var count = 0
        while count < lhs.count, count < rhs.count, lhs[count] == rhs[count] {
            count += 1
        }
        return count
    }
}

enum TypingTestPhase: Equatable, Sendable {
    case ready
    case running
    case completed
    case cancelled
}

struct TypingTestResult: Equatable, Sendable {
    let rawWPM: Double
    let rawCPM: Double
    let accuracyPercent: Double
    let duration: TimeInterval
    let language: TypingTestLanguage
    let level: TypingTestLevel
    let creditedCharacters: Int
    let attempts: Int
    let correctAttempts: Int

    var roundedWPM: Int { Int(rawWPM.rounded()) }
    var roundedCPM: Int { Int(rawCPM.rounded()) }
    var isWPMInExistingRange: Bool {
        rawWPM >= Double(UsageStatsEstimate.minimumWPM)
            && rawWPM <= Double(UsageStatsEstimate.maximumWPM)
    }
    /// Accuracy is informational: it is never an acceptance threshold.
    var canApply: Bool { creditedCharacters > 0 && isWPMInExistingRange }
}

/// Pure attempt model. The first committed printable grapheme fixes the monotonic
/// deadline; a UI timer only displays the remainder.
final class TypingSpeedTestEngine {
    let duration: TimeInterval
    private let builder: TypingTestPromptBuilder
    private let clock: () -> TimeInterval

    private(set) var phase: TypingTestPhase = .ready
    private(set) var prompt: TypingTestPrompt
    private(set) var typedGraphemes: [Character] = []
    private(set) var expectedGraphemes: [Character]
    private(set) var startedAt: TimeInterval?
    private(set) var deadline: TimeInterval?
    private(set) var attempts = 0
    private(set) var correctAttempts = 0
    private(set) var result: TypingTestResult?

    init(
        prompt: TypingTestPrompt,
        builder: TypingTestPromptBuilder,
        duration: TimeInterval = 30,
        clock: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }
    ) {
        self.prompt = prompt
        self.builder = builder
        self.duration = duration
        self.clock = clock
        self.expectedGraphemes = prompt.graphemes
    }

    var typedText: String { String(typedGraphemes) }
    var promptText: String { prompt.text }

    var remainingSeconds: TimeInterval {
        guard phase == .running, let deadline else { return duration }
        return max(0, deadline - clock())
    }

    /// Apply one committed text-edit (insertion, deletion, or replacement). Late
    /// events complete the attempt at the fixed deadline and are not credited.
    @discardableResult
    func apply(_ edit: TypingTestEdit, now: TimeInterval? = nil) -> Bool {
        let now = now ?? clock()
        switch phase {
        case .ready, .running:
            break
        case .completed, .cancelled:
            return false
        }

        if phase == .ready {
            guard !edit.replacement.isEmpty else { return false }
            phase = .running
            startedAt = now
            deadline = now + duration
        }

        if let deadline, now >= deadline {
            finish(at: deadline)
            return false
        }

        let lower = min(max(0, edit.replacedRange.lowerBound), typedGraphemes.count)
        let upper = min(max(lower, edit.replacedRange.upperBound), typedGraphemes.count)
        ensureExpectedCapacity(lower + edit.replacement.count + 16)

        if !edit.replacement.isEmpty {
            for offset in edit.replacement.indices {
                let expectedIndex = lower + offset
                attempts += 1
                guard expectedIndex < expectedGraphemes.count else { continue }
                let normalized = String(edit.replacement[offset]).precomposedStringWithCanonicalMapping
                if let character = normalized.first, normalized.count == 1,
                   character == expectedGraphemes[expectedIndex] {
                    correctAttempts += 1
                }
            }
        }

        typedGraphemes.replaceSubrange(lower..<upper, with: edit.replacement)
        return true
    }

    /// Display-only tick. It may complete the attempt at the fixed deadline but its
    /// tick count never defines duration or speed.
    @discardableResult
    func tick(now: TimeInterval? = nil) -> Bool {
        let now = now ?? clock()
        guard phase == .running, let deadline, now >= deadline else { return false }
        finish(at: deadline)
        return true
    }

    func cancel() {
        guard phase == .ready || phase == .running else { return }
        phase = .cancelled
        result = nil
    }

    private func ensureExpectedCapacity(_ capacity: Int) {
        while expectedGraphemes.count < capacity {
            let before = prompt.graphemes.count
            builder.extend(&prompt, toAtLeast: before + 1)
            guard prompt.graphemes.count > before else { return }
            expectedGraphemes = prompt.graphemes
        }
    }

    private func finish(at time: TimeInterval) {
        guard phase == .running, let startedAt else { return }
        phase = .completed
        let credited = TypingTestMetrics.creditedCharacters(
            typed: typedGraphemes,
            expected: expectedGraphemes
        )
        let seconds = max(0.001, time - startedAt)
        let cpm = Double(credited) * 60 / seconds
        let wpm = cpm / 5
        let accuracy = attempts == 0 ? 0 : Double(correctAttempts) / Double(attempts) * 100
        result = TypingTestResult(
            rawWPM: wpm,
            rawCPM: cpm,
            accuracyPercent: accuracy,
            duration: duration,
            language: prompt.language,
            level: prompt.level,
            creditedCharacters: credited,
            attempts: attempts,
            correctAttempts: correctAttempts
        )
    }
}
