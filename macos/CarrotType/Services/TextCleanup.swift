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
        // Whitespace and words inside fenced code are data. Prefer an unchanged transcript
        // over applying prose heuristics to it (also used by model failure fallback).
        if text.contains("```") { return text.trimmingCharacters(in: .whitespacesAndNewlines) }
        var result = text
            .replacingOccurrences(of: #"[^\S\r\n]+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Only unambiguous hesitation sounds. 'like', 'ну', 'типа' can carry meaning.
        let fillers = ["эм", "ээ", "um", "uh"]
        for filler in fillers {
            let pattern = "(?i)(^|\\s)" + NSRegularExpression.escapedPattern(for: filler) + "(?=\\s|$|,|\\.)[,\\.]*[ \t]*"
            result = result.replacingOccurrences(of: pattern, with: "$1", options: .regularExpression)
        }

        result = result
            .replacingOccurrences(of: #"[^\S\r\n]+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let first = result.first {
            result = String(first).uppercased() + result.dropFirst()
        }
        return result
    }
}
