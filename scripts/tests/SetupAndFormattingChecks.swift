import Foundation

private enum FakeFailure: Error { case helperMissing, timeout, generation }
private actor FailingCleanup: CleanupEngine {
    let failure: FakeFailure
    private(set) var calls = 0
    init(_ failure: FakeFailure) { self.failure = failure }
    func cleanup(text: String, mode: CleanupMode, modelDirectory: URL?, instructions: String?) async throws -> String {
        calls += 1
        throw failure
    }
    func unload() async {}
}
private actor SuccessfulCleanup: CleanupEngine {
    private(set) var calls = 0
    func cleanup(text: String, mode: CleanupMode, modelDirectory: URL?, instructions: String?) async throws -> String {
        calls += 1
        return "Formatted fixture."
    }
    func unload() async {}
}
private actor CancelledCleanup: CleanupEngine {
    func cleanup(text: String, mode: CleanupMode, modelDirectory: URL?, instructions: String?) async throws -> String {
        throw CancellationError()
    }
    func unload() async {}
}

@main
struct SetupAndFormattingChecks {
    @MainActor static func main() async throws {
        let progressCases: [(SetupProgress, Int, SetupProgress.Step?)] = [
            (SetupProgress(microphone: false, accessibility: false, model: false, trial: false), 0, .microphone),
            (SetupProgress(microphone: true, accessibility: false, model: false, trial: false), 1, .accessibility),
            (SetupProgress(microphone: true, accessibility: true, model: false, trial: false), 2, .model),
            (SetupProgress(microphone: true, accessibility: true, model: true, trial: false), 3, .trial),
            (SetupProgress(microphone: true, accessibility: true, model: true, trial: true), 4, nil),
            (SetupProgress(microphone: false, accessibility: true, model: true, trial: true), 3, .microphone),
        ]
        for (progress, count, next) in progressCases {
            precondition(progress.completedCount == count && progress.nextStep == next)
        }
        print("PASS setup: partial/revoked requirements, ordered next step, trial separate from readiness")

        let light = LightCleanupEngine()
        for mode in [CleanupMode.off, .light] {
            let result = try await DictationFormatting.perform(text: "Hello world.", mode: mode, directory: nil,
                                                               engine: light, lightEngine: light)
            precondition(result.text == "Hello world." && result.formatting.actualMode == mode && !result.formatting.usedFallback)
        }
        let successful = SuccessfulCleanup()
        for mode in [CleanupMode.smart, .smartPlus, .gemma] {
            let result = try await DictationFormatting.perform(text: "fixture", mode: mode,
                directory: URL(fileURLWithPath: "/unused-test-model"), engine: successful, lightEngine: light)
            precondition(result.text == "Formatted fixture." && result.formatting.actualMode == mode && !result.formatting.usedFallback)
            for failure in [FakeFailure.helperMissing, .timeout, .generation] {
                let engine = FailingCleanup(failure)
                let fallback = try await DictationFormatting.perform(text: "Hello world.", mode: mode,
                    directory: URL(fileURLWithPath: "/unused-test-model"), engine: engine, lightEngine: light)
                precondition(fallback.text == "Hello world." && fallback.formatting.requestedMode == mode)
                precondition(fallback.formatting.actualMode == .light && fallback.formatting.fallbackReason == .generationFailed)
            }
            let missing = try await DictationFormatting.perform(text: "Hello world.", mode: mode, directory: nil,
                                                               engine: successful, lightEngine: light)
            precondition(missing.formatting.fallbackReason == .modelUnavailable && missing.text == "Hello world.")
        }
        let calls = await successful.calls
        precondition(calls == 3) // missing packages must not invoke the MLX engine
        do {
            _ = try await DictationFormatting.perform(text: "fixture", mode: .smart,
                directory: URL(fileURLWithPath: "/unused-test-model"), engine: CancelledCleanup(), lightEngine: light)
            preconditionFailure("Cancellation must not become a successful fallback")
        } catch is CancellationError {}
        print("PASS formatting: Off/Light, successful MLX modes, missing package/helper, timeout/generation failure, cancellation")

        var caretCalls = 0, trialCalls = 0, statsCount = 0, clipboardWrites = 0
        let result = FormattedDictation(text: "Trial fixture", formatting: FormattingOutcome(requestedMode: .light, actualMode: .light, fallbackReason: nil))
        let caret: (FormattedDictation) -> Void = { _ in caretCalls += 1; statsCount += 1; clipboardWrites += 1 }
        let trial: (FormattedDictation) -> Void = { completed in trialCalls += 1; precondition(completed.text == "Trial fixture") }
        DictationDelivery.setupTrial.deliver(result, atCaret: caret, inTrial: trial)
        precondition(caretCalls == 0 && statsCount == 0 && clipboardWrites == 0 && trialCalls == 1)
        DictationDelivery.caret.deliver(result, atCaret: caret, inTrial: trial)
        precondition(caretCalls == 1 && statsCount == 1 && clipboardWrites == 1 && trialCalls == 1)
        print("PASS delivery: trial skips caret/clipboard/stats closure; normal output delivered exactly once")

        precondition(TransformModelSelection.resolve(requested: .smartPlus, available: [.smart, .smartPlus]) == .smartPlus)
        precondition(TransformModelSelection.resolve(requested: .gemma, available: [.smart, .smartPlus]) == .smart)
        precondition(TransformModelSelection.resolve(requested: .smart, available: []) == nil)
        precondition(TransformModelSelection.resolve(requested: .off, available: [.off, .light]) == nil)
        let name = "carrottype.setup-checks.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        precondition(TransformBindingsStore.load(defaults: defaults).count == 1)
        for count in 0...5 {
            let bindings = (0..<count).map { _ in TransformBinding.makeDefault() }
            TransformBindingsStore.save(bindings, defaults: defaults)
            precondition(TransformBindingsStore.load(defaults: defaults) == bindings)
        }
        print("PASS bindings: real resolution policy, saved 0–5 rows persist, empty list does not resurrect defaults")
        let hotkeys = HotkeyService(defaults: defaults, registersGlobalHotkeys: false)
        let binding = TransformBinding.makeDefault()
        hotkeys.replaceTransformBindings([binding])
        let original = hotkeys.chord
        hotkeys.apply(binding.chord, for: .dictation)
        precondition(hotkeys.lastCaptureConflict && hotkeys.chord == original)
        hotkeys.apply(original, for: .transformBinding(binding.id))
        precondition(hotkeys.lastCaptureConflict && hotkeys.binding(id: binding.id)?.chord == binding.chord)
        var actions = 0
        hotkeys.setOnHotkey { actions += 1 }
        hotkeys.isRecording = true
        hotkeys.handleCarbonHotkeyPressed()
        precondition(actions == 0)
        hotkeys.cancelRecording()
        hotkeys.handleCarbonHotkeyPressed()
        precondition(actions == 1 && !hotkeys.isRecording)
        print("PASS hotkey capture: duplicate-chord conflicts keep original settings; editing does not trigger dictation")
    }
}
