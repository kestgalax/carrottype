import Foundation

/// Daily character + recording-duration buckets on disk (ADR-013). No transcripts.
@MainActor
final class UsageStatsStore: ObservableObject {
    struct TransformCount: Codable, Equatable, Sendable {
        var kind: TransformKind
        var count: Int
    }

    struct TransformMonthTotal: Equatable, Identifiable, Sendable {
        var id: UUID
        var kind: TransformKind
        var count: Int
    }

    struct DayBucket: Codable, Equatable, Sendable {
        var characters: Int
        var recordingMilliseconds: Int
        var sessions: Int
        var transforms: [UUID: TransformCount]

        init(
            characters: Int = 0,
            recordingMilliseconds: Int = 0,
            sessions: Int = 0,
            transforms: [UUID: TransformCount] = [:]
        ) {
            self.characters = characters
            self.recordingMilliseconds = recordingMilliseconds
            self.sessions = sessions
            self.transforms = transforms
        }

        enum CodingKeys: String, CodingKey {
            case characters
            case recordingMilliseconds
            case sessions
            case transforms
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            characters = try container.decode(Int.self, forKey: .characters)
            recordingMilliseconds = try container.decode(Int.self, forKey: .recordingMilliseconds)
            sessions = try container.decodeIfPresent(Int.self, forKey: .sessions) ?? 0
            let keyed = try container.decodeIfPresent([String: TransformCount].self, forKey: .transforms) ?? [:]
            transforms = Dictionary(uniqueKeysWithValues: keyed.compactMap { key, value in
                UUID(uuidString: key).map { ($0, value) }
            })
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(characters, forKey: .characters)
            try container.encode(recordingMilliseconds, forKey: .recordingMilliseconds)
            try container.encode(sessions, forKey: .sessions)
            let keyed = Dictionary(uniqueKeysWithValues: transforms.map { ($0.key.uuidString, $0.value) })
            try container.encode(keyed, forKey: .transforms)
        }

        var hasContent: Bool {
            characters > 0 || recordingMilliseconds > 0 || sessions > 0 || transforms.contains { $0.value.count > 0 }
        }
    }

    struct MonthTotals: Equatable, Sendable {
        var characters: Int
        var recordingMilliseconds: Int
        var sessions: Int

        var isEmpty: Bool { characters == 0 && recordingMilliseconds == 0 && sessions == 0 }
    }

    @Published private(set) var days: [String: DayBucket] = [:]

