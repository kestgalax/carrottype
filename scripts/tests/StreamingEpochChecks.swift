import AVFoundation
import Foundation
import FluidAudio

// SDK catalog/version boundaries only; no preview algorithms are copied here.
enum BundledModelCatalog { static let parakeetUltraSTTID = "stt.parakeet-ultra" }
enum ParakeetSTTEngine { static let modelVersion = AsrModelVersion.ultra }

@main struct StreamingChecks {
    static func main() async throws {
        let engine = ParakeetStreamingEngine()
        let probe = PreviewProbe.shared
        let updates = Updates()
        let url = URL(fileURLWithPath: "/tmp/unused-stub-model")
        try await engine.start(modelDirectory: url, packageID: "stt.parakeet-ultra", languageCode: nil) { _ in
            Task { await updates.increment() }
        }
        let oldFeed = await engine.makeFeedHandler()
        let format = AVAudioFormat(standardFormatWithSampleRate: 16_000, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 32_000)!
        buffer.frameLength = 32_000
        for i in 0..<32_000 { buffer.floatChannelData![0][i] = 0.1 }
        let oldFanout = ConvertedBufferFanout()
        oldFanout.setHandler(oldFeed)
        oldFanout.emit(buffer)
        let deadline = Date().addingTimeInterval(5)
        while !(await probe.isBlocked) {
            precondition(Date() < deadline)
            try await Task.sleep(nanoseconds: 1_000_000)
        }
        let cancel = Task { await engine.cancel() }
        while !(await probe.cancellationObserved) {
            precondition(Date() < deadline)
            try await Task.sleep(nanoseconds: 1_000_000)
        }
        // Actual old ASR pass is still running; cancel must not finish cleanup early.
        let before = await probe.cleanups
        precondition(before == 0)
        await probe.release()
        await cancel.value
        let count = await updates.count
        precondition(count == 0)
        try await engine.start(modelDirectory: url, packageID: "stt.parakeet-ultra", languageCode: nil) { _ in
            Task { await updates.increment() }
        }
        oldFanout.setHandler(nil)
        let newFanout = ConvertedBufferFanout()
        var crossSessionFrames = 0
        newFanout.setHandler { _ in crossSessionFrames += 1 }
        oldFanout.emit(buffer)
        precondition(crossSessionFrames == 0)
        oldFeed(buffer) // Even a callback acquired just before detachment retains the old epoch.
        try await Task.sleep(nanoseconds: 2_200_000_000)
        let passes = await probe.transcriptions
        precondition(passes == 1, "Old audio contaminated the new stream")
        await engine.cancel()
        print("PASS actual streaming actor: joins in-flight preview, drops late result and old audio handler in next epoch (stub SDK, no models/microphone)")
    }
}
actor Updates {
    var count = 0
    func increment() { count += 1 }
}
