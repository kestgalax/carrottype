import AVFoundation
import Foundation
import Speech

/// User-facing Prepare failure for Apple SpeechAnalyzer (never show raw SFSpeechError text in Settings).
enum AppleSpeechPrepareError: LocalizedError {
    case unsupportedOS
    case localeNotSupported(languageCode: String)
    case assetUnavailable(languageCode: String)
    case other

    var errorDescription: String? {
        switch self {
        case .unsupportedOS:
            return L10n.t("error.apple_speech_os")
        case .localeNotSupported(let code):
            return String(format: L10n.t("error.apple_speech_locale"), displayLanguage(code))
        case .assetUnavailable(let code):
            if code.hasPrefix("ru") {
                return L10n.t("error.apple_speech_ru_unavailable")
            }
            return String(format: L10n.t("error.apple_speech_asset_unavailable"), displayLanguage(code))
        case .other:
            return L10n.t("error.apple_speech_prepare_failed")
        }
    }

    private func displayLanguage(_ code: String) -> String {
        code.hasPrefix("ru") ? L10n.t("language.russian") : L10n.t("language.english")
    }

    /// Map Apple / system errors into calm Settings copy.
    static func from(systemError: Error, languageCode: String) -> AppleSpeechPrepareError {
        let raw = [
            systemError.localizedDescription,
            (systemError as NSError).userInfo[NSLocalizedDescriptionKey] as? String,
            String(describing: systemError),
        ]
        .compactMap { $0 }
        .joined(separator: " ")
        .lowercased()

        if raw.contains("not installing")
            || raw.contains("unavailable after attempted download")
            || raw.contains("asset not found after attempted download")
            || raw.contains("asset unavailable") {
            return .assetUnavailable(languageCode: languageCode)
        }
        return .other
    }
}

/// On-device STT via Apple SpeechAnalyzer (macOS 26+). Catalog: `stt.apple-speechanalyzer`.
actor AppleSpeechSTTEngine: STTEngine {
    static var isPlatformSupported: Bool {
        if #available(macOS 26, *) { return true }
        return false
    }

    /// Fluid-style layout: catalog package dir holds only a Ready marker (assets live in the system).
    static func isPackageReady(packageDirectory: URL) -> Bool {
        FileManager.default.fileExists(atPath: ModelPackageLayout.readyMarker(in: packageDirectory).path)
    }

    static func preferredAppLocale() -> Locale {
        L10n.preferredLocale
    }

    static func languageCode(for appLocale: Locale) -> String {
        appLocale.language.languageCode?.identifier ?? "en"
    }

    static func speechLocale(for appLocale: Locale) async -> Locale? {
        guard #available(macOS 26, *) else { return nil }
        let code = languageCode(for: appLocale)
        let preferred = Locale(identifier: code.hasPrefix("ru") ? "ru_RU" : "en_US")
        return await SpeechTranscriber.supportedLocale(equivalentTo: preferred)
    }

    static func isReady(locale: Locale) async -> Bool {
        guard #available(macOS 26, *) else { return false }
        guard let speechLocale = await speechLocale(for: locale) else { return false }
        let transcriber = SpeechTranscriber(locale: speechLocale, preset: .transcription)
        let status = await AssetInventory.status(forModules: [transcriber])
        return status == .installed
    }

    /// Download/install system speech assets for the app language; writes Ready marker under `packageDirectory`.
    static func ensureAssets(
        packageDirectory: URL,
        locale: Locale,
        onProgress: (@Sendable (Double) -> Void)? = nil
    ) async throws {
        let languageCode = languageCode(for: locale)
        guard #available(macOS 26, *) else {
            throw AppleSpeechPrepareError.unsupportedOS
        }
        guard let speechLocale = await speechLocale(for: locale) else {
            throw AppleSpeechPrepareError.localeNotSupported(languageCode: languageCode)
        }

        try FileManager.default.createDirectory(at: packageDirectory, withIntermediateDirectories: true)
        _ = try await AssetInventory.reserve(locale: speechLocale)

        let transcriber = SpeechTranscriber(locale: speechLocale, preset: .transcription)
        do {
            if let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
                let observation = request.progress.observe(\.fractionCompleted) { progress, _ in
                    onProgress?(progress.fractionCompleted)
                }
                defer { observation.invalidate() }
                try await request.downloadAndInstall()
            }
        } catch {
            throw AppleSpeechPrepareError.from(systemError: error, languageCode: languageCode)
        }
        onProgress?(1)

        let status = await AssetInventory.status(forModules: [transcriber])
        guard status == .installed else {
            throw AppleSpeechPrepareError.assetUnavailable(languageCode: languageCode)
        }

        let marker = ModelPackageLayout.readyMarker(in: packageDirectory)
        try Data().write(to: marker, options: .atomic)
    }

    static func removePrepared(packageDirectory: URL, locale: Locale) async throws {
        if #available(macOS 26, *) {
            if let speechLocale = await speechLocale(for: locale) {
                _ = await AssetInventory.release(reservedLocale: speechLocale)
            }
        }
        let fm = FileManager.default
        if fm.fileExists(atPath: packageDirectory.path) {
            try fm.removeItem(at: packageDirectory)
        }
    }

    func transcribe(audioURL: URL, modelPath: String?) async throws -> String {
        _ = modelPath
        guard #available(macOS 26, *) else {
            throw STTEngineError.unsupported
        }
        guard let speechLocale = await Self.speechLocale(for: Self.preferredAppLocale()) else {
            throw STTEngineError.unsupported
        }

        let transcriber = SpeechTranscriber(locale: speechLocale, preset: .transcription)
        let status = await AssetInventory.status(forModules: [transcriber])
        if status != .installed {
            if let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
                try await request.downloadAndInstall()
            }
        }

        let audioFile = try AVAudioFile(forReading: audioURL)
        let analyzer = try await SpeechAnalyzer(
            inputAudioFile: audioFile,
            modules: [transcriber],
            finishAfterFile: true
        )
        _ = analyzer

        var parts: [String] = []
        for try await result in transcriber.results {
            guard result.isFinal else { continue }
            let chunk = String(result.text.characters).trimmingCharacters(in: .whitespacesAndNewlines)
            if !chunk.isEmpty {
                parts.append(chunk)
            }
        }

        let text = parts.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw STTEngineError.emptyResult }
        return text
    }

    func unload() async {
        // System modules are not retained across sessions.
    }
}
