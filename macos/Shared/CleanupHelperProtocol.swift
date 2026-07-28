import Foundation

/// Versioned stdin/stdout JSON contract between CarrotType and CarrotTypeCleanupHelper (ADR-009).
enum CleanupHelperProtocol {
    static let version = 1
}

struct CleanupHelperRequest: Codable, Sendable {
    var v: Int
    var text: String
    /// `smart`, `smartPlus`, or `gemma` (matches `CleanupMode.rawValue`).
    var mode: String
    var modelDirectory: String

    init(text: String, mode: String, modelDirectory: String, v: Int = CleanupHelperProtocol.version) {
        self.v = v
        self.text = text
        self.mode = mode
        self.modelDirectory = modelDirectory
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
