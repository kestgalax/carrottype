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
        precondition(notes.content(locale: Locale(identifier: "de"))?.summary == notes.localizations["en"]?.summary)
        precondition(notes.content(locale: Locale(identifier: "ru"))?.visibleSections.count == 2)
        do {
            _ = try ReleaseNotes.decode(source, version: version, build: "999999999")
            fatalError("Mismatched build accepted")
        } catch {}
        var json = try JSONSerialization.jsonObject(with: source) as! [String: Any]
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
        print("PASS production release notes: matching metadata, language fallback, hidden empty sections, invalid dates, fresh/upgrade/relaunch/read tracking and safe corrupt-resource fallback")
    }
}
