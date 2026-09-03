import SwiftUI

/// Top-level Settings sidebar destinations (Status is a header, not a pane).
enum SettingsPane: String, CaseIterable, Identifiable, Hashable {
    case general
    case setup
    case models
    case storage
    case statistics

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .general: return "info.square"
        case .setup: return "gear"
        case .models: return "cpu"
        case .storage: return "internaldrive"
        case .statistics: return "chart.bar"
        }
    }

    func title(locale: Locale) -> String {
        switch self {
        case .general: return L10n.t("settings.pane.general", locale: locale)
        case .setup: return L10n.t("settings.pane.setup", locale: locale)
        case .models: return L10n.t("settings.pane.models", locale: locale)
        case .storage: return L10n.t("settings.pane.storage", locale: locale)
        case .statistics: return L10n.t("settings.pane.statistics", locale: locale)
        }
    }
}
