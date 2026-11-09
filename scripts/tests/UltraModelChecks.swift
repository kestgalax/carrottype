import Foundation

@main
struct UltraModelChecks {
    static func expect(_ value: @autoclosure () -> Bool, _ message: String) {
        guard value() else { fatalError(message) }
    }

    static func main() throws {
        let catalog = try JSONDecoder().decode(ModelCatalogFile.self, from: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1])))
        for source in [catalog, BundledModelCatalog.fallback] {
            let stt = source.packages.filter { $0.role == .stt }
            expect(stt.count == 1 && stt[0].id == "stt.parakeet-ultra", "only Ultra offered, including fallback")
            expect(stt[0].recommended && stt[0].supportsStreaming && stt[0].downloadable, "Ultra ready for download/live draft")
            expect(Set(source.packages.filter { $0.role == .cleanup }.map(\.id)) == Set(["cleanup.qwen3-0.6b-4bit", "cleanup.qwen3-1.7b-4bit", "cleanup.gemma4-e2b-4bit"]), "all cleanup choices preserved")
        }
        let suite = "carrottype-migration-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set("gemma", forKey: "carrottype.cleanupMode")
        for saved in [nil, "stt.whisper-base-ggml", "stt.parakeet-tdt-0.6b-v3", "stt.apple-speechanalyzer", "unknown", "stt.parakeet-ultra"] as [String?] {
            defaults.set(saved, forKey: DictationModelPolicy.selectionKey)
            expect(DictationModelPolicy.restoreSelection(defaults: defaults) == "stt.parakeet-ultra", "migrate saved preference")
            expect(DictationModelPolicy.restoreSelection(defaults: defaults) == "stt.parakeet-ultra", "migration idempotent")
            expect(defaults.string(forKey: "carrottype.cleanupMode") == "gemma", "preserve cleanup setting")
        }
        print("PASS catalog/default migration: Ultra only, live draft, all cleanup choices, isolated preferences")

        let temporary = FileManager.default.temporaryDirectory.appendingPathComponent("carrottype-legacy-tests-\(UUID().uuidString)")
        let root = temporary.appendingPathComponent("models")
        let outside = temporary.appendingPathComponent("outside")
        defer { try? FileManager.default.removeItem(at: temporary) }
        try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: true)
        let sentinel = outside.appendingPathComponent("keep.txt")
        try Data("keep".utf8).write(to: sentinel)
        let keep = ["parakeet-ultra", "stt.parakeet-ultra", "cleanup.gemma4-e2b-4bit", "stt.gigaam-experiment"]
        let oldPaths = LegacySTTStorage.knownPackages.flatMap(\.directories)
        for path in oldPaths + keep {
            let directory = root.appendingPathComponent(path)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try Data(repeating: 7, count: 64).write(to: directory.appendingPathComponent("fixture"))
        }
        let original = Set(try FileManager.default.contentsOfDirectory(atPath: root.path))
        let inventory = LegacySTTStorage.inventory(modelsRoot: root)
        expect(inventory.count == 5, "retired groups visible")
        expect(inventory.first { $0.id == "stt.parakeet-tdt-0.6b-v3" }?.bytes == 192, "v3 marker/cache/legacy sibling counted")
        let afterInventory = Set(try FileManager.default.contentsOfDirectory(atPath: root.path))
        expect(afterInventory == original, "inventory does not mutate files")
        try LegacySTTStorage.remove(id: "stt.parakeet-tdt-0.6b-v3", modelsRoot: root)
        expect(!LegacySTTStorage.inventory(modelsRoot: root).contains { $0.id == "stt.parakeet-tdt-0.6b-v3" }, "delete all v3 directories")
        for path in keep { expect(FileManager.default.fileExists(atPath: root.appendingPathComponent(path).path), "preserve active/cleanup/unknown files") }
        do {
            try LegacySTTStorage.remove(id: "../outside", modelsRoot: root)
            fatalError("reject unknown id")
        } catch LegacySTTStorage.StorageError.rejectedPath {}

        let v3Marker = root.appendingPathComponent("stt.parakeet-tdt-0.6b-v3")
        try FileManager.default.createDirectory(at: v3Marker, withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(at: root.appendingPathComponent("parakeet-tdt-0.6b-v3"), withDestinationURL: outside)
        do {
            try LegacySTTStorage.remove(id: "stt.parakeet-tdt-0.6b-v3", modelsRoot: root)
            fatalError("reject escaped symlink")
        } catch LegacySTTStorage.StorageError.rejectedPath {}
        expect(FileManager.default.fileExists(atPath: v3Marker.path), "validate group before deleting anything")
        expect(FileManager.default.fileExists(atPath: sentinel.path), "outside target preserved")
        // Nested symlinks must neither be counted nor followed during removal.
        let whisper = root.appendingPathComponent("stt.whisper-base-ggml")
        try FileManager.default.createSymbolicLink(at: whisper.appendingPathComponent("external"), withDestinationURL: outside)
        expect(LegacySTTStorage.inventory(modelsRoot: root).first { $0.id == "stt.whisper-base-ggml" }?.bytes == 64, "do not count nested symlink target")
        try LegacySTTStorage.remove(id: "stt.whisper-base-ggml", modelsRoot: root)
        try LegacySTTStorage.remove(id: "stt.apple-speechanalyzer", modelsRoot: root)
        expect(FileManager.default.fileExists(atPath: sentinel.path), "deletion does not follow symlinks or touch system assets")
        print("PASS legacy inventory/removal: all layouts, optional deletion, unknown/active preservation, path/symlink jail")
    }
}
