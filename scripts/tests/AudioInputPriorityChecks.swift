import Foundation

private var failures = 0

private func check(_ condition: Bool, _ message: String) {
    if condition { return }
    failures += 1
    print("FAIL \(message)")
}

private func expect(_ actual: String?, _ expected: String?, _ message: String) {
    check(actual == expected, "\(message): expected \(expected ?? "nil"), got \(actual ?? "nil")")
}

private func makeDefaults() -> UserDefaults {
    let suite = "carrottype.smart-mic-priority.checks.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defaults.removePersistentDomain(forName: suite)
    return defaults
}

@main struct AudioInputPriorityChecks {
    static func main() {
        normalization()
        migration()
        resolution()
        retention()
        promotion()
        moving()
        persistence()
        guard failures == 0 else {
            print("FAILED \(failures) smart-mic-priority check(s)")
            exit(1)
        }
        print("PASS smart mic priority: normalization, migration, ordered failover, retention, promote, bounded move, defaults round-trip")
    }

    private static func normalization() {
        check(AudioInputPriorityList([" b ", "a", "a", "", "   ", "c"]).uids == ["b", "a", "c"],
              "trims, drops empties and removes duplicates while preserving order")
        check(AudioInputPriorityList().uids.isEmpty, "empty list stays empty")
        check(AudioInputPriorityList(["\n\t"]).uids.isEmpty, "whitespace-only UIDs are dropped")
    }

    private static func migration() {
        let legacy = makeDefaults()
        legacy.set("usb-wave", forKey: AudioInputPriorityList.legacySelectedKey)
        let migrated = AudioInputPriorityList.load(defaults: legacy)
        check(migrated.uids == ["usb-wave"], "legacy single selection becomes a one-entry priority list")
        migrated.save(defaults: legacy)

        legacy.set("usb-other", forKey: AudioInputPriorityList.legacySelectedKey)
        check(AudioInputPriorityList.load(defaults: legacy).uids == ["usb-wave"],
              "a saved priority list wins over the legacy key")

        let existing = makeDefaults()
        existing.set(["a", "b"], forKey: AudioInputPriorityList.defaultsKey)
        existing.set("legacy", forKey: AudioInputPriorityList.legacySelectedKey)
        check(AudioInputPriorityList.load(defaults: existing).uids == ["a", "b"],
              "existing multi-entry list is not replaced by the legacy value")

        let explicitEmpty = makeDefaults()
        explicitEmpty.set([String](), forKey: AudioInputPriorityList.defaultsKey)
        explicitEmpty.set("legacy", forKey: AudioInputPriorityList.legacySelectedKey)
        check(AudioInputPriorityList.load(defaults: explicitEmpty).uids.isEmpty,
              "an explicitly empty list is not re-migrated")

        let emptyLegacy = makeDefaults()
        emptyLegacy.set("", forKey: AudioInputPriorityList.legacySelectedKey)
        check(AudioInputPriorityList.load(defaults: emptyLegacy).uids.isEmpty,
              "empty legacy selection migrates to no preference")

        let missing = makeDefaults()
        check(AudioInputPriorityList.load(defaults: missing).uids.isEmpty,
              "first launch without any saved value has no preference")

        let corrupt = makeDefaults()
        corrupt.set("not-an-array", forKey: AudioInputPriorityList.defaultsKey)
        corrupt.set("usb-legacy", forKey: AudioInputPriorityList.legacySelectedKey)
        check(AudioInputPriorityList.load(defaults: corrupt).uids == ["usb-legacy"],
              "a non-array stored value falls back to legacy migration")

        let duplicates = makeDefaults()
        duplicates.set(["a", " a ", "b", "a"], forKey: AudioInputPriorityList.defaultsKey)
        check(AudioInputPriorityList.load(defaults: duplicates).uids == ["a", "b"],
              "stored duplicates and whitespace normalize on load")
    }

    private static func resolution() {
        let list = AudioInputPriorityList(["usb", "builtin"])

        expect(list.resolveActiveUID(discoveredUIDs: ["builtin", "usb"], systemDefaultUID: "builtin"),
               "usb", "first preferred connected device wins over the system default")
        expect(list.resolveActiveUID(discoveredUIDs: ["builtin"], systemDefaultUID: "builtin"),
               "builtin", "skips a disconnected preference and uses the next preferred device")
        expect(list.resolveActiveUID(discoveredUIDs: ["other"], systemDefaultUID: "other"),
               "other", "falls back to the system default when no preference is connected")
        expect(list.resolveActiveUID(discoveredUIDs: ["first", "second"], systemDefaultUID: "missing"),
               "first", "falls back to discovery order when the system default is unavailable")
        expect(AudioInputPriorityList().resolveActiveUID(discoveredUIDs: ["first"], systemDefaultUID: "first"),
               "first", "an empty preference list resolves the system default")
        expect(list.resolveActiveUID(discoveredUIDs: [], systemDefaultUID: nil),
               nil, "no connected devices resolves to no microphone")
        expect(AudioInputPriorityList(["a"]).resolveActiveUID(discoveredUIDs: ["b"], systemDefaultUID: nil),
               "b", "a missing single preference falls back to the only connected device")
    }

