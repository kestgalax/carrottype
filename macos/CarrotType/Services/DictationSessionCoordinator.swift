import Foundation

enum DictationSessionPhase: Equatable {
    case idle, starting, recording, transcribing, cleaning, finishing, cancelling
}

struct DictationCapture {
    let url: URL
    let duration: TimeInterval
}

/// Owns one recording's tasks/resources. UI and concrete audio/engine adapters stay outside.
/// Every entry and cleanup runs on the main actor; the install lease outlives all awaits.
@MainActor
final class DictationSessionCoordinator<Configuration, Output> {
    struct Dependencies {
        var startCapture: (Configuration, @escaping (Float) -> Void) throws -> Void
        var stopCapture: () throws -> DictationCapture
        var cancelCapture: () -> Void
        var unmute: (Configuration) async -> Void
        var restoreMute: () async -> Void
        var wantsPreview: (Configuration) -> Bool
        var startPreview: (Configuration, @escaping (String, String) -> Void) async -> Bool
        var attachPreview: (Bool) -> Void
        var stopPreview: () async -> Void
        var process: (DictationCapture, Configuration, @escaping @Sendable (DictationSessionPhase) -> Void) async throws -> Output
        var unload: () async -> Void
    }

    private(set) var phase: DictationSessionPhase = .idle
    private(set) var configuration: Configuration?
    var isActive: Bool { token != nil }
    var onPhase: (DictationSessionPhase) -> Void = { _ in }
    var onPreview: (String, String) -> Void = { _, _ in }
    var onPeak: (Float) -> Void = { _ in }
    var onResult: (Output, TimeInterval, Configuration) async -> Void = { _, _, _ in }
    var onFailure: (Error) -> Void = { _ in }
    var onCancelled: () -> Void = {}

    private let gate: UpdateInstallationGate
    private let dependencies: Dependencies
    private var token: UUID?
    private var operation: Task<Void, Never>?
    private var preview: Task<Void, Never>?
    private var unmute: Task<Void, Never>?
    private var maintenance: Task<Void, Never>?
    private var acceptingOperations = true
    private var cancelled = false
    private var delivering = false
    private var notifiedCancellation = false
    private var capturing = false
    private var audio: DictationCapture?

    init(gate: UpdateInstallationGate, dependencies: Dependencies) {
        self.gate = gate
        self.dependencies = dependencies
    }

    @discardableResult
    func start(_ configuration: Configuration) -> Bool {
        guard acceptingOperations, !isActive, !gate.isBusy, let lease = gate.beginOperation() else { return false }
        token = lease
        self.configuration = configuration
        cancelled = false
        delivering = false
        notifiedCancellation = false
        transition(.starting)
        operation = Task { await startRecording(lease, configuration) }
        return true
    }

    func finish() {
        guard let token, let configuration, phase == .recording else { return }
        preview?.cancel()
        dependencies.attachPreview(false)
        transition(.transcribing)
        operation = Task { await finishRecording(token, configuration) }
    }

    /// Processing cancellation only flags/cancels its owning task; never launches a second teardown.
    func cancel() {
        guard let token, !cancelled, !delivering else { return }
        let wasRecording = phase == .recording
        cancelled = true
        preview?.cancel()
        operation?.cancel()
        dependencies.attachPreview(false)
        transition(.cancelling)
        if capturing { dependencies.cancelCapture(); capturing = false }
        notifyCancellation()
        if wasRecording {
            operation = Task { await complete(token, wasCancelled: true) }
        }
    }

    /// Serializes idle unload/deletion with starts, transforms and install handoff.
    /// Busy operations already unload on exit; their models must remain untouched.
    @discardableResult
    func maintain(_ body: @escaping () async -> Void) -> Bool {
        guard acceptingOperations, !gate.isBusy, let lease = gate.beginOperation() else { return false }
        maintenance = Task {
            await body()
            maintenance = nil
            gate.endOperation(lease)
        }
        return true
    }

    func unloadWhenIdle() {
        _ = maintain { await self.dependencies.unload() }
    }

    func stopAcceptingOperations() { acceptingOperations = false }

    func waitUntilIdle() async {
        await operation?.value
        await maintenance?.value
    }

    private func transition(_ phase: DictationSessionPhase) {
        self.phase = phase
        onPhase(phase)
    }

    private func startRecording(_ lease: UUID, _ configuration: Configuration) async {
        guard token == lease else { return }
        guard !cancelled else { await complete(lease, wasCancelled: true); return }
        unmute = Task { await dependencies.unmute(configuration) }
        do {
            capturing = true
            try dependencies.startCapture(configuration) { [weak self] peak in
                guard let self, self.token == lease, self.phase == .recording else { return }
                self.onPeak(peak)
            }
            transition(.recording)
            guard phase == .recording, dependencies.wantsPreview(configuration) else { return }
            preview = Task { [self] in
                let started = await dependencies.startPreview(configuration) { [weak self] confirmed, volatile in
                    guard let self, self.token == lease, self.phase == .recording, !self.cancelled else { return }
                    self.onPreview(confirmed, volatile)
                }
                await unmute?.value
                guard token == lease, phase == .recording, !Task.isCancelled, !cancelled else { return }
                dependencies.attachPreview(started)
            }
        } catch {
            if !cancelled { onFailure(error) }
            await complete(lease, wasCancelled: cancelled)
        }
    }

    private func finishRecording(_ lease: UUID, _ configuration: Configuration) async {
        var restored = false
        do {
            guard !cancelled else { await complete(lease, wasCancelled: true); return }
            audio = try dependencies.stopCapture()
            capturing = false
            await restoreCaptureResources()
            restored = true
            guard !cancelled else { await complete(lease, wasCancelled: true, restored: true); return }
            let result = try await dependencies.process(audio!, configuration) { [weak self] phase in
                Task { @MainActor in
                    guard let self, self.token == lease, !self.cancelled,
                          self.phase == .transcribing || self.phase == .cleaning,
                          phase == .transcribing || phase == .cleaning else { return }
                    self.transition(phase)
                }
            }
            if !cancelled {
                delivering = true
                transition(.finishing)
                await onResult(result, audio!.duration, configuration)
            }
            await complete(lease, wasCancelled: cancelled, restored: true)
        } catch {
            if !cancelled { onFailure(error) }
            await complete(lease, wasCancelled: cancelled, restored: restored)
        }
    }

    private func restoreCaptureResources() async {
        dependencies.attachPreview(false)
        preview?.cancel()
        await unmute?.value
        unmute = nil
        await dependencies.restoreMute()
        await preview?.value
        preview = nil
        await dependencies.stopPreview()
    }

    private func notifyCancellation() {
        guard !notifiedCancellation else { return }
        notifiedCancellation = true
        onCancelled()
    }

    private func complete(_ lease: UUID, wasCancelled: Bool, restored: Bool = false) async {
        guard token == lease else { return }
        if capturing { dependencies.cancelCapture(); capturing = false }
        if !restored { await restoreCaptureResources() }
        if wasCancelled { notifyCancellation() }
        if let audio { try? FileManager.default.removeItem(at: audio.url) }
        audio = nil
        // Await unload before releasing ownership. No fire-and-forget cleanup can hit a new session.
        await dependencies.unload()
        token = nil
        configuration = nil
        operation = nil
        transition(.idle)
        gate.endOperation(lease)
    }
}
