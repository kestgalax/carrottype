import AVFoundation
import Foundation

/// Main-actor assignment of `AudioRecorder.onConvertedBuffer`; the tap calls `emit`.
final class ConvertedBufferFanout: @unchecked Sendable {
    private let lock = NSLock()
    private var handler: ((AVAudioPCMBuffer) -> Void)?

    func setHandler(_ handler: ((AVAudioPCMBuffer) -> Void)?) {
        lock.lock()
        self.handler = handler
        lock.unlock()
    }

    func currentHandler() -> ((AVAudioPCMBuffer) -> Void)? {
        lock.lock()
        defer { lock.unlock() }
        return handler
    }

    func emit(_ buffer: AVAudioPCMBuffer) {
        lock.lock()
        let handler = self.handler
        lock.unlock()
        handler?(buffer)
    }
}
