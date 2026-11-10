import Foundation

@MainActor final class Pause {
    private var continuation: CheckedContinuation<Void, Never>?
    private(set) var waiting = false
    func wait() async { waiting = true; await withCheckedContinuation { continuation = $0 } }
    func release() { continuation?.resume(); continuation = nil }
}

enum FixtureError: Error { case start, stop, process }

@MainActor final class Fixture {
    struct Configuration { let mode: String; let preview: Bool }
    let gate = UpdateInstallationGate()
    var calls: [String] = []
    var delivered: [String] = []
    var failures = 0
    var cancelled = 0
    var previews = 0
    var peak = 0
    var fail: FixtureError?
    var unmutePause: Pause?
    var previewPause: Pause?
    var processPause: Pause?
    var unloadPause: Pause?
    var stalePreview: ((String, String) -> Void)?
    var stalePeak: ((Float) -> Void)?
    var stalePhase: (@Sendable (DictationSessionPhase) -> Void)?
    let audio = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".wav")
    lazy var session: DictationSessionCoordinator<Configuration, String> = {
        let value = DictationSessionCoordinator<Configuration, String>(gate: gate, dependencies: .init(
            startCapture: { [self] configuration, peak in
                calls.append("start"); stalePeak = peak
                if fail == .start { throw FixtureError.start }
            },
            stopCapture: { [self] in
                calls.append("stop")
                if fail == .stop { throw FixtureError.stop }
                try Data("audio fixture".utf8).write(to: audio)
                return DictationCapture(url: audio, duration: 2)
            },
            cancelCapture: { [self] in calls.append("cancelCapture") },
            unmute: { [self] _ in calls.append("unmute"); await unmutePause?.wait(); calls.append("unmuted") },
            restoreMute: { [self] in calls.append("restore") },
            wantsPreview: { $0.preview },
            startPreview: { [self] _, update in
                stalePreview = update; calls.append("preview")
                await previewPause?.wait(); return true
            },
            attachPreview: { [self] attach in if attach { calls.append("attach") } },
            stopPreview: { [self] in calls.append("stopPreview") },
            process: { [self] _, configuration, phase in
                calls.append("process"); stalePhase = phase
                await processPause?.wait()
                if fail == .process { throw FixtureError.process }
                return configuration.mode
            },
            unload: { [self] in calls.append("unload"); await unloadPause?.wait() }
        ))
        value.onResult = { [self] result, _, _ in delivered.append(result) }
        value.onFailure = { [self] _ in failures += 1 }
        value.onCancelled = { [self] in cancelled += 1 }
        value.onPreview = { [self] _, _ in previews += 1 }
        value.onPeak = { [self] _ in peak += 1 }
        return value
    }()
    var countRestore: Int { calls.filter { $0 == "restore" }.count }
    var countUnload: Int { calls.filter { $0 == "unload" }.count }
}

