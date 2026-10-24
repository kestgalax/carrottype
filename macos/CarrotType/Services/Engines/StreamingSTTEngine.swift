import AVFoundation
import Foundation

/// Partial live draft shown in the Status Capsule while the user speaks.
/// `volatile` is the replaceable tail; it must not be appended across updates.
struct LiveTranscript: Sendable, Equatable {
    var confirmed: String
    var volatile: String

    var isEmpty: Bool {
        confirmed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && volatile.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

/// Streaming STT: feed PCM while recording, surface confirmed + volatile text, finish on stop.
/// Nothing is pasted until `finish()` (or the file-path fallback) returns.
protocol StreamingSTTEngine: Sendable {
    /// Prepare models and begin accepting audio. Throws if streaming cannot start.
    func start(
        modelDirectory: URL,
        packageID: String,
        languageCode: String?,
        onUpdate: @escaping @Sendable (LiveTranscript) -> Void
    ) async throws

    /// Enqueue a 16 kHz mono (or convertible) PCM buffer. Must be safe to call from the audio tap.
    /// Callers should pass a buffer that will not be overwritten; implementations may copy again.
    nonisolated func feed(_ buffer: AVAudioPCMBuffer)

    /// End of utterance: flush and return the final transcript text.
    func finish() async throws -> String

    /// Discard the session without a result (Escape / soft cancel).
    func cancel() async

    /// Release models / managers after the session (and optional offline pass).
    func unload() async
}
