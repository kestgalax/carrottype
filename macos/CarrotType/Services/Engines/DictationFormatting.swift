import Foundation

protocol CleanupEngine: Sendable {
    func cleanup(text: String, mode: CleanupMode, modelDirectory: URL?, instructions: String?) async throws -> String
    func formatDictation(text: String, mode: CleanupMode, modelDirectory: URL?, rules: DictationRules) async throws -> String
    func unload() async
}

extension CleanupEngine {
    func formatDictation(text: String, mode: CleanupMode, modelDirectory: URL?, rules: DictationRules) async throws -> String {
        try await cleanup(text: text, mode: mode, modelDirectory: modelDirectory, instructions: nil)
    }
}

typealias FormattingFallbackReason = DictationModelFailure

enum FormattingStyleOutcome: String, Equatable { case notRequested, generated, unchanged, unavailable, failed }

struct FormattingOutcome: Equatable {
    let requestedMode: CleanupMode
    let actualMode: CleanupMode
    let fallbackReason: FormattingFallbackReason?
    var exactRulesApplied = false
    var style: FormattingStyleOutcome = .notRequested

    var usedFallback: Bool { fallbackReason != nil }
}

struct FormattedDictation {
    let text: String
    let formatting: FormattingOutcome
}

/// Shared production formatting path; error details never become part of the result/UI.
enum DictationFormatting {
    private static func wording(_ text: String) -> [String] {
        text.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init)
    }

    static func perform(
        text: String, mode: CleanupMode, directory: URL?,
        engine: any CleanupEngine, lightEngine: any CleanupEngine, rules: DictationRules = DictationRules()
    ) async throws -> FormattedDictation {
        try Task.checkCancellation()
        let rules = rules.normalized
        let source = ExactDictationRules.removeWords(text, rules: rules)
        func completed(_ cleaned: String, actual: CleanupMode, reason: FormattingFallbackReason?) -> FormattedDictation {
            var style = FormattingStyleOutcome.notRequested
            if rules.businessStyle && !source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                if !mode.usesMLXHelper { style = .unavailable }
                else if reason != nil { style = .failed }
                else if wording(cleaned) == wording(source) { style = .unchanged }
                else { style = .generated }
            }
            return FormattedDictation(text: ExactDictationRules.apply(cleaned, rules: rules), formatting: FormattingOutcome(
                requestedMode: mode, actualMode: actual, fallbackReason: reason,
                exactRulesApplied: ExactDictationRules.enabled(rules), style: style))
        }
        // Explicit deletion may consume all speech. Never ask a model to invent a replacement.
        if source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return completed("", actual: .off, reason: nil)
        }
        var reason: FormattingFallbackReason?
        if mode.usesMLXHelper && directory == nil {
            reason = .modelUnavailable
        } else {
            do {
                let cleaned = try await engine.formatDictation(text: source, mode: mode, modelDirectory: directory, rules: rules)
                try Task.checkCancellation()
                return completed(cleaned, actual: mode, reason: nil)
            } catch is CancellationError {
                throw CancellationError()
            } catch let failure as DictationModelFailure {
                reason = failure
            } catch {
                reason = .generationFailed
            }
        }
        try Task.checkCancellation()
        let cleaned = try await lightEngine.cleanup(text: source, mode: .light, modelDirectory: nil, instructions: nil)
        try Task.checkCancellation()
        return completed(cleaned, actual: .light, reason: reason)
    }
}
