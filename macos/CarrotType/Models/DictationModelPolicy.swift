import Foundation

enum DictationModelPolicy {
    static let selectionKey = "carrottype.selectedSTT"

    /// Migrate only the preference. Installed weights and all other settings remain untouched.
    static func restoreSelection(defaults: UserDefaults = .standard) -> String {
        let id = BundledModelCatalog.recommendedSTTID
        if defaults.string(forKey: selectionKey) != id { defaults.set(id, forKey: selectionKey) }
        return id
    }
}
