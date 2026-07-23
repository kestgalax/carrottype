import Foundation
import WhisperMetalKit

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

actor WhisperSTTEngine: STTEngine {
    private var loadedPath: String?
    private var model: WhisperModel?

    func transcribe(audioURL: URL, modelPath: String?) async throws -> String {
        guard let modelPath else { throw STTEngineError.modelMissing }
        if loadedPath != modelPath {
            model = try WhisperModel(modelPath: URL(fileURLWithPath: modelPath), useGPU: true)
            loadedPath = modelPath
        }
        guard let model else { throw STTEngineError.modelMissing }

        let samples = try WhisperAudio.samples(fromFile: audioURL)
        guard !samples.isEmpty else { throw STTEngineError.emptyAudio }

        let languages: [String?] = [nil, "ru", "en"]
        for lang in languages {
            let result = try await model.transcribe(
                samples: samples,
                options: WhisperOptions(language: lang, translate: false)
            )
            let text = result.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty { return text }
        }
        throw STTEngineError.emptyResult
    }

    func unload() async {
        model = nil
        loadedPath = nil
    }
}
