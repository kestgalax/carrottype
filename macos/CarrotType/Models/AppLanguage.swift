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
            return AppLanguageCode.russian
        case .english:
            return AppLanguageCode.english
        case .system:
            return AppLanguageCode.resolve(
                Locale.autoupdatingCurrent.language.languageCode?.identifier,
                fallback: AppLanguageCode.english
            )
        }
    }

    /// Sparkle selects its own UI and localized appcast `<description>` from the
    /// process preferred localizations, which only read the app-domain
    /// `AppleLanguages` key when a process starts. Mirroring an explicit in-app
    /// language there keeps the next launch's standard update window consistent
    /// with What's New (which follows `effectiveLocale` immediately).
    /// Only remove the key when this bridge created it, so a user's own per-app
    /// language choice is never overwritten.
    static let appleLanguagesKey = "AppleLanguages"
    static let updaterBridgeMarkerKey = "carrottype.updaterLanguageBridge"

    func synchronizeUpdaterPresentationLanguage(defaults: UserDefaults = .standard) {
        switch self {
        case .system:
            guard defaults.bool(forKey: Self.updaterBridgeMarkerKey) else { return }
            defaults.removeObject(forKey: Self.appleLanguagesKey)
            defaults.removeObject(forKey: Self.updaterBridgeMarkerKey)
        case .russian:
            defaults.set([AppLanguageCode.russian], forKey: Self.appleLanguagesKey)
            defaults.set(true, forKey: Self.updaterBridgeMarkerKey)
        case .english:
            defaults.set([AppLanguageCode.english], forKey: Self.appleLanguagesKey)
            defaults.set(true, forKey: Self.updaterBridgeMarkerKey)
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
        let lang = AppLanguageCode.resolve(
            (locale ?? preferredLocale).language.languageCode?.identifier,
            fallback: preferredLanguageCode
        )
        guard let path = Bundle.main.path(forResource: lang, ofType: "lproj"),
              let bundle = Bundle(path: path)
        else {
            return Bundle.main.localizedString(forKey: key, value: key, table: "Localizable")
        }
        return bundle.localizedString(forKey: key, value: key, table: "Localizable")
    }
}