    private let fileManager: FileManager
    private let fileURL: URL
    private let calendar: Calendar
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        fileManager: FileManager = .default,
        fileURL: URL? = nil,
        calendar: Calendar = .current
    ) {
        self.fileManager = fileManager
        self.calendar = calendar
        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = [.sortedKeys]
        self.decoder = JSONDecoder()

        if let fileURL {
            self.fileURL = fileURL
        } else {
            let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? URL(fileURLWithPath: NSTemporaryDirectory())
            let folder = support
                .appendingPathComponent("carrottype", isDirectory: true)
                .appendingPathComponent("stats", isDirectory: true)
            try? fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
            self.fileURL = folder.appendingPathComponent("daily.json", isDirectory: false)
        }

        days = Self.load(from: self.fileURL, decoder: decoder) ?? [:]
    }

    var hasAnyData: Bool { days.values.contains(where: \.hasContent) }

    func record(characters: Int, recordingMilliseconds: Int, at date: Date = Date()) {
        let chars = max(0, characters)
        let millis = max(0, recordingMilliseconds)
        guard chars > 0 else { return }

        let key = Self.dayKey(for: date, calendar: calendar)
        var next = days
        var bucket = next[key] ?? DayBucket()
        bucket.characters += chars
        bucket.recordingMilliseconds += millis
        bucket.sessions += 1
        next[key] = bucket
        days = next
        persist()
    }

    func recordTransform(bindingID: UUID, kind: TransformKind, at date: Date = Date()) {
        let key = Self.dayKey(for: date, calendar: calendar)
        var next = days
        var bucket = next[key] ?? DayBucket()
        var entry = bucket.transforms[bindingID] ?? TransformCount(kind: kind, count: 0)
        entry.kind = kind
        entry.count += 1
        bucket.transforms[bindingID] = entry
        next[key] = bucket
        days = next
        persist()
    }

    func totals(forMonthContaining date: Date) -> MonthTotals {
        let prefix = Self.monthPrefix(for: date, calendar: calendar)
        var characters = 0
        var recordingMilliseconds = 0
        var sessions = 0
        for (key, bucket) in days where key.hasPrefix(prefix) {
            characters += bucket.characters
            recordingMilliseconds += bucket.recordingMilliseconds
            sessions += bucket.sessions
        }
        return MonthTotals(
            characters: characters,
            recordingMilliseconds: recordingMilliseconds,
            sessions: sessions
        )
    }

    func transformTotals(forMonthContaining date: Date) -> [TransformMonthTotal] {
        let prefix = Self.monthPrefix(for: date, calendar: calendar)
        var merged: [UUID: TransformCount] = [:]
        for key in days.keys.sorted() where key.hasPrefix(prefix) {
            guard let bucket = days[key] else { continue }
            for (id, entry) in bucket.transforms where entry.count > 0 {
                var current = merged[id] ?? TransformCount(kind: entry.kind, count: 0)
                current.count += entry.count
                current.kind = entry.kind
                merged[id] = current
            }
        }
        return merged
            .map { TransformMonthTotal(id: $0.key, kind: $0.value.kind, count: $0.value.count) }
            .sorted { lhs, rhs in
                if lhs.count != rhs.count { return lhs.count > rhs.count }
                return lhs.id.uuidString < rhs.id.uuidString
            }
    }

    /// First-of-month dates that have at least one stored day, plus the current month.
    func selectableMonthStarts(now: Date = Date()) -> [Date] {
        var starts = Set<Date>()
        if let current = Self.startOfMonth(for: now, calendar: calendar) {
            starts.insert(current)
        }
        for key in days.keys {
            if let start = Self.startOfMonth(fromDayKey: key, calendar: calendar) {
                starts.insert(start)
            }
        }
        return starts.sorted()
    }

    func clear() {
        days = [:]
        persist()
        if fileManager.fileExists(atPath: fileURL.path) {
            try? fileManager.removeItem(at: fileURL)
        }
    }

    // MARK: - Persistence

    private struct FilePayload: Codable {
        var days: [String: DayBucket]
    }

    private func persist() {
        do {
            let directory = fileURL.deletingLastPathComponent()
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            if days.isEmpty || days.values.allSatisfy({ !$0.hasContent }) {
                days = [:]
                if fileManager.fileExists(atPath: fileURL.path) {
                    try fileManager.removeItem(at: fileURL)
                }
                return
            }
            let data = try encoder.encode(FilePayload(days: days))
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // Stats must never fail the dictation loop.
        }
    }

    private static func load(from url: URL, decoder: JSONDecoder) -> [String: DayBucket]? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return (try? decoder.decode(FilePayload.self, from: data))?.days
    }

    // MARK: - Calendar keys

    static func dayKey(for date: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        let year = parts.year ?? 0
        let month = parts.month ?? 0
        let day = parts.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    static func monthPrefix(for date: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month], from: date)
        let year = parts.year ?? 0
        let month = parts.month ?? 0
        return String(format: "%04d-%02d", year, month)
    }

    static func startOfMonth(for date: Date, calendar: Calendar) -> Date? {
        let parts = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: DateComponents(year: parts.year, month: parts.month, day: 1))
    }

    static func startOfMonth(fromDayKey key: String, calendar: Calendar) -> Date? {
        let parts = key.split(separator: "-")
        guard parts.count >= 2,
              let year = Int(parts[0]),
              let month = Int(parts[1])
        else { return nil }
        return calendar.date(from: DateComponents(year: year, month: month, day: 1))
    }
}
