import AVFoundation
import Foundation

/// Partial live draft shown in the Status Capsule while the user speaks.
/// `volatile` is the muted interim tail (last few words); `confirmed` is the stable body.
struct LiveTranscript: Sendable, Equatable {
    var confirmed: String
    var volatile: String

    var isEmpty: Bool {
        confirmed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && volatile.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

/// Live Capsule preview: feed PCM while recording, surface draft text, cancel on stop.
/// Paste always uses the session WAV file STT path after stop (ADR-014 offline-preview mode).
protocol StreamingSTTEngine: Sendable {
    /// Prepare models and begin accepting audio. Throws if preview cannot start.
    func start(
        modelDirectory: URL,
        packageID: String,
        languageCode: String?,
        onUpdate: @escaping @Sendable (LiveTranscript) -> Void
    ) async throws

    /// Enqueue a 16 kHz mono (or convertible) PCM buffer. Safe to call from the audio tap.
    nonisolated func feed(_ buffer: AVAudioPCMBuffer)

    /// End of utterance helper (optional). Paste path does not rely on this result.
    func finish() async throws -> String

    /// Discard the session without a result (Escape / soft cancel / stop before file STT).
    func cancel() async

    /// Release models / managers after the session.
    func unload() async
}
