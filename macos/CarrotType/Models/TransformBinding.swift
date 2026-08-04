import Foundation

enum TransformKind: String, Codable, CaseIterable, Identifiable {
    case translate
    case custom

    var id: String { rawValue }

    func title(locale: Locale) -> String {
        switch self {
        case .translate: return L10n.t("transform.kind.translate", locale: locale)
        case .custom: return L10n.t("transform.kind.custom", locale: locale)
        }
    }
}

/// Curated language codes for Translate pair pickers (NLLanguageRecognizer-friendly).
enum TransformLanguageCatalog {
    static let codes: [String] = [
        "en", "ru", "de", "fr", "es", "it", "pt", "zh-Hans", "ja", "ko",
    ]

    static func displayName(code: String, locale: Locale) -> String {
        let key = "transform.lang.\(code)"
        let localized = L10n.t(key, locale: locale)
        return localized == key ? code : localized
    }

    static func shortLabel(code: String) -> String {
        switch code {
        case "zh-Hans": return "ZH"
        default: return code.uppercased()
        }
    }

    /// Map NLLanguageRecognizer / BCP-47 hypothesis onto a catalog/pair code.
    static func normalize(_ raw: String) -> String {
        let lower = raw.lowercased().replacingOccurrences(of: "_", with: "-")
        if lower.hasPrefix("zh") { return "zh-Hans" }
        if let exact = codes.first(where: { $0.lowercased() == lower }) {
            return exact
        }
        let primary = lower.split(separator: "-").first.map(String.init) ?? lower
        if let match = codes.first(where: { $0.lowercased().hasPrefix(primary) }) {
            return match
        }
        return primary
    }
}

struct TransformBinding: Identifiable, Codable, Equatable {
    var id: UUID
    var chord: KeyChord
    var kind: TransformKind
    var customInstruction: String
    var cleanupMode: CleanupMode
    var languageA: String
    var languageB: String

    static let maxCount = 5

    static func makeDefault(cleanupMode: CleanupMode = .smart) -> TransformBinding {
        TransformBinding(
            id: UUID(),
            chord: .defaultTransform,
            kind: .translate,
            customInstruction: "",
            cleanupMode: cleanupMode.usesMLXHelper ? cleanupMode : .smart,
            languageA: "ru",
            languageB: "en"
        )
    }

    mutating func ensureDistinctLanguages() {
        if languageA == languageB {
            languageB = languageA == "en" ? "ru" : "en"
        }
        if !TransformLanguageCatalog.codes.contains(languageA) {
            languageA = "ru"
        }
        if !TransformLanguageCatalog.codes.contains(languageB) {
            languageB = "en"
        }
        if languageA == languageB {
            languageB = languageA == "en" ? "ru" : "en"
        }
    }
}

enum TransformBindingsStore {
    static let defaultsKey = "carrottype.transformBindings"
    private static let legacyChordKey = "carrottype.transformHotkeyChord"
    private static let legacyInstructionKey = "carrottype.transformInstruction"
    private static let legacyModeKey = "carrottype.transformCleanupMode"

    static func load(
        defaults: UserDefaults = .standard,
        preferredCleanupMode: CleanupMode = .smart
    ) -> [TransformBinding] {
        if let data = defaults.data(forKey: defaultsKey),
           var decoded = try? JSONDecoder().decode([TransformBinding].self, from: data),
           !decoded.isEmpty {
            for i in decoded.indices {
                decoded[i].ensureDistinctLanguages()
                if !decoded[i].cleanupMode.usesMLXHelper {
                    decoded[i].cleanupMode = .smart
                }
            }
            return Array(decoded.prefix(TransformBinding.maxCount))
        }

        let migrated = migrateLegacy(defaults: defaults, preferredCleanupMode: preferredCleanupMode)
        save(migrated, defaults: defaults)
        clearLegacyKeys(defaults: defaults)
        return migrated
    }

    static func save(_ bindings: [TransformBinding], defaults: UserDefaults = .standard) {
        var copy = Array(bindings.prefix(TransformBinding.maxCount))
        for i in copy.indices {
            copy[i].ensureDistinctLanguages()
        }
        if let data = try? JSONEncoder().encode(copy) {
            defaults.set(data, forKey: defaultsKey)
        }
    }

    /// Package IDs referenced by saved transform bindings (Storage Active / delete-unused).
    static func referencedCleanupPackageIDs(defaults: UserDefaults = .standard) -> Set<String> {
        guard let data = defaults.data(forKey: defaultsKey),
              let decoded = try? JSONDecoder().decode([TransformBinding].self, from: data) else {
            return []
        }
        return Set(decoded.compactMap { $0.cleanupMode.requiredPackageID })
    }

    /// After a cleanup package is deleted, point bindings at another MLX mode.
    static func remapCleanupMode(
        removingPackageID: String,
        fallback: CleanupMode,
        defaults: UserDefaults = .standard
    ) {
        guard let data = defaults.data(forKey: defaultsKey),
              var decoded = try? JSONDecoder().decode([TransformBinding].self, from: data),
              !decoded.isEmpty else {
            return
        }
        let mode = fallback.usesMLXHelper ? fallback : .smart
        var changed = false
        for i in decoded.indices {
            if decoded[i].cleanupMode.requiredPackageID == removingPackageID {
                decoded[i].cleanupMode = mode
                changed = true
            }
        }
        if changed {
            save(decoded, defaults: defaults)
        }
    }

    private static func migrateLegacy(
        defaults: UserDefaults,
        preferredCleanupMode: CleanupMode
    ) -> [TransformBinding] {
        let chord: KeyChord
        if let data = defaults.data(forKey: legacyChordKey),
           let saved = try? JSONDecoder().decode(KeyChord.self, from: data) {
            chord = saved
        } else {
            chord = .defaultTransform
        }

        let instruction = defaults.string(forKey: legacyInstructionKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let mode: CleanupMode
        if let raw = defaults.string(forKey: legacyModeKey),
           let parsed = CleanupMode(rawValue: raw),
           parsed.usesMLXHelper {
            mode = parsed
        } else if preferredCleanupMode.usesMLXHelper {
            mode = preferredCleanupMode
        } else {
            mode = .smart
        }

        let looksLikeTranslate = instruction.isEmpty
            || instruction.localizedCaseInsensitiveContains("перевед")
            || instruction.localizedCaseInsensitiveContains("translate")

        if looksLikeTranslate {
            var binding = TransformBinding.makeDefault(cleanupMode: mode)
            binding.chord = chord
            return [binding]
        }

        return [
            TransformBinding(
                id: UUID(),
                chord: chord,
                kind: .custom,
                customInstruction: instruction,
                cleanupMode: mode,
                languageA: "ru",
                languageB: "en"
            ),
        ]
    }

    private static func clearLegacyKeys(defaults: UserDefaults) {
        defaults.removeObject(forKey: legacyInstructionKey)
        defaults.removeObject(forKey: legacyModeKey)
        defaults.removeObject(forKey: legacyChordKey)
        defaults.removeObject(forKey: "carrottype.transformHotkeyDisplay")
    }
}
