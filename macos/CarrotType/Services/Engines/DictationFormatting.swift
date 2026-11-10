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

enum FormattingFallbackReason: Equatable, Sendable {
    case modelUnavailable
    case generationFailed
}

struct FormattingOutcome: Equatable {
    let requestedMode: CleanupMode
    let actualMode: CleanupMode
    let fallbackReason: FormattingFallbackReason?

    var usedFallback: Bool { fallbackReason != nil }
}

struct FormattedDictation {
    let text: String
    let formatting: FormattingOutcome
}

/// Shared production formatting path; error details never become part of the result/UI.
enum DictationFormatting {
    static func perform(
        text: String, mode: CleanupMode, directory: URL?,
        engine: any CleanupEngine, lightEngine: any CleanupEngine, rules: DictationRules = DictationRules()
    ) async throws -> FormattedDictation {
        try Task.checkCancellation()
        var reason: FormattingFallbackReason?
        if mode.usesMLXHelper && directory == nil {
            reason = .modelUnavailable
        } else {
            do {
                let cleaned = try await engine.formatDictation(text: text, mode: mode, modelDirectory: directory, rules: rules)
                try Task.checkCancellation()
                return FormattedDictation(text: cleaned, formatting: FormattingOutcome(
                    requestedMode: mode, actualMode: mode, fallbackReason: nil
                ))
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                reason = .generationFailed
            }
        }
        try Task.checkCancellation()
        let cleaned = try await lightEngine.cleanup(text: text, mode: .light, modelDirectory: nil, instructions: nil)
        return FormattedDictation(text: cleaned, formatting: FormattingOutcome(
            requestedMode: mode, actualMode: .light, fallbackReason: reason
        ))
    }
}