@main struct Checks {
    @MainActor static func until(_ condition: () -> Bool) async {
        let deadline = Date().addingTimeInterval(4)
        while !condition() {
            precondition(Date() < deadline, "Timed out waiting for lifecycle boundary")
            try? await Task.sleep(nanoseconds: 100_000)
        }
    }
    @MainActor static func main() async {
        // Queued PTT release cancels before recorder/unmute start, retaining the gate through unload.
        do {
            let f = Fixture(); f.unloadPause = Pause()
            precondition(f.session.start(.init(mode: "queued", preview: false)))
            f.session.cancel(); f.session.cancel()
            await until { f.unloadPause!.waiting }
            precondition(!f.calls.contains("start") && f.gate.isBusy)
            precondition(!f.gate.prepareForTermination())
            precondition(!f.session.maintain { f.calls.append("delete") })
            f.unloadPause!.release(); await f.session.waitUntilIdle()
            precondition(f.cancelled == 1 && f.countUnload == 1 && !f.gate.isBusy)
        }
        // Stop waits for parallel unmute, cold preview and final unload; snapshot stays pinned.
        do {
            let f = Fixture(); f.unmutePause = Pause(); f.previewPause = Pause(); f.processPause = Pause(); f.unloadPause = Pause()
            precondition(f.session.start(.init(mode: "frozen", preview: true)))
            await until { f.previewPause!.waiting && f.unmutePause!.waiting }
            f.session.finish(); f.session.finish()
            await until { f.calls.contains("stop") }
            precondition(f.countRestore == 0 && !f.calls.contains("process"))
            f.unmutePause!.release(); await until { f.countRestore == 1 }
            precondition(!f.calls.contains("process"))
            f.stalePreview?("late", "draft"); precondition(f.previews == 0)
            f.previewPause!.release(); await until { f.processPause!.waiting }
            precondition(!f.session.start(.init(mode: "new", preview: false)))
            f.processPause!.release(); await until { f.unloadPause!.waiting }
            precondition(f.delivered == ["frozen"] && f.countRestore == 1 && f.gate.isBusy)
            var installs = 0
            precondition(f.gate.postponeInstallation { installs += 1 })
            precondition(!f.session.maintain { f.calls.append("delete") })
            f.unloadPause!.release(); await f.session.waitUntilIdle()
            precondition(installs == 1 && f.countUnload == 1 && !FileManager.default.fileExists(atPath: f.audio.path))
            precondition(!f.session.start(.init(mode: "blocked by install", preview: false)))
        }
        // Escape while load is non-cooperative: recorder stops once; late preview never attaches.
        do {
            let f = Fixture(); f.previewPause = Pause()
            precondition(f.session.start(.init(mode: "cancel", preview: true)))
            await until { f.previewPause!.waiting }
            let oldPeak = f.stalePeak
            f.session.cancel(); f.session.cancel()
            precondition(f.calls.filter { $0 == "cancelCapture" }.count == 1 && f.cancelled == 1)
            await until { f.countRestore == 1 }
            precondition(f.gate.isBusy && f.calls.filter { $0 == "cancelCapture" }.count == 1)
            f.stalePreview?("stale", ""); oldPeak?(1)
            precondition(f.previews == 0 && f.peak == 0 && !f.calls.contains("attach"))
            f.previewPause!.release(); await f.session.waitUntilIdle()
            precondition(f.cancelled == 1 && f.countRestore == 1 && f.countUnload == 1)
            f.previewPause = nil
            precondition(f.session.start(.init(mode: "next", preview: false)))
            await until { f.session.phase == .recording }
            oldPeak?(1); precondition(f.peak == 0)
            f.session.cancel(); await f.session.waitUntilIdle()
        }
        // A cancelled trial discards even a successful result returned by a non-cooperative engine.
        do {
            let f = Fixture(); f.processPause = Pause()
            precondition(f.session.start(.init(mode: "trial", preview: false)))
            await until { f.session.phase == .recording }
            f.session.finish(); await until { f.processPause!.waiting }
            f.session.cancel(); f.session.cancel()
            f.stalePhase?(.cleaning)
            f.processPause!.release(); await f.session.waitUntilIdle()
            precondition(f.delivered.isEmpty && f.cancelled == 1 && f.countRestore == 1 && f.countUnload == 1)
            precondition(!FileManager.default.fileExists(atPath: f.audio.path))
        }
        for failure in [FixtureError.start, .stop, .process] {
            let f = Fixture(); f.fail = failure
            precondition(f.session.start(.init(mode: "failure", preview: false)))
            if failure != .start {
                await until { f.session.phase == .recording }
                f.session.finish()
            }
            await f.session.waitUntilIdle()
            precondition(f.failures == 1 && f.countRestore == 1 && f.countUnload == 1 && !f.gate.isBusy)
        }
        // A stale cleaning callback cannot change the next recording; idle cleanup cannot race a start.
        do {
            let f = Fixture()
            precondition(f.session.start(.init(mode: "first", preview: false)))
            await until { f.session.phase == .recording }; f.session.finish(); await f.session.waitUntilIdle()
            let old = f.stalePhase
            let barrier = Pause()
            precondition(f.session.maintain { await barrier.wait() })
            await until { barrier.waiting }
            precondition(!f.session.start(.init(mode: "too early", preview: false)))
            barrier.release(); await f.session.waitUntilIdle()
            precondition(f.session.start(.init(mode: "second", preview: false)))
            await until { f.session.phase == .recording }
            old?(.cleaning)
            for _ in 0..<10 { await Task.yield() }
            precondition(f.session.phase == .recording)
            f.session.unloadWhenIdle(); precondition(f.countUnload == 1)
            f.session.cancel(); await f.session.waitUntilIdle()
            precondition(f.countUnload == 2)
        }
        do {
            let f = Fixture(); f.unloadPause = Pause()
            precondition(f.session.start(.init(mode: "quit", preview: false)))
            await until { f.session.phase == .recording }
            f.session.stopAcceptingOperations(); f.session.cancel()
            await until { f.unloadPause!.waiting }
            precondition(!f.gate.prepareForTermination())
            f.unloadPause!.release(); await f.session.waitUntilIdle()
            precondition(f.gate.prepareForTermination())
            f.gate.resetInstallation()
            precondition(!f.session.start(.init(mode: "closed", preview: false)))
            precondition(!f.session.maintain {})
        }
        print("PASS production lifecycle: queued release, cold-load/unmute races, cancellation/result discard, single restore/unload, snapshot, stale callbacks, deletion/unload/install/termination lease and temp cleanup")
    }
}
