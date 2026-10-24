import AVFoundation
import FluidAudio
import Foundation

/// Pseudo-streaming Parakeet via FluidAudio `SlidingWindowAsrManager` (v0.17.7).
/// Loads the same cache directory / `AsrModelVersion` as `ParakeetSTTEngine`.
/// `AsrModels` keeps `MLModel` class references — offline second pass can reuse them
/// without a second disk load (see ADR-014).
actor ParakeetStreamingEngine: StreamingSTTEngine {
    private var manager: SlidingWindowAsrManager?
    private var loadedModels: AsrModels?
    private var updatePump: Task<Void, Never>?
    private var feedPump: Task<Void, Never>?
    private let feedBridge = FeedBridge()

    /// Shared CoreML models from the last successful `start`, for an optional offline WAV pass.
    var sharedModels: AsrModels? { loadedModels }

    func start(
        modelDirectory: URL,
        packageID: String,
        languageCode: String?,
        onUpdate: @escaping @Sendable (LiveTranscript) -> Void
    ) async throws {
        await cancelInternal(clearModels: true)

        let kind = ParakeetSTTEngine.PackageKind.resolve(packageID: packageID)
        guard AsrModels.modelsExist(at: modelDirectory, version: kind.version) else {
            throw STTEngineError.modelMissing
        }

        let models = try await AsrModels.load(from: modelDirectory, version: kind.version)
        let language = Self.fluidLanguage(from: languageCode)
        let sliding = SlidingWindowAsrManager(
            config: .streaming.applying(language: language)
        )
        try await sliding.loadModels(models)
        try await sliding.startStreaming(source: .microphone)

        loadedModels = models
        manager = sliding

        let (feedStream, feedContinuation) = AsyncStream<AVAudioPCMBuffer>.makeStream()
        feedBridge.continuation = feedContinuation
        feedPump = Task {
            for await buffer in feedStream {
                await sliding.streamAudio(buffer)
            }
        }

        updatePump = Task {
            for await _ in await sliding.transcriptionUpdates {
                let confirmed = await sliding.confirmedTranscript
                let volatile = await sliding.volatileTranscript
                onUpdate(LiveTranscript(confirmed: confirmed, volatile: volatile))
            }
        }
    }

    nonisolated func feed(_ buffer: AVAudioPCMBuffer) {
        guard let copy = Self.copyBuffer(buffer) else { return }
        feedBridge.yield(copy)
    }

    func finish() async throws -> String {
        defer {
            updatePump?.cancel()
            updatePump = nil
            feedPump = nil
            feedBridge.finish()
            manager = nil
        }

        guard let manager else { throw STTEngineError.emptyResult }

        feedBridge.finish()
        // Let the feed pump drain into SlidingWindow before finish() closes recognition.
        await feedPump?.value
        feedPump = nil

        let text = try await manager.finish()
        await manager.cleanup()
        updatePump?.cancel()
        updatePump = nil

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw STTEngineError.emptyResult }
        // Keep `loadedModels` until `unload()` so an optional offline WAV pass can reuse them.
        return trimmed
    }

    func cancel() async {
        await cancelInternal(clearModels: true)
    }

    func unload() async {
        await cancelInternal(clearModels: true)
    }

    /// Offline WAV pass using the already-loaded `AsrModels` (shared `MLModel` refs).
    func transcribeOffline(audioURL: URL) async throws -> String {
        guard let models = loadedModels else { throw STTEngineError.modelMissing }
        let asr = AsrManager(config: .default)
        try await asr.loadModels(models)
        do {
            var decoderState = TdtDecoderState.make()
            let result = try await asr.transcribe(audioURL, decoderState: &decoderState)
            await asr.cleanup()
            let text = result.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { throw STTEngineError.emptyResult }
            return text
        } catch {
            await asr.cleanup()
            throw error
        }
    }

    private func cancelInternal(clearModels: Bool) async {
        updatePump?.cancel()
        updatePump = nil
        feedBridge.finish()
        feedPump?.cancel()
        feedPump = nil
        if let manager {
            await manager.cancel()
            await manager.cleanup()
        }
        manager = nil
        if clearModels {
            loadedModels = nil
        }
    }

    private static func fluidLanguage(from code: String?) -> Language? {
        guard let raw = code?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
              !raw.isEmpty
        else { return nil }
        let primary = raw.split(separator: "-").first.map(String.init) ?? raw
        return Language(rawValue: primary)
    }

    private static func copyBuffer(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        guard let copy = AVAudioPCMBuffer(pcmFormat: buffer.format, frameCapacity: buffer.frameLength)
        else { return nil }
        copy.frameLength = buffer.frameLength
        guard let src = buffer.floatChannelData, let dst = copy.floatChannelData else {
            return copy.frameLength > 0 ? copy : nil
        }
        let channels = Int(buffer.format.channelCount)
        let frames = Int(buffer.frameLength)
        for ch in 0..<channels {
            memcpy(dst[ch], src[ch], frames * MemoryLayout<Float>.size)
        }
        return copy
    }
}

/// Thread-safe yield into the actor's feed `AsyncStream` (audio tap must not await the actor).
private final class FeedBridge: @unchecked Sendable {
    private let lock = NSLock()
    var continuation: AsyncStream<AVAudioPCMBuffer>.Continuation? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _continuation
        }
        set {
            lock.lock()
            _continuation = newValue
            lock.unlock()
        }
    }

    private var _continuation: AsyncStream<AVAudioPCMBuffer>.Continuation?

    func yield(_ buffer: AVAudioPCMBuffer) {
        lock.lock()
        let cont = _continuation
        lock.unlock()
        cont?.yield(buffer)
    }

    func finish() {
        lock.lock()
        let cont = _continuation
        _continuation = nil
        lock.unlock()
        cont?.finish()
    }
}
