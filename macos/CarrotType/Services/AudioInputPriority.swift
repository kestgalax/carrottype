import Foundation

/// Capture usability beyond “shows up in the device list”.
///
/// Elgato Wave Link keeps virtual mix devices (Voice / Stream / Main / …) present and `alive`
/// even when the physical Wave mic is unplugged. Counting those as connected would pin failover
/// on a silent virtual path. Virtual Wave Link targets are usable only while real Wave hardware
/// is also present in Core Audio.
enum AudioInputTransport: Equatable {
    case builtIn
    case usb
    case bluetooth
    case virtual
    case aggregate
    case other
}

enum AudioInputUsability {
    /// Wave Link software mix / FX / stream endpoints (not the USB Wave:3 itself).
    static func looksLikeWaveLinkVirtual(name: String, transport: AudioInputTransport) -> Bool {
        guard transport == .virtual else { return false }
        let n = name.lowercased()
        return n.contains("wave link") || n.contains("wavelink")
    }

    /// Physical Elgato Wave hardware (Wave:1 / Wave:3 / …), never a Wave Link virtual mix.
    static func looksLikePhysicalWaveHardware(
        name: String,
        manufacturer: String,
        transport: AudioInputTransport
    ) -> Bool {
        switch transport {
        case .virtual, .aggregate:
            return false
        case .builtIn, .usb, .bluetooth, .other:
            break
        }
        let n = name.lowercased()
        let m = manufacturer.lowercased()
        if n.range(of: #"wave:\d"#, options: .regularExpression) != nil { return true }
        let elgatoFamily = m.contains("elgato") || m.contains("corsair")
        return elgatoFamily && n.contains("wave") && !n.contains("wave link") && !n.contains("wavelink")
    }

    /// Present inputs are usable unless they are orphan Wave Link virtual mixes.
    static func isUsable(
        name: String,
        manufacturer: String,
        transport: AudioInputTransport,
        physicalWaveHardwarePresent: Bool
    ) -> Bool {
        if looksLikeWaveLinkVirtual(name: name, transport: transport) {
            return physicalWaveHardwarePresent
        }
        return true
    }

    static func physicalWaveHardwarePresent(
        in devices: [(name: String, manufacturer: String, transport: AudioInputTransport)]
    ) -> Bool {
        devices.contains {
            looksLikePhysicalWaveHardware(name: $0.name, manufacturer: $0.manufacturer, transport: $0.transport)
        }
    }

    /// Continuity / iPhone-as-mic style inputs — often present but poor first-run defaults.
    static func looksLikeContinuityOrRemoteMic(name: String, transport: AudioInputTransport) -> Bool {
        let n = name.lowercased()
        if n.contains("iphone") || n.contains("ipad") || n.contains("continuity") { return true }
        // Continuity Capture often reports a non-standard transport (not built-in/USB/BT/virtual).
        if transport == .other, n.contains("microphone"), !n.contains("macbook"), !n.contains("imac") {
            return true
        }
        return false
    }

    /// Higher is better for the one-time empty-priority seed (first launch / no preference yet).
    /// Prefer built-in over USB/BT; deprioritize Continuity and virtual mixes so a silent Wave Link
    /// default does not own the first dictation.
    static func firstSeedScore(name: String, transport: AudioInputTransport) -> Int {
        if looksLikeContinuityOrRemoteMic(name: name, transport: transport) { return 20 }
        switch transport {
        case .builtIn: return 100
        case .usb: return 80
        case .bluetooth: return 45
        case .other: return 35
        case .virtual: return 15
        case .aggregate: return 10
        }
    }

    /// Best UID for seeding an empty priority list. `candidates` must already be usable.
    static func preferredFirstSeedUID(
        in candidates: [(uid: String, name: String, transport: AudioInputTransport)]
    ) -> String? {
        candidates.max { lhs, rhs in
            let left = firstSeedScore(name: lhs.name, transport: lhs.transport)
            let right = firstSeedScore(name: rhs.name, transport: rhs.transport)
            if left != right { return left < right }
            return lhs.uid > rhs.uid
        }?.uid
    }
}

/// Ordered microphone preference for smart failover.
///
/// The active input is the first UID in this list that is currently **usable**. UIDs stay in the
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
