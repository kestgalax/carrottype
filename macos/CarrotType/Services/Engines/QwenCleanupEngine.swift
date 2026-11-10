import Foundation

enum CleanupEngineError: LocalizedError {
    case modelMissing
    case generationFailed
    case notAppleSilicon
    case helperMissing

    var errorDescription: String? {
        switch self {
        case .modelMissing: return L10n.t("error.cleanup_model_missing")
        case .generationFailed: return L10n.t("error.cleanup_failed")
        case .notAppleSilicon: return L10n.t("error.cleanup_not_silicon")
        case .helperMissing: return L10n.t("error.cleanup_failed")
        }
    }
}

/// Spawns `CarrotTypeCleanupHelper` for Smart/Smart+/Gemma (ADR-009 / ADR-010). No in-process MLX.
actor QwenCleanupEngine: CleanupEngine {
    /// Wall-clock budget for cold load + generate (helper is killed on timeout).
    private static let timeoutNanoseconds: UInt64 = 120_000_000_000

    func formatDictation(text: String, mode: CleanupMode, modelDirectory: URL?, rules: DictationRules) async throws -> String {
        try await run(text: text, mode: mode, modelDirectory: modelDirectory, instructions: nil, rules: rules.normalized)
    }

    func cleanup(text: String, mode: CleanupMode, modelDirectory: URL?, instructions: String?) async throws -> String {
        try await run(text: text, mode: mode, modelDirectory: modelDirectory, instructions: instructions, rules: nil)
    }

    private func run(
        text: String,
        mode: CleanupMode,
        modelDirectory: URL?,
        instructions: String?,
        rules: DictationRules?
    ) async throws -> String {
        switch mode {
        case .off:
            return text
        case .light:
            return TextCleanup.apply(text, mode: .light)
        case .smart, .smartPlus, .gemma:
            break
        }

        #if arch(arm64)
        guard let modelDirectory else { throw CleanupEngineError.modelMissing }
        guard QwenCleanupPackage.isPackageReady(at: modelDirectory) else {
            throw CleanupEngineError.modelMissing
        }
        guard let helperURL = Self.helperExecutableURL() else {
            throw CleanupEngineError.helperMissing
        }

        let request = CleanupHelperRequest(
            text: text,
            mode: mode.rawValue,
            modelDirectory: modelDirectory.path,
            instructions: instructions,
            purpose: instructions?.isEmpty == false ? "transform" : "dictation", dictationRules: rules
        )
        let requestData = try JSONEncoder().encode(request)
        let data: Data
        do {
            data = try await CleanupHelperTransport.run(
                executable: helperURL,
                request: requestData,
                timeout: Double(Self.timeoutNanoseconds) / 1_000_000_000
            )
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw CleanupEngineError.generationFailed
        }
        guard let response = try? CleanupHelperResponse.decode(data) else {
            throw CleanupEngineError.generationFailed
        }
        if response.ok, let cleaned = response.text, !cleaned.isEmpty {
            return cleaned
        }
        switch response.error {
        case "modelMissing": throw CleanupEngineError.modelMissing
        case "notAppleSilicon": throw CleanupEngineError.notAppleSilicon
        default: throw CleanupEngineError.generationFailed
        }
        #else
        throw CleanupEngineError.notAppleSilicon
        #endif
    }

    func unload() async {
        // Helper exits after each request; nothing resident in the host.
    }

    private static func helperExecutableURL() -> URL? {
        if let url = Bundle.main.url(forAuxiliaryExecutable: "CarrotTypeCleanupHelper") {
            return url
        }
        guard let exec = Bundle.main.executableURL else { return nil }
        let sibling = exec.deletingLastPathComponent()
            .appendingPathComponent("CarrotTypeCleanupHelper", isDirectory: false)
        return FileManager.default.isExecutableFile(atPath: sibling.path) ? sibling : nil
    }

}
