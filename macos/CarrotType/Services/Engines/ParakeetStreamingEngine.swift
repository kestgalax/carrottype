import AVFoundation
import FluidAudio
import Foundation

/// Live Capsule preview via periodic **full-buffer offline** Parakeet passes (OpenBot-style).
///
/// SlidingWindow was dropped for live draft: short windows could not rewrite earlier words
/// with growing context. Each tick re-transcribes all accumulated 16 kHz samples so the
/// draft can adapt. Paste still uses the session WAV file path after stop (ADR-014).
actor ParakeetStreamingEngine: StreamingSTTEngine {
    private var asr: AsrManager?
    private var loadedModels: AsrModels?
    private var language: Language?
    private var samples: [Float] = []
    /// Once we see real speech, drop any muted/silent prefix for good (full-buffer preview).
    private var leadingSilenceCompacted = false
    private var previewLoop: Task<Void, Never>?
    private var passInFlight = false
    private var onUpdate: (@Sendable (LiveTranscript) -> Void)?
    /// Bumped by `cancelInternal` so an in-flight `start` cannot publish after cancel or a newer start.
    private var startToken: UInt64 = 0

    /// Shared CoreML models from the last successful `start` (optional offline reuse).
    var sharedModels: AsrModels? { loadedModels }

    private static let previewIntervalNs: UInt64 = 1_000_000_000
    /// Skip ticks until we have a little speech (OpenBot waits on first chunk cadence).
    private static let minPreviewSamples = 8_000 // 0.5 s @ 16 kHz
    /// Match AudioRecorder soft-silence peak — leading mute (parallel unmute) must not enter ASR.
    private static let leadingSilencePeak: Float = 0.004
    private static let interimWordCount = 2

    func start(
        modelDirectory: URL,
        packageID: String,
        languageCode: String?,
        onUpdate: @escaping @Sendable (LiveTranscript) -> Void
    ) async throws {
        let myToken = await cancelInternal(clearModels: true)
        try Task.checkCancellation()
        guard startToken == myToken else { throw CancellationError() }

        guard packageID == BundledModelCatalog.parakeetUltraSTTID else { throw STTEngineError.modelMissing }
        guard AsrModels.modelsExist(at: modelDirectory, version: ParakeetSTTEngine.modelVersion) else {
            throw STTEngineError.modelMissing
        }

        let models: AsrModels
        do {
            models = try await AsrModels.load(from: modelDirectory, version: ParakeetSTTEngine.modelVersion)
        } catch {
            if startToken != myToken { throw CancellationError() }
            throw error
        }
        guard startToken == myToken else { throw CancellationError() }

        try Task.checkCancellation()
        let manager = AsrManager(config: .default)
        do {
            try await manager.loadModels(models)
        } catch {
            await manager.cleanup()
            if startToken != myToken { throw CancellationError() }
            throw error
        }
        guard startToken == myToken, !Task.isCancelled else {
            await manager.cleanup()
            throw CancellationError()
        }

        loadedModels = models
        asr = manager
        language = Self.fluidLanguage(from: languageCode)
        samples = []
        leadingSilenceCompacted = false
        self.onUpdate = onUpdate

        previewLoop = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: Self.previewIntervalNs)
                if Task.isCancelled { break }
                await self.runPreviewPassIfNeeded()
            }
        }
    }

    /// Compatibility feed targets the current stream. The recorder uses the generation-bound handler below.
    nonisolated func feed(_ buffer: AVAudioPCMBuffer) {
        guard let floats = Self.monoFloats(from: buffer), !floats.isEmpty else { return }
        Task { await self.appendCurrentSamples(floats) }
    }

    private func appendCurrentSamples(_ samples: [Float]) { appendSamples(samples, token: startToken) }

    /// Capture the preview generation at attachment; an old tap must never feed a newer session.
    func makeFeedHandler() -> @Sendable (AVAudioPCMBuffer) -> Void {
        let token = startToken
        return { [weak self] buffer in
            guard let floats = Self.monoFloats(from: buffer), !floats.isEmpty else { return }
            Task { await self?.appendSamples(floats, token: token) }
        }
    }

    func finish() async throws -> String {
        // Capsule preview only — paste always uses the session WAV file path after stop.
        previewLoop?.cancel()
        previewLoop = nil
        onUpdate = nil
        asr = nil
        samples = []
        throw STTEngineError.emptyResult
    }

    func cancel() async {
        await cancelInternal(clearModels: true)
    }

    func unload() async {
        await cancelInternal(clearModels: true)
    }

    /// Offline WAV pass using already-loaded models (Settings “refine after stop” / helpers).
    func transcribeOffline(audioURL: URL) async throws -> String {
        guard let models = loadedModels else { throw STTEngineError.modelMissing }
        let manager = AsrManager(config: .default)
        try await manager.loadModels(models)
        do {
            var decoderState = TdtDecoderState.make()
            let result = try await manager.transcribe(audioURL, decoderState: &decoderState, language: language)
            await manager.cleanup()
            let text = result.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { throw STTEngineError.emptyResult }
            return text
        } catch {
            await manager.cleanup()
            throw error
        }
    }

    // MARK: - Private

    private func appendSamples(_ chunk: [Float], token: UInt64) {
        guard startToken == token, asr != nil else { return }
        samples.append(contentsOf: chunk)
        compactLeadingSilenceIfNeeded()
    }

    /// Parallel unmute (ADR-007) leaves a muted prefix in the capture fan-out. Full-buffer
    /// preview re-decodes that prefix every tick → multilingual translit / `<unk>` across the
    /// whole draft, not only the first words. Drop it once voice appears.
    private func compactLeadingSilenceIfNeeded() {
        guard !leadingSilenceCompacted else { return }
        let trimmed = Self.trimLeadingSilence(samples, peakThreshold: Self.leadingSilencePeak)
        if trimmed.isEmpty {
            // Still muted/silent — bound RAM until Wave Link unmute finishes.
            let maxHold = 16_000 * 2 // 2 s @ 16 kHz
            if samples.count > maxHold {
                samples = Array(samples.suffix(maxHold))
            }
            return
        }
        if trimmed.count < samples.count {
            samples = trimmed
        }
        leadingSilenceCompacted = true
    }

    private func runPreviewPassIfNeeded(force: Bool = false) async {
        guard !passInFlight else { return }
        guard let asr else { return }
        compactLeadingSilenceIfNeeded()
        guard leadingSilenceCompacted || force else { return }
        let snapshot = samples
        guard force || snapshot.count >= Self.minPreviewSamples else { return }

        let token = startToken
        let update = onUpdate
        passInFlight = true
        defer { if startToken == token { passInFlight = false } }

        do {
            var decoderState = TdtDecoderState.make()
            let result = try await asr.transcribe(
                snapshot,
                decoderState: &decoderState,
                language: language
            )
            guard startToken == token, !Task.isCancelled else { return }
            let trimmed = Self.sanitizePreviewText(result.text)
            guard !trimmed.isEmpty else { return }
            let split = Self.splitInterimTail(trimmed, interimWords: Self.interimWordCount)
            update?(LiveTranscript(confirmed: split.body, volatile: split.tail))
        } catch {
            if error is CancellationError || Task.isCancelled { return }
            NSLog("CarrotType: live draft preview pass failed: %@", error.localizedDescription)
        }
    }

    /// Invalidates any in-flight `start` before the first await, then tears down published state.
    /// Returns the token captured at invalidation so the caller can detect a newer `start`/`cancel`.
    @discardableResult
    private func cancelInternal(clearModels: Bool) async -> UInt64 {
        startToken &+= 1
        let token = startToken
        let loop = previewLoop
        loop?.cancel()
        previewLoop = nil
        passInFlight = false
        samples = []
        leadingSilenceCompacted = false
        onUpdate = nil
        let published = asr
        // Joining the actual preview pass prevents its old manager cleanup from racing a new one.
        await loop?.value
        if let published {
            await published.cleanup()
        }
        // A newer start/cancel may have published during cleanup. Do not clear it.
        guard startToken == token else { return token }
        asr = nil
        if clearModels {
            loadedModels = nil
        }
        language = nil
        return token
    }

    private static func splitInterimTail(
        _ text: String,
        interimWords: Int
    ) -> (body: String, tail: String) {
        let words = text.split { $0.isWhitespace || $0.isNewline }.map(String.init)
        guard !words.isEmpty else { return ("", "") }
        if words.count <= interimWords {
            return ("", words.joined(separator: " "))
        }
        let body = words.dropLast(interimWords).joined(separator: " ")
        let tail = words.suffix(interimWords).joined(separator: " ")
        return (body, tail)
    }

    static func sanitizePreviewText(_ text: String) -> String { LiveDraftText.sanitizePreviewText(text) }
    static func trimLeadingSilence(_ samples: [Float], peakThreshold: Float) -> [Float] {
        LiveDraftText.trimLeadingSilence(samples, peakThreshold: peakThreshold)
    }

    private static func fluidLanguage(from code: String?) -> Language? {
        guard let raw = code?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
              !raw.isEmpty
        else { return nil }
        let primary = raw.split(separator: "-").first.map(String.init) ?? raw
        return Language(rawValue: primary)
    }

    private static func monoFloats(from buffer: AVAudioPCMBuffer) -> [Float]? {
        let frames = Int(buffer.frameLength)
        guard frames > 0, let channels = buffer.floatChannelData else { return nil }
        if buffer.format.channelCount == 1 {
            return Array(UnsafeBufferPointer(start: channels[0], count: frames))
        }
        // Downmix if a converter ever feeds multi-channel (recorder targets mono).
        var out = [Float](repeating: 0, count: frames)
        let chCount = Int(buffer.format.channelCount)
        for f in 0..<frames {
            var sum: Float = 0
            for ch in 0..<chCount {
                sum += channels[ch][f]
            }
            out[f] = sum / Float(chCount)
        }
        return out
    }
}
