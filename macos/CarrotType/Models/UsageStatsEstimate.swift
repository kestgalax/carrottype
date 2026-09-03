import Foundation

/// Display-time estimate of typing time vs recording time (ADR-013).
/// Not a measurement of the user's real typing speed.
enum UsageStatsEstimate {
    static let defaultWPM = 50
    static let minimumWPM = 10
    static let maximumWPM = 200
    /// Typing-test convention: one word is five characters including spaces.
    static let charactersPerWord = 5

    struct Result: Equatable, Sendable {
        var typingSeconds: TimeInterval
        var savedSeconds: TimeInterval
    }

    static func clampedWPM(_ value: Int) -> Int {
        min(maximumWPM, max(minimumWPM, value))
    }

    static func estimate(
        characters: Int,
        recordingMilliseconds: Int,
        wordsPerMinute: Int
    ) -> Result {
        let wpm = Double(clampedWPM(wordsPerMinute))
        let charsPerMinute = wpm * Double(charactersPerWord)
        let typingSeconds: TimeInterval
        if characters <= 0 || charsPerMinute <= 0 {
            typingSeconds = 0
        } else {
            typingSeconds = Double(characters) / (charsPerMinute / 60.0)
        }
        let recordingSeconds = max(0, Double(recordingMilliseconds) / 1000.0)
        return Result(
            typingSeconds: typingSeconds,
            savedSeconds: max(0, typingSeconds - recordingSeconds)
        )
    }

    static func durationString(_ seconds: TimeInterval, locale: Locale) -> String {
        let total = max(0, Int(seconds.rounded()))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        if hours > 0 {
            return String(
                format: L10n.t("stats.duration.hours_minutes", locale: locale),
                hours,
                minutes
            )
        }
        if minutes > 0, secs > 0 {
            return String(
                format: L10n.t("stats.duration.minutes_seconds", locale: locale),
                minutes,
                secs
            )
        }
        if minutes > 0 {
            return String(format: L10n.t("stats.duration.minutes", locale: locale), minutes)
        }
        return String(format: L10n.t("stats.duration.seconds", locale: locale), secs)
    }
}
