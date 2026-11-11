import Foundation

/// Versioned stdin/stdout JSON contract between CarrotType and CarrotTypeCleanupHelper (ADR-009 / ADR-012).
enum CleanupHelperProtocol {
    /// v3: explicit purpose and bounded dictation rules; transform instructions remain independent.
    static let version = 3
}

struct CleanupHelperRequest: Codable, Sendable {
    var v: Int
    var text: String
    /// `smart`, `smartPlus`, or `gemma` (matches `CleanupMode.rawValue`).
    var mode: String
    var modelDirectory: String
    /// When non-empty, used as ChatSession instructions instead of the built-in literal cleanup prompt.
    var instructions: String?
    var purpose: String?
    var dictationRules: DictationRules?

    init(
        text: String,
        mode: String,
        modelDirectory: String,
        instructions: String? = nil,
        v: Int = CleanupHelperProtocol.version,
        purpose: String? = nil,
        dictationRules: DictationRules? = nil
    ) {
        self.v = v
        self.text = text
        self.mode = mode
        self.modelDirectory = modelDirectory
        self.instructions = instructions
        self.purpose = purpose ?? (instructions?.isEmpty == false ? "transform" : "dictation")
        self.dictationRules = dictationRules
    }
}

struct CleanupHelperResponse: Codable, Sendable {
    var v: Int
    var ok: Bool
    var text: String?
    /// Stable machine codes: `modelMissing`, `modelPathRejected`, `generationFailed`, `notAppleSilicon`, `invalidRequest`.
    var error: String?

    enum DecodeError: Error { case incompatibleVersion }

    static func decode(_ data: Data) throws -> CleanupHelperResponse {
        let line = data.prefix { $0 != UInt8(ascii: "\n") }
        let response = try JSONDecoder().decode(Self.self, from: Data(line))
        guard response.v == CleanupHelperProtocol.version else { throw DecodeError.incompatibleVersion }
        return response
    }

    static func success(_ text: String) -> CleanupHelperResponse {
        CleanupHelperResponse(v: CleanupHelperProtocol.version, ok: true, text: text, error: nil)
    }

    static func failure(_ code: String) -> CleanupHelperResponse {
        CleanupHelperResponse(v: CleanupHelperProtocol.version, ok: false, text: nil, error: code)
    }
}
