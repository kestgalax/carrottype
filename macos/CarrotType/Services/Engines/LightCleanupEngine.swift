import Foundation

actor LightCleanupEngine: CleanupEngine {
    func cleanup(text: String, mode: CleanupMode, modelDirectory: URL?) async throws -> String {
        TextCleanup.apply(text, mode: mode == .off ? .off : .light)
    }

    func unload() async {}
}
