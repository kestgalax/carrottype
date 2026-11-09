import Foundation

enum STTEngineError: LocalizedError {
    case modelMissing
    case emptyAudio
    case emptyResult
    case unsupported

    var errorDescription: String? {
        switch self {
        case .modelMissing: return L10n.t("error.stt_model_missing")
        case .emptyAudio: return L10n.t("error.stt_empty_audio")
        case .emptyResult: return L10n.t("error.stt_empty_result")
        case .unsupported: return L10n.t("error.stt_unsupported")
        }
    }
}
