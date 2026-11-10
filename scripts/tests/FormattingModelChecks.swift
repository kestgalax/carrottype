import AppKit
@testable import CarrotType

/// Opt-in observations of the real AppState trial. Synthetic inputs only; no model download.
@main struct FormattingModelChecks {
    struct Sample: Decodable { let id: String; let text: String; let rules: DictationRules? }
    @MainActor static func main() throws {
        NSApplication.shared.setActivationPolicy(.prohibited)
        let defaults = UserDefaults.standard
        let identity = Bundle.main.bundleIdentifier!
        precondition(identity.contains(".update-test.formatting."))
        defer { defaults.removePersistentDomain(forName: identity) }
        defaults.set(true, forKey: "carrottype.didCompleteFirstRun")
        let temporary = URL(fileURLWithPath: CommandLine.arguments[1])
        let modelRoot = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("carrottype/models")
        let state = AppState(modelManager: ModelManager(modelsRoot: modelRoot),
            hotkey: HotkeyService(registersGlobalHotkeys: false),
            usageStats: UsageStatsStore(fileURL: temporary.appendingPathComponent("stats.json")), defaults: defaults)
        state.modelManager.selectCleanup(.gemma)
        guard state.modelManager.cleanupMode == .gemma else { fatalError("Install Gemma explicitly before this opt-in diagnostic") }
        let samples = try JSONDecoder().decode([Sample].self,
            from: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[2])))
            .filter { $0.id.hasPrefix("structured-") }
        precondition(!samples.isEmpty)
        for sample in samples {
            state.dictationRules = sample.rules ?? DictationRules()
            let clipboard = NSPasteboard.general.changeCount
            let start = Date()
            state.runFormattingTrial(sample.text)
            let deadline = Date().addingTimeInterval(130)
            while state.isFormattingTrialRunning && Date() < deadline {
                RunLoop.main.run(until: Date().addingTimeInterval(0.05))
            }
            precondition(!state.isFormattingTrialRunning && !state.updates.installationGate.isBusy)
            precondition(NSPasteboard.general.changeCount == clipboard && state.lastDictationText == nil)
            precondition(!FileManager.default.fileExists(atPath: temporary.appendingPathComponent("stats.json").path))
            let observation: [String: Any] = [
                "case": sample.id, "seconds": Date().timeIntervalSince(start),
                "output": state.formattingTrialResult ?? "<nil>",
                "actualMode": state.formattingTrialOutcome?.actualMode.rawValue ?? "<nil>",
                "reason": state.formattingTrialOutcome?.fallbackReason?.rawValue ?? "",
                "style": state.formattingTrialOutcome?.style.rawValue ?? "<nil>",
                "exact": state.formattingTrialOutcome?.exactRulesApplied ?? false
            ]
            print(String(data: try JSONSerialization.data(withJSONObject: observation, options: [.sortedKeys, .withoutEscapingSlashes]), encoding: .utf8)!)
            fflush(stdout)
            state.clearFormattingTrial()
        }
    }
}
