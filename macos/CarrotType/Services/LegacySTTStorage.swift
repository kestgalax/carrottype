import Foundation

struct LegacySTTPackage: Identifiable, Equatable {
    let id: String
    let name: String
    let directories: [String]
    var bytes: Int64 = 0
}

/// Retired packages remain visible without keeping their engines or offering new downloads.
enum LegacySTTStorage {
    enum StorageError: LocalizedError {
        case rejectedPath
        var errorDescription: String? { L10n.t("storage.legacy_path_rejected") }
    }

    static let knownPackages: [LegacySTTPackage] = [
        .init(id: "stt.whisper-base-ggml", name: "Whisper Base", directories: ["stt.whisper-base-ggml"]),
        .init(id: "stt.whisper-small-ggml", name: "Whisper Small", directories: ["stt.whisper-small-ggml"]),
        .init(id: "stt.whisper-large-v3-turbo-q5", name: "Whisper Turbo q5", directories: ["stt.whisper-large-v3-turbo-q5"]),
        .init(id: "stt.parakeet-tdt-0.6b-v3", name: "Parakeet TDT 0.6B v3",
              directories: ["stt.parakeet-tdt-0.6b-v3", "parakeet-tdt-0.6b-v3", "parakeet-tdt-0.6b-v3-coreml"]),
        // Only CarrotType's preparation marker. System-wide Apple assets are never removed here.
        .init(id: "stt.apple-speechanalyzer", name: "Apple SpeechAnalyzer", directories: ["stt.apple-speechanalyzer"]),
    ]

    static func inventory(modelsRoot: URL, fileManager: FileManager = .default) -> [LegacySTTPackage] {
        knownPackages.compactMap { package in
            let existing = package.directories.map { modelsRoot.appendingPathComponent($0) }
                .filter { fileManager.fileExists(atPath: $0.path) }
            guard !existing.isEmpty else { return nil }
            var result = package
            result.bytes = existing.reduce(0) { sum, url in
                guard allowed(url, under: modelsRoot) else { return sum }
                return sum + size(of: url, fileManager: fileManager)
            }
            return result
        }
    }

    static func remove(id: String, modelsRoot: URL, fileManager: FileManager = .default) throws {
        guard let package = knownPackages.first(where: { $0.id == id }) else { throw StorageError.rejectedPath }
        let paths = package.directories.map { modelsRoot.appendingPathComponent($0) }
        // Validate every path before the first deletion to avoid partially deleting a rejected group.
        guard paths.allSatisfy({ allowed($0, under: modelsRoot) }) else { throw StorageError.rejectedPath }
        for path in paths where fileManager.fileExists(atPath: path.path) {
            try fileManager.removeItem(at: path)
        }
    }

    private static func allowed(_ url: URL, under root: URL) -> Bool {
        let rootPath = root.resolvingSymlinksInPath().standardizedFileURL.path
        let path = url.resolvingSymlinksInPath().standardizedFileURL.path
        return path.hasPrefix(rootPath + "/")
    }

    private static func size(of url: URL, fileManager: FileManager) -> Int64 {
        guard let files = fileManager.enumerator(at: url, includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey]) else { return 0 }
        return files.reduce(Int64(0)) { sum, element in
            guard let file = element as? URL,
                  let values = try? file.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey]),
                  values.isRegularFile == true, values.isSymbolicLink != true else { return sum }
            return sum + Int64(values.fileSize ?? 0)
        }
    }
}
