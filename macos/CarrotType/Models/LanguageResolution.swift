import Foundation

/// Single source of truth for the two shipped interface/release-note languages.
/// Any `ru*` identifier resolves to Russian; everything else falls back to English.
/// Explicit unknown identifiers also fall back, so a stale system locale can never
/// make release notes disagree with the in-app language override.
enum AppLanguageCode {
    static let english = "en"
    static let russian = "ru"
    static let supported = [english, russian]

    static func normalized(_ identifier: String?) -> String? {
        guard let identifier, !identifier.isEmpty else { return nil }
        return identifier.lowercased().hasPrefix(russian) ? russian : english
    }

    /// Uses the explicit identifier when present, otherwise the caller's fallback
    /// (for example `L10n.preferredLanguageCode`).
    static func resolve(_ identifier: String?, fallback: @autoclosure () -> String?) -> String {
        normalized(identifier) ?? normalized(fallback()) ?? english
    }
}
