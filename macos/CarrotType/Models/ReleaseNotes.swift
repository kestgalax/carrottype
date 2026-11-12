import Foundation
import Combine

/// Shipped product information only. Never fetches or stores user content.
struct ReleaseNotes: Decodable {
    struct Item: Decodable {
        let title: String
        let detail: String?
    }
    struct Section: Decodable, Identifiable {
        enum Kind: String, Decodable { case new, improved, fixed }
        let kind: Kind
        let items: [Item]
        var id: String { kind.rawValue }
    }
    struct Content: Decodable {
        let summary: String
        let sections: [Section]
        var visibleSections: [Section] { sections.filter { !$0.items.isEmpty } }
    }
    let schemaVersion: Int
    let version: String
    let build: String
    let date: String
    let localizations: [String: Content]

    var identity: String { "\(version) (\(build))" }
    var changelogURL: URL? { URL(string: "https://github.com/kestgalax/carrottype/releases") }

    /// Resolves notes with the same language rules as `L10n`: explicit `ru*`
    /// variants win, otherwise the in-app preference, otherwise English.
    func content(locale: Locale, preferredLanguageCode: String? = nil) -> Content? {
        let code = AppLanguageCode.resolve(
            locale.language.languageCode?.identifier,
            fallback: preferredLanguageCode ?? L10n.preferredLanguageCode
        )
        return localizations[code] ?? localizations["en"]
    }

    static func decode(_ data: Data, version: String, build: String) throws -> ReleaseNotes {
        let notes = try JSONDecoder().decode(Self.self, from: data)
        try notes.validate(version: version, build: build)
        return notes
    }

    private func validate(version: String, build: String) throws {
        let notes = self
        let validText: (String) -> Bool = { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        guard notes.schemaVersion == 1, notes.version == version, notes.build == build,
              version.range(of: #"^\d+\.\d+\.\d+$"#, options: .regularExpression) != nil,
              build.range(of: #"^[1-9]\d*$"#, options: .regularExpression) != nil, Int(build) != nil,
              let date = formatter.date(from: notes.date), formatter.string(from: date) == notes.date,
              notes.localizations["en"] != nil, !notes.localizations.isEmpty,
              notes.localizations.values.allSatisfy({ content in
                  validText(content.summary) && !content.visibleSections.isEmpty &&
                  Set(content.sections.map(\.id)).count == content.sections.count &&
                  content.sections.allSatisfy { section in
                      section.items.allSatisfy { validText($0.title) && ($0.detail.map(validText) ?? true) }
                  }
              }) else { throw CocoaError(.coderReadCorrupt) }
    }

    /// Immutable history is optional at runtime; reject gaps/duplicates/future entries as a unit.
    static func decodeHistory(_ data: Data, current: ReleaseNotes) throws -> [ReleaseNotes] {
        let history = try JSONDecoder().decode([ReleaseNotes].self, from: data)
        var expected = Int(current.build)! - 1
        for note in history {
            try note.validate(version: note.version, build: note.build)
            guard Int(note.build) == expected else { throw CocoaError(.coderReadCorrupt) }
            expected -= 1
        }
        return history
    }
}

@MainActor
final class ReleaseNotesStore: ObservableObject {
    let notes: ReleaseNotes?
    let version: String
    let build: String
    let releases: [ReleaseNotes]
    let previousVersion: String?
    let limitedHistorySince: String?
    @Published private(set) var hasUnreadChanges: Bool
    private let defaults: UserDefaults
    private let identity: String
    private static let observedKey = "carrottype.releaseNotes.observedVersion"
    private static let baselineKey = "carrottype.releaseNotes.upgradeBaseline"
    private static let readKey = "carrottype.releaseNotes.readVersion"

    init(bundle: Bundle = .main, defaults: UserDefaults = .standard) {
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
        let data = bundle.url(forResource: "ReleaseNotes", withExtension: "json").flatMap { try? Data(contentsOf: $0) }
        self.version = version
        self.build = build
        let notes = data.flatMap { try? ReleaseNotes.decode($0, version: version, build: build) }
        self.notes = notes
        self.defaults = defaults
        self.identity = "\(version) (\(build))"
        let previous = defaults.string(forKey: Self.observedKey)
        // Establish a quiet baseline on the first run of tracking. Only an observed
        // change is called Updated; do not infer an upgrade from onboarding progress.
        if previous == nil {
            defaults.set(identity, forKey: Self.readKey)
            defaults.removeObject(forKey: Self.baselineKey)
        } else if previous != identity {
            defaults.set(previous, forKey: Self.baselineKey)
        }
        let baseline = defaults.string(forKey: Self.baselineKey)
        let parts = baseline?.components(separatedBy: " (") ?? []
        let priorBuild = parts.count == 2 && parts[1].hasSuffix(")") ? Int(parts[1].dropLast()) : nil
        let validBaseline = baseline?.range(of: #"^\d+\.\d+\.\d+ \([1-9]\d*\)$"#, options: .regularExpression) != nil
        let historyData = bundle.url(forResource: "ReleaseNotesHistory", withExtension: "json").flatMap { try? Data(contentsOf: $0) }
        let history = notes.flatMap { current in historyData.flatMap { try? ReleaseNotes.decodeHistory($0, current: current) } } ?? []
        if let notes, validBaseline, let priorBuild, let currentBuild = Int(build), priorBuild < currentBuild {
            self.releases = ([notes] + history).filter { Int($0.build)! > priorBuild }
            self.previousVersion = parts[0]
            let oldest = history.last ?? notes
            self.limitedHistorySince = priorBuild < Int(oldest.build)! - 1 ? oldest.version : nil
        } else {
            self.releases = notes.map { [$0] } ?? []
            self.previousVersion = nil
            self.limitedHistorySince = nil
        }
        defaults.set(identity, forKey: Self.observedKey)
        self.hasUnreadChanges = previous != nil && defaults.string(forKey: Self.readKey) != identity
    }

    func markRead() {
        defaults.set(identity, forKey: Self.readKey)
        hasUnreadChanges = false
    }
}
