import Foundation

@main
struct Checks {
    @MainActor
    static func main() throws {
        let root = URL(fileURLWithPath: CommandLine.arguments[1])
        let temp = URL(fileURLWithPath: CommandLine.arguments[2])
        let source = try Data(contentsOf: root.appendingPathComponent("macos/CarrotType/Resources/ReleaseNotes.json"))
        let info = try PropertyListSerialization.propertyList(from: Data(contentsOf: root.appendingPathComponent("macos/CarrotType/Info.plist")), format: nil) as! [String: Any]
        let version = info["CFBundleShortVersionString"] as! String
        let build = info["CFBundleVersion"] as! String
        let notes = try ReleaseNotes.decode(source, version: version, build: build)
        // Shared language resolution: any ru* variant picks RU, unknown/system
        // locales keep the English fallback used by L10n.
        precondition(AppLanguageCode.resolve("ru", fallback: "en") == "ru")
        precondition(AppLanguageCode.resolve("ru_RU", fallback: "en") == "ru")
        precondition(AppLanguageCode.resolve("ru-RU", fallback: "en") == "ru")
        precondition(AppLanguageCode.resolve("en_GB", fallback: "ru") == "en")
        precondition(AppLanguageCode.resolve("de", fallback: "ru") == "en")
        precondition(AppLanguageCode.resolve(nil, fallback: "ru") == "ru")
        precondition(AppLanguageCode.resolve(nil, fallback: nil) == "en")
        precondition(AppLanguage.russian.effectiveLocale.language.languageCode?.identifier == "ru")
        precondition(AppLanguage.english.effectiveLocale.language.languageCode?.identifier == "en")
        precondition(notes.content(locale: AppLanguage.russian.effectiveLocale)?.summary == notes.localizations["ru"]?.summary)
        precondition(notes.content(locale: AppLanguage.english.effectiveLocale)?.summary == notes.localizations["en"]?.summary)
        precondition(notes.content(locale: Locale(identifier: "ru_RU"))?.summary == notes.localizations["ru"]?.summary)
        precondition(notes.content(locale: Locale(identifier: "de_DE"))?.summary == notes.localizations["en"]?.summary)
        precondition(notes.content(locale: Locale(identifier: "de_DE"), preferredLanguageCode: "ru")?.summary == notes.localizations["en"]?.summary)
        precondition(notes.content(locale: Locale(identifier: ""), preferredLanguageCode: "ru")?.summary == notes.localizations["ru"]?.summary)
        // Sparkle's preferred-localization bridge: only manage AppleLanguages
        // when CarrotType wrote it, and restore system behavior afterwards.
        let languageSuite = "carrottype-language-checks-" + UUID().uuidString
        let languageDefaults = UserDefaults(suiteName: languageSuite)!
        defer { languageDefaults.removePersistentDomain(forName: languageSuite) }
        languageDefaults.set(["fr"], forKey: AppLanguage.appleLanguagesKey)
        AppLanguage.system.synchronizeUpdaterPresentationLanguage(defaults: languageDefaults)
        precondition(languageDefaults.stringArray(forKey: AppLanguage.appleLanguagesKey) == ["fr"]) // user-owned override untouched
        AppLanguage.russian.synchronizeUpdaterPresentationLanguage(defaults: languageDefaults)
        precondition(languageDefaults.stringArray(forKey: AppLanguage.appleLanguagesKey) == ["ru"])
        precondition(languageDefaults.bool(forKey: AppLanguage.updaterBridgeMarkerKey))
        AppLanguage.english.synchronizeUpdaterPresentationLanguage(defaults: languageDefaults)
        precondition(languageDefaults.stringArray(forKey: AppLanguage.appleLanguagesKey) == ["en"])
        AppLanguage.system.synchronizeUpdaterPresentationLanguage(defaults: languageDefaults)
        precondition(languageDefaults.persistentDomain(forName: languageSuite)?[AppLanguage.appleLanguagesKey] == nil)
        precondition(!languageDefaults.bool(forKey: AppLanguage.updaterBridgeMarkerKey))
        precondition(notes.content(locale: Locale(identifier: "de"))?.summary == notes.localizations["en"]?.summary)
        precondition(notes.content(locale: Locale(identifier: "ru")) != nil)
        do {
            _ = try ReleaseNotes.decode(source, version: version, build: "999999999")
            fatalError("Mismatched build accepted")
        } catch {}
        var json = try JSONSerialization.jsonObject(with: source) as! [String: Any]
        // Controlled empty-section fixture, independent of the current release's sections.
        var emptyFixture = json
        var localizations = emptyFixture["localizations"] as! [String: Any]
        var russian = localizations["ru"] as! [String: Any]
        russian["sections"] = [
            ["kind": "new", "items": []],
            ["kind": "fixed", "items": [["title": "Kept section"]]]
        ]
        localizations["ru"] = russian
        emptyFixture["localizations"] = localizations
        let decoded = try ReleaseNotes.decode(JSONSerialization.data(withJSONObject: emptyFixture), version: version, build: build)
        precondition(decoded.content(locale: Locale(identifier: "ru"))?.visibleSections.map(\.id) == ["fixed"])
        json["date"] = "2026-02-31"
        do {
            _ = try ReleaseNotes.decode(JSONSerialization.data(withJSONObject: json), version: version, build: build)
            fatalError("Invalid date accepted")
        } catch {}
        let suite = "carrottype-release-checks-" + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        func bundle(_ build: String, corrupt: Bool = false) throws -> Bundle {
            let url = temp.appendingPathComponent(UUID().uuidString + ".bundle")
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            let info = ["CFBundleIdentifier": "carrottype.tests." + UUID().uuidString,
                        "CFBundleShortVersionString": "0.6.1", "CFBundleVersion": build]
            try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0).write(to: url.appendingPathComponent("Info.plist"))
            var data = try JSONSerialization.jsonObject(with: source) as! [String: Any]
            data["build"] = build
            data["version"] = "0.6.1"
            try (corrupt ? Data("broken".utf8) : JSONSerialization.data(withJSONObject: data))
                .write(to: url.appendingPathComponent("ReleaseNotes.json"))
            return Bundle(url: url)!
        }
        let old = try bundle("26"), current = try bundle("27")
        let fresh = ReleaseNotesStore(bundle: old, defaults: defaults)
        precondition(!fresh.hasUnreadChanges && fresh.notes != nil)
        let upgraded = ReleaseNotesStore(bundle: current, defaults: defaults)
        precondition(upgraded.hasUnreadChanges && upgraded.notes != nil)
        precondition(ReleaseNotesStore(bundle: current, defaults: defaults).hasUnreadChanges)
        upgraded.markRead()
        precondition(!upgraded.hasUnreadChanges)
        precondition(!ReleaseNotesStore(bundle: current, defaults: defaults).hasUnreadChanges)
        let broken = ReleaseNotesStore(bundle: try bundle("28", corrupt: true), defaults: defaults)
        precondition(broken.notes == nil && broken.version == "0.6.1")
        // Real bundled archive: five skipped builds, baseline persistence and safe fallbacks.
        let historySource = try Data(contentsOf: root.appendingPathComponent("macos/CarrotType/Resources/ReleaseNotesHistory.json"))
        let history = try ReleaseNotes.decodeHistory(historySource, current: notes)
        let currentBuild = Int(build)!
        precondition(history.map(\.build) == stride(from: currentBuild - 1, through: 27, by: -1).map(String.init))
        let shippingURL = temp.appendingPathComponent("shipping.bundle")
        try FileManager.default.createDirectory(at: shippingURL, withIntermediateDirectories: true)
        try PropertyListSerialization.data(fromPropertyList: ["CFBundleIdentifier": "carrottype.tests.shipping", "CFBundleShortVersionString": version, "CFBundleVersion": build], format: .xml, options: 0).write(to: shippingURL.appendingPathComponent("Info.plist"))
        try source.write(to: shippingURL.appendingPathComponent("ReleaseNotes.json"))
        let historyURL = shippingURL.appendingPathComponent("ReleaseNotesHistory.json")
        try historySource.write(to: historyURL)
        let shipping = Bundle(url: shippingURL)!
        func setPrevious(_ value: String?) {
            defaults.removePersistentDomain(forName: suite)
            if let value { defaults.set(value, forKey: "carrottype.releaseNotes.observedVersion") }
        }
        setPrevious("0.6.1 (\(currentBuild - 5))")
        let skipped = ReleaseNotesStore(bundle: shipping, defaults: defaults)
        precondition(skipped.releases.map(\.build) == stride(from: currentBuild, through: currentBuild - 4, by: -1).map(String.init))
        precondition(skipped.previousVersion == "0.6.1" && skipped.limitedHistorySince == nil && skipped.hasUnreadChanges)
        precondition(ReleaseNotesStore(bundle: shipping, defaults: defaults).releases.map(\.build) == skipped.releases.map(\.build))
        skipped.markRead()
        let reopened = ReleaseNotesStore(bundle: shipping, defaults: defaults)
        precondition(!reopened.hasUnreadChanges && reopened.releases.map(\.build) == skipped.releases.map(\.build))
        setPrevious("0.8.1 (\(currentBuild - 1))")
        precondition(ReleaseNotesStore(bundle: shipping, defaults: defaults).releases.map(\.build) == [build])
        setPrevious("0.5.0 (25)")
        let partial = ReleaseNotesStore(bundle: shipping, defaults: defaults)
        precondition(partial.releases.count == currentBuild - 26 && partial.limitedHistorySince == "0.6.1")
        for value in [nil, "invalid", "0.9.0 (\(currentBuild + 1))", "0.1.0 (99999999999999999999999)"] as [String?] {
            setPrevious(value)
            let safe = ReleaseNotesStore(bundle: shipping, defaults: defaults)
            precondition(safe.releases.map(\.build) == [build] && safe.previousVersion == nil)
            if value == nil { precondition(!safe.hasUnreadChanges) }
        }
        // A later actual upgrade replaces the saved range instead of keeping an older baseline.
        setPrevious("0.6.1 (\(currentBuild - 5))")
        _ = ReleaseNotesStore(bundle: shipping, defaults: defaults)
        let nextBundle = try bundle(String(currentBuild + 1))
        let next = ReleaseNotesStore(bundle: nextBundle, defaults: defaults)
        precondition(next.previousVersion == version && next.releases.map(\.build) == [String(currentBuild + 1)])
        var entries = try JSONSerialization.jsonObject(with: historySource) as! [[String: Any]]
        entries[1]["build"] = String(currentBuild - 1) // duplicate/gap must reject the entire archive
        do {
            _ = try ReleaseNotes.decodeHistory(JSONSerialization.data(withJSONObject: entries), current: notes)
            fatalError("Invalid history accepted")
        } catch {}
        try Data("broken".utf8).write(to: historyURL)
        setPrevious("0.6.1 (\(currentBuild - 5))")
        let damaged = ReleaseNotesStore(bundle: shipping, defaults: defaults)
        precondition(damaged.releases.map(\.build) == [build] && damaged.limitedHistorySince == version)
        try FileManager.default.removeItem(at: historyURL)
        setPrevious("0.8.1 (\(currentBuild - 1))")
        precondition(ReleaseNotesStore(bundle: shipping, defaults: defaults).releases.map(\.build) == [build])
        print("PASS cumulative history: skip five, one-step, persistent range/read, fresh/unknown/downgrade/overflow, coverage and corrupt/missing archive fallback")
        print("PASS production release notes: matching metadata, language fallback, hidden empty sections, invalid dates, fresh/upgrade/relaunch/read tracking and safe corrupt-resource fallback")
    }
}