    private static func retention() {
        let list = AudioInputPriorityList(["usb", "builtin"])
        // Resolution must never prune or extend: reconnecting the preferred mic restores it.
        _ = list.resolveActiveUID(discoveredUIDs: ["builtin"], systemDefaultUID: "builtin")
        check(list.uids == ["usb", "builtin"], "resolution does not remove disconnected UIDs")
        check(list.contains("usb"), "disconnected preferred UID is retained for reconnect")

        let empty = AudioInputPriorityList()
        _ = empty.resolveActiveUID(discoveredUIDs: ["builtin"], systemDefaultUID: "builtin")
        check(empty.uids.isEmpty, "pure resolution never mutates the list; seeding is the service's job")

        let fallback = AudioInputPriorityList(["unplugged"])
        _ = fallback.resolveActiveUID(discoveredUIDs: ["other"], systemDefaultUID: "other")
        check(fallback.uids == ["unplugged"], "a fallback device is not silently appended")

        var promoted = AudioInputPriorityList()
        promoted.promote("chosen")
        check(promoted.uids == ["chosen"], "explicit promotion is the only way a UID is added")
    }

    private static func promotion() {
        var list = AudioInputPriorityList(["a", "b", "c"])
        list.promote("c")
        check(list.uids == ["c", "a", "b"], "menu quick-select moves the chosen device to the front")
        list.promote("c")
        check(list.uids == ["c", "a", "b"], "promoting an already-first device is stable")
        list.promote("unplugged")
        check(list.uids == ["unplugged", "c", "a", "b"], "promoting an unreached UID inserts it once")
        list.promote("   ")
        check(list.uids == ["unplugged", "c", "a", "b"], "blank promotion is ignored")
    }

    private static func moving() {
        var list = AudioInputPriorityList(["a", "b", "c"])

        check(AudioInputPriorityList.moving("b", byOffset: -1, in: list.uids) == ["b", "a", "c"],
              "moving up swaps neighbors")
        check(AudioInputPriorityList.moving("c", byOffset: -1, in: list.uids) == ["a", "c", "b"],
              "moving the last entry up keeps other entries in order")
        check(AudioInputPriorityList.moving("a", byOffset: -1, in: list.uids) == nil,
              "moving the first entry up is rejected")
        check(AudioInputPriorityList.moving("a", byOffset: 1, in: list.uids) == ["b", "a", "c"],
              "moving the first entry down swaps neighbors")
        check(AudioInputPriorityList.moving("c", byOffset: 1, in: list.uids) == nil,
              "moving the last entry down is rejected")
        check(AudioInputPriorityList.moving("missing", byOffset: 1, in: list.uids) == nil,
              "unknown UID movement is rejected")
        check(AudioInputPriorityList.moving("b", byOffset: 0, in: list.uids) == nil,
              "zero offset is rejected")
        check(list.uids == ["a", "b", "c"], "rejected moves leave the order unchanged")

        // Setup moves the displayed order, which can include connected devices not preferred yet.
        let displayed = ["a", "extra", "b"]
        check(AudioInputPriorityList.moving("extra", byOffset: -1, in: displayed) == ["extra", "a", "b"],
              "moving an unlisted connected device up is supported")

        list.reorder([" b ", "c", "b"])
        check(list.uids == ["b", "c"], "reorder normalizes the persisted order")
    }

    private static func persistence() {
        let defaults = makeDefaults()
        var list = AudioInputPriorityList.load(defaults: defaults)
        check(list.uids.isEmpty, "empty defaults load as no preference")

        list.reorder(["usb", "builtin", "usb"])
        list.save(defaults: defaults)
        check(AudioInputPriorityList.load(defaults: defaults).uids == ["usb", "builtin"],
              "saved list round-trips normalized")

        // The resolved active UID keeps writing the legacy key for compatibility.
        defaults.set("builtin", forKey: AudioInputPriorityList.legacySelectedKey)
        check(AudioInputPriorityList.load(defaults: defaults).uids == ["usb", "builtin"],
              "writing the resolved value does not overwrite the priority list")
    }
}
