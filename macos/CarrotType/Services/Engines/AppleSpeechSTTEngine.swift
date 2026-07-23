import AVFoundation
import Foundation
import Speech

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

    static func speechLocale(for appLocale: Locale) async -> Locale? {
        guard #available(macOS 26, *) else { return nil }
        let code = appLocale.language.languageCode?.identifier ?? "en"
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
        guard #available(macOS 26, *) else {
            throw STTEngineError.unsupported
        }
        guard let speechLocale = await speechLocale(for: locale) else {
            throw STTEngineError.unsupported
        }

        try FileManager.default.createDirectory(at: packageDirectory, withIntermediateDirectories: true)
        _ = try await AssetInventory.reserve(locale: speechLocale)

        let transcriber = SpeechTranscriber(locale: speechLocale, preset: .transcription)
        if let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
            let observation = request.progress.observe(\.fractionCompleted) { progress, _ in
                onProgress?(progress.fractionCompleted)
            }
            defer { observation.invalidate() }
            try await request.downloadAndInstall()
        }
        onProgress?(1)

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
