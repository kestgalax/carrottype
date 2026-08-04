import Foundation

actor LightCleanupEngine: CleanupEngine {
    func cleanup(
        text: String,
        mode: CleanupMode,
        modelDirectory: URL?,
        instructions: String?
    ) async throws -> String {
        _ = instructions
        return TextCleanup.apply(text, mode: mode == .off ? .off : .light)
    }

    func unload() async {}
}
