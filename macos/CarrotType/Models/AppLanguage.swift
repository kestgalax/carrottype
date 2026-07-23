import Foundation

/// In-app language preference. Default follows the system locale (`ru*` → Russian, else English).
enum AppLanguage: String, CaseIterable, Identifiable, Hashable {
    case system
    case russian
    case english

    var id: String { rawValue }

    static let defaultsKey = "carrottype.appLanguage"

    /// Locale used for UI formatting and L10n lookup.
    var effectiveLocale: Locale {
        Locale(identifier: effectiveLanguageCode)
    }

    var effectiveLanguageCode: String {
        switch self {
        case .russian:
            return "ru"
        case .english:
            return "en"
        case .system:
            if Locale.autoupdatingCurrent.language.languageCode?.identifier == "ru" {
                return "ru"
            }
            return "en"
        }
    }

    func title(locale: Locale) -> String {
        switch self {
        case .system: return L10n.t("language.system", locale: locale)
        case .russian: return L10n.t("language.russian", locale: locale)
        case .english: return L10n.t("language.english", locale: locale)
        }
    }
}

/// Resolves UI copy from compiled `*.lproj/Localizable.strings` by explicit language.
/// System `String(localized:)` follows preferredLanguages and ignores in-app overrides.
enum L10n {
    static var preferredLocale: Locale {
        if let raw = UserDefaults.standard.string(forKey: AppLanguage.defaultsKey),
           let language = AppLanguage(rawValue: raw) {
            return language.effectiveLocale
        }
        return AppLanguage.system.effectiveLocale
    }

    static var preferredLanguageCode: String {
        if let raw = UserDefaults.standard.string(forKey: AppLanguage.defaultsKey),
           let language = AppLanguage(rawValue: raw) {
            return language.effectiveLanguageCode
        }
        return AppLanguage.system.effectiveLanguageCode
    }

    static func t(_ key: String, locale: Locale? = nil) -> String {
        let code = (locale ?? preferredLocale).language.languageCode?.identifier
            ?? preferredLanguageCode
        let lang = code.hasPrefix("ru") ? "ru" : "en"
        guard let path = Bundle.main.path(forResource: lang, ofType: "lproj"),
              let bundle = Bundle(path: path)
        else {
            return Bundle.main.localizedString(forKey: key, value: key, table: "Localizable")
        }
        return bundle.localizedString(forKey: key, value: key, table: "Localizable")
    }
}
