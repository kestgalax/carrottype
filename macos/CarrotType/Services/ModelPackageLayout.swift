import Foundation

/// Shared catalog helpers for package layout under Application Support.
enum ModelPackageLayout {
    static func directory(modelsRoot: URL, packageID: String) -> URL {
        modelsRoot.appendingPathComponent(packageID, isDirectory: true)
    }

    static func readyMarker(in directory: URL) -> URL {
        directory.appendingPathComponent(".ready", isDirectory: false)
    }
}
