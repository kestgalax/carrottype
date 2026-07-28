import Foundation

enum TextCleanup {
    static func apply(_ text: String, mode: CleanupMode) -> String {
        switch mode {
        case .off:
            return text
        case .light, .smart, .smartPlus, .gemma:
            // MLX modes use out-of-process helper (ADR-009); heuristics here for Light/fallback.
            return light(text)
        }
    }

    private static func light(_ text: String) -> String {
        var result = text
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let fillers = [
            "эм", "ээ", "аа", "ну", "типа", "как бы", "в общем",
            "um", "uh", "like", "you know",
        ]
        for filler in fillers {
            let pattern = "(?i)(^|\\s)" + NSRegularExpression.escapedPattern(for: filler) + "(?=\\s|$|,|\\.)"
            result = result.replacingOccurrences(of: pattern, with: "$1", options: .regularExpression)
        }

        result = result
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let first = result.first {
            result = String(first).uppercased() + result.dropFirst()
        }
        return result
    }
}
