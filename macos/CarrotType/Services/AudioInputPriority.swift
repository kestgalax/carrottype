import Foundation

/// Ordered microphone preference for smart failover.
///
/// The active input is the first UID in this list that is currently connected. UIDs stay in the
/// list while their device is unavailable so reconnecting restores the preferred microphone.
/// Nothing is pruned automatically: the system default and the first discovered device are only
/// fallbacks. The service seeds an empty list once with the resolved default; it never appends
/// later fallbacks.
struct AudioInputPriorityList: Equatable {
    /// Ordered preferred device UIDs (`carrottype.audioInputPriorityUIDs`).
    static let defaultsKey = "carrottype.audioInputPriorityUIDs"
    /// Pre-priority single-device selection (`carrottype.selectedAudioInputID`); migrated once.
    static let legacySelectedKey = "carrottype.selectedAudioInputID"

    private(set) var uids: [String]

    init(_ uids: [String] = []) {
        self.uids = Self.normalized(uids)
    }

    /// Trims whitespace, drops empty values and removes duplicates; the first occurrence wins.
    static func normalized(_ uids: [String]) -> [String] {
        var seen = Set<String>()
        return uids.compactMap { raw in
            let uid = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !uid.isEmpty, seen.insert(uid).inserted else { return nil }
            return uid
        }
    }

    // MARK: - Persistence

    static func load(defaults: UserDefaults) -> AudioInputPriorityList {
        // An explicitly stored empty array means “no preference”. Only an absent or non-array
        // value falls back to the legacy single selection, which is then migrated once.
        if let stored = defaults.stringArray(forKey: defaultsKey) {
            return AudioInputPriorityList(stored)
        }
        return AudioInputPriorityList(migratedUIDs(defaults: defaults))
    }

    /// Existing single selection becomes the initial priority exactly once.
    static func migratedUIDs(defaults: UserDefaults) -> [String] {
        guard let selected = defaults.string(forKey: legacySelectedKey) else { return [] }
        return normalized([selected])
    }

    func save(defaults: UserDefaults) {
        defaults.set(uids, forKey: Self.defaultsKey)
    }

    // MARK: - Queries

    func contains(_ uid: String) -> Bool {
        uids.contains(uid)
    }

    /// First preferred UID that is connected right now.
    func preferredAvailableUID(in available: Set<String>) -> String? {
        uids.first { available.contains($0) }
    }

    /// Resolved active input: preferred → macOS default → first discovered → none.
    func resolveActiveUID(discoveredUIDs: [String], systemDefaultUID: String?) -> String? {
        let available = Set(discoveredUIDs)
        if let preferred = preferredAvailableUID(in: available) { return preferred }
        if let systemDefaultUID, available.contains(systemDefaultUID) { return systemDefaultUID }
        return discoveredUIDs.first
    }

    // MARK: - Mutation

    /// Menu quick-select: existing or new UID moves to the front without disturbing the rest.
    mutating func promote(_ uid: String) {
        let trimmed = uid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        uids.removeAll { $0 == trimmed }
        uids.insert(trimmed, at: 0)
    }

    /// Swaps one entry with its neighbor in a displayed order (which may include connected devices
    /// that are not preferred yet). Returns the new order, or nil for unknown UIDs/out-of-range moves.
    static func moving(_ uid: String, byOffset offset: Int, in order: [String]) -> [String]? {
        guard let index = order.firstIndex(of: uid) else { return nil }
        let target = index + offset
        guard offset != 0, order.indices.contains(target) else { return nil }
        var moved = order
        moved.swapAt(index, target)
        return moved
    }

    /// Replaces the stored order (Setup reorder) after normalization.
    mutating func reorder(_ uids: [String]) {
        self.uids = Self.normalized(uids)
    }
}
