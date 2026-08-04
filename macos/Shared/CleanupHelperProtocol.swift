import Foundation

/// Versioned stdin/stdout JSON contract between CarrotType and CarrotTypeCleanupHelper (ADR-009 / ADR-012).
enum CleanupHelperProtocol {
    /// v2: optional `instructions` for selection transform (nil = literal dictation cleanup).
    static let version = 2
}

struct CleanupHelperRequest: Codable, Sendable {
    var v: Int
    var text: String
    /// `smart`, `smartPlus`, or `gemma` (matches `CleanupMode.rawValue`).
    var mode: String
    var modelDirectory: String
    /// When non-empty, used as ChatSession instructions instead of the built-in literal cleanup prompt.
    var instructions: String?

    init(
        text: String,
        mode: String,
        modelDirectory: String,
        instructions: String? = nil,
        v: Int = CleanupHelperProtocol.version
    ) {
        self.v = v
        self.text = text
        self.mode = mode
        self.modelDirectory = modelDirectory
        self.instructions = instructions
    }
}

struct CleanupHelperResponse: Codable, Sendable {
    var v: Int
    var ok: Bool
    var text: String?
    /// Stable machine codes: `modelMissing`, `generationFailed`, `notAppleSilicon`, `invalidRequest`.
    var error: String?

    static func success(_ text: String) -> CleanupHelperResponse {
        CleanupHelperResponse(v: CleanupHelperProtocol.version, ok: true, text: text, error: nil)
    }

    static func failure(_ code: String) -> CleanupHelperResponse {
        CleanupHelperResponse(v: CleanupHelperProtocol.version, ok: false, text: nil, error: code)
    }
}
