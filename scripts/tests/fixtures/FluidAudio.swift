// Test-only SDK boundary. The production ParakeetStreamingEngine is compiled unchanged.
import Foundation

public enum AsrModelVersion: Sendable { case ultra }
public struct Language: RawRepresentable, Sendable {
    public let rawValue: String
    public init?(rawValue: String) { self.rawValue = rawValue }
}
public struct TdtDecoderState: Sendable {
    public static func make() -> Self { Self() }
}
public struct Transcript: Sendable { public let text: String }
public actor PreviewProbe {
    public static let shared = PreviewProbe()
    private var blocked: CheckedContinuation<Void, Never>?
    public private(set) var transcriptions = 0
    public private(set) var cleanups = 0
    public private(set) var cancellationObserved = false
    public var isBlocked: Bool { blocked != nil }
    public func transcribe() async -> Transcript {
        transcriptions += 1
        await withTaskCancellationHandler(operation: {
            await withCheckedContinuation { blocked = $0 }
        }, onCancel: {
            Task { await self.noteCancellation() }
        })
        return Transcript(text: "old result must not reach new stream")
    }
    private func noteCancellation() { cancellationObserved = true }
    public func release() { blocked?.resume(); blocked = nil }
    public func cleanup() { cleanups += 1 }
}
public struct AsrModels: Sendable {
    public static func modelsExist(at: URL, version: AsrModelVersion) -> Bool { true }
    public static func load(from: URL, version: AsrModelVersion) async throws -> Self { Self() }
}
public actor AsrManager {
    public init(config: Configuration) {}
    public struct Configuration: Sendable { public static let `default` = Self() }
    public func loadModels(_ models: AsrModels) async throws {}
    public func cleanup() async { await PreviewProbe.shared.cleanup() }
    public func transcribe(_ samples: [Float], decoderState: inout TdtDecoderState, language: Language?) async throws -> Transcript {
        await PreviewProbe.shared.transcribe()
    }
    public func transcribe(_ audioURL: URL, decoderState: inout TdtDecoderState, language: Language?) async throws -> Transcript {
        await PreviewProbe.shared.transcribe()
    }
}
