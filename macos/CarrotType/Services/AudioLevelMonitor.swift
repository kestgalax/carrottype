import AVFoundation
import Foundation

/// Live input level for the selected microphone (0…1).
@MainActor
final class AudioLevelMonitor: ObservableObject {
    @Published private(set) var level: Float = 0
    @Published private(set) var isRunning = false
    @Published private(set) var lastError: String?

    private var engine: AVAudioEngine?
    private var deviceUID: String?
    private var decayTimer: Timer?
    private var lastPublishTime: CFAbsoluteTime = 0
    /// Cap UI publishes so Settings does not redraw at audio-callback rates.
    private let minPublishInterval: CFAbsoluteTime = 1.0 / 8.0

    func start(deviceUID: String?) {
        stop()
        self.deviceUID = deviceUID
        lastError = nil
        lastPublishTime = 0

        do {
            if let deviceUID, !deviceUID.isEmpty {
                try AudioInputService.selectSystemInputDevice(uid: deviceUID)
            }

            let engine = AVAudioEngine()
            let input = engine.inputNode
            let format = input.inputFormat(forBus: 0)
            guard format.sampleRate > 0, format.channelCount > 0 else {
                throw AudioRecorderError.engineFailed(L10n.t("error.meter_unavailable"))
            }

            input.removeTap(onBus: 0)
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                let peak = Self.peakLevel(buffer: buffer)
                Task { @MainActor in
                    guard let self, self.isRunning else { return }
                    let next = max(peak, self.level * 0.82)
                    self.publishLevelIfNeeded(next, force: peak > self.level)
                }
            }

            engine.prepare()
            try engine.start()
            self.engine = engine
            isRunning = true

            // Slow decay timer — UI only needs ~8 Hz, not 30 Hz.
            decayTimer = Timer.scheduledTimer(withTimeInterval: minPublishInterval, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    guard let self, self.isRunning else { return }
                    let next = self.level * 0.85
                    self.publishLevelIfNeeded(next < 0.01 ? 0 : next, force: true)
                }
            }
            if let decayTimer {
                RunLoop.main.add(decayTimer, forMode: .common)
            }
        } catch {
            lastError = error.localizedDescription
            level = 0
            isRunning = false
        }
    }

    func restartIfNeeded(deviceUID: String?) {
        if isRunning, self.deviceUID == deviceUID { return }
        start(deviceUID: deviceUID)
    }

    func stop() {
        decayTimer?.invalidate()
        decayTimer = nil
        if let engine {
            engine.inputNode.removeTap(onBus: 0)
            if engine.isRunning { engine.stop() }
        }
        engine = nil
        isRunning = false
        level = 0
        lastPublishTime = 0
    }

    private func publishLevelIfNeeded(_ next: Float, force: Bool) {
        let now = CFAbsoluteTimeGetCurrent()
        if !force, now - lastPublishTime < minPublishInterval, abs(next - level) < 0.02 {
            return
        }
        lastPublishTime = now
        level = next
    }

    private nonisolated static func peakLevel(buffer: AVAudioPCMBuffer) -> Float {
        guard let channels = buffer.floatChannelData else { return 0 }
        let frameCount = Int(buffer.frameLength)
        guard frameCount > 0 else { return 0 }
        let channelCount = Int(buffer.format.channelCount)
        var peak: Float = 0
        for ch in 0..<channelCount {
            let data = channels[ch]
            for i in 0..<frameCount {
                peak = max(peak, abs(data[i]))
            }
        }
        // Soft knee so quiet speech is visible.
        return min(1, pow(peak, 0.6) * 1.4)
    }
}
