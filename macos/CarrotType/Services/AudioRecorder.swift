import AVFoundation
import Foundation

enum AudioRecorderError: LocalizedError {
    case alreadyRecording
    case notRecording
    case engineFailed(String)
    case writeFailed(String)
    case silentOrTooShort

    var errorDescription: String? {
        switch self {
        case .alreadyRecording: return L10n.t("error.already_recording")
        case .notRecording: return L10n.t("error.not_recording")
        case .engineFailed(let message): return message
        case .writeFailed(let message): return message
        case .silentOrTooShort:
            return L10n.t("error.silent_recording")
        }
    }
}

/// Shared mutable state for the audio tap (runs off the main actor).
private final class RecordingBuffers: @unchecked Sendable {
    let file: AVAudioFile
    let converter: AVAudioConverter?
    let targetFormat: AVAudioFormat
    private let lock = NSLock()
    private(set) var framesWritten: AVAudioFramePosition = 0
    private(set) var peakLevel: Float = 0
    private(set) var instantaneousPeak: Float = 0
    var onInstantPeak: ((Float) -> Void)?

    init(file: AVAudioFile, converter: AVAudioConverter?, targetFormat: AVAudioFormat) {
        self.file = file
        self.converter = converter
        self.targetFormat = targetFormat
    }

    func append(_ buffer: AVAudioPCMBuffer) {
        let peak = Self.peak(of: buffer)
        lock.lock()
        peakLevel = max(peakLevel, peak)
        instantaneousPeak = peak
        lock.unlock()
        onInstantPeak?(peak)

        if let converter,
           buffer.format.sampleRate != targetFormat.sampleRate
            || buffer.format.channelCount != targetFormat.channelCount {
            let ratio = targetFormat.sampleRate / max(buffer.format.sampleRate, 1)
            let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 32
            guard let converted = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: capacity) else {
                return
            }
            var error: NSError?
            var consumed = false
            let status = converter.convert(to: converted, error: &error) { _, outStatus in
                if consumed {
                    outStatus.pointee = .noDataNow
                    return nil
                }
                consumed = true
                outStatus.pointee = .haveData
                return buffer
            }
            if status != .error, converted.frameLength > 0 {
                try? file.write(from: converted)
                lock.lock()
                framesWritten += AVAudioFramePosition(converted.frameLength)
                lock.unlock()
            }
        } else if buffer.frameLength > 0 {
            try? file.write(from: buffer)
            lock.lock()
            framesWritten += AVAudioFramePosition(buffer.frameLength)
            lock.unlock()
        }
    }

    private nonisolated static func peak(of buffer: AVAudioPCMBuffer) -> Float {
        guard let channels = buffer.floatChannelData else { return 0 }
        let frames = Int(buffer.frameLength)
        let channelCount = Int(buffer.format.channelCount)
        var peak: Float = 0
        for ch in 0..<channelCount {
            let data = channels[ch]
            for i in 0..<frames {
                peak = max(peak, abs(data[i]))
            }
        }
        return peak
    }

    var snapshot: (frames: AVAudioFramePosition, peak: Float) {
        lock.lock()
        defer { lock.unlock() }
        return (framesWritten, peakLevel)
    }
}

/// Captures microphone audio as 16 kHz mono Float32 WAV for whisper.cpp.
@MainActor
final class AudioRecorder {
    private var engine: AVAudioEngine?
    private var buffers: RecordingBuffers?
    private var outputURL: URL?
    private let targetFormat: AVAudioFormat

    private(set) var isRecording = false
    private(set) var lastPeakLevel: Float = 0
    /// Live peak for UI meters (0…1-ish), updated off the audio callback.
    var onLivePeak: ((Float) -> Void)?

    init() {
        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 16_000,
            channels: 1,
            interleaved: false
        ) else {
            fatalError("Unable to create 16 kHz mono float format")
        }
        targetFormat = format
    }

    func start(deviceUID: String?) throws -> URL {
        guard !isRecording else { throw AudioRecorderError.alreadyRecording }

        if let deviceUID, !deviceUID.isEmpty {
            try AudioInputService.selectSystemInputDevice(uid: deviceUID)
        }

        // Fresh engine after device switch — input format is otherwise stale.
        let engine = AVAudioEngine()
        let input = engine.inputNode
        let inputFormat = input.inputFormat(forBus: 0)
        guard inputFormat.sampleRate > 0, inputFormat.channelCount > 0 else {
            throw AudioRecorderError.engineFailed("Микрофон недоступен (нулевая частота дискретизации)")
        }

        let converter: AVAudioConverter?
        if inputFormat.sampleRate != targetFormat.sampleRate
            || inputFormat.channelCount != targetFormat.channelCount {
            converter = AVAudioConverter(from: inputFormat, to: targetFormat)
            guard converter != nil else {
                throw AudioRecorderError.engineFailed("Не удалось создать конвертер аудио")
            }
        } else {
            converter = nil
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("carrottype-\(UUID().uuidString).wav")

        let file: AVAudioFile
        do {
            file = try AVAudioFile(forWriting: url, settings: targetFormat.settings)
        } catch {
            throw AudioRecorderError.writeFailed(error.localizedDescription)
        }

        let session = RecordingBuffers(file: file, converter: converter, targetFormat: targetFormat)
        session.onInstantPeak = { [weak self] peak in
            let display = min(1, pow(peak, 0.55) * 1.35)
            Task { @MainActor in
                self?.onLivePeak?(display)
            }
        }
        buffers = session
        outputURL = url
        self.engine = engine
        lastPeakLevel = 0
        onLivePeak?(0)

        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { buffer, _ in
            session.append(buffer)
        }

        engine.prepare()
        do {
            try engine.start()
        } catch {
            input.removeTap(onBus: 0)
            buffers = nil
            outputURL = nil
            self.engine = nil
            throw AudioRecorderError.engineFailed(error.localizedDescription)
        }

        isRecording = true
        return url
    }

    struct StoppedRecording: Sendable {
        let url: URL
        let duration: TimeInterval
    }

    func stop() throws -> StoppedRecording {
        guard isRecording, let url = outputURL, let engine else {
            throw AudioRecorderError.notRecording
        }

        let snapshot = buffers?.snapshot ?? (frames: 0, peak: 0)
        lastPeakLevel = snapshot.peak
        let duration = Double(snapshot.frames) / targetFormat.sampleRate

        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        buffers = nil
        outputURL = nil
        self.engine = nil
        isRecording = false

        // ~0.35 s of 16 kHz mono, or essentially silent.
        let minFrames: AVAudioFramePosition = 5600
        if snapshot.frames < minFrames || snapshot.peak < 0.004 {
            try? FileManager.default.removeItem(at: url)
            throw AudioRecorderError.silentOrTooShort
        }

        return StoppedRecording(url: url, duration: max(0, duration))
    }

    func cancel() {
        guard isRecording else { return }
        if let engine {
            engine.inputNode.removeTap(onBus: 0)
            if engine.isRunning { engine.stop() }
        }
        if let url = outputURL {
            try? FileManager.default.removeItem(at: url)
        }
        buffers = nil
        outputURL = nil
        engine = nil
        isRecording = false
    }
}
