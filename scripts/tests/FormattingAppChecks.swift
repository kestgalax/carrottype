import AppKit
import SwiftUI
@testable import CarrotType

@main struct FormattingAppChecks {
    @MainActor static func main() throws {
        let nsApp = NSApplication.shared
        nsApp.setActivationPolicy(.prohibited)
        let output = URL(fileURLWithPath: CommandLine.arguments[1])
        let fixture = output.appendingPathComponent("fixture")
        let defaults = UserDefaults.standard // Unique staging bundle ID, never production defaults.
        precondition(Bundle.main.bundleIdentifier!.contains(".update-test.formatting."))
        defer { defaults.removePersistentDomain(forName: Bundle.main.bundleIdentifier!) }
        defaults.set(true, forKey: "carrottype.didCompleteFirstRun")
        let modelRoot = fixture.appendingPathComponent("models")
        for mode in [CleanupMode.smart, .smartPlus, .gemma] {
            let package = BundledModelCatalog.fallback.packages.first { $0.id == mode.requiredPackageID }!
            let dir = modelRoot.appendingPathComponent(package.id)
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            try Data("{}".utf8).write(to: dir.appendingPathComponent("config.json"))
            try Data().write(to: dir.appendingPathComponent("fixture.safetensors"))
            try Data(package.hubRevision!.utf8).write(to: dir.appendingPathComponent(".hub-revision"))
        }
        defaults.set("smartPlus", forKey: "carrottype.cleanupMode")
        var legacyBinding = TransformBinding.makeDefault(cleanupMode: .smartPlus)
        legacyBinding.customInstruction = "fixture"
        TransformBindingsStore.save([legacyBinding], defaults: defaults)
        let state = AppState(
            modelManager: ModelManager(modelsRoot: fixture.appendingPathComponent("models")),
            hotkey: HotkeyService(registersGlobalHotkeys: false),
            usageStats: UsageStatsStore(fileURL: fixture.appendingPathComponent("stats.json")),
            defaults: defaults
        )
        precondition(state.modelManager.cleanupMode == .smartPlus)
        precondition(state.modelManager.status(for: BundledModelCatalog.smartPlusCleanupID).isReady)
        precondition(state.modelManager.selectableCleanupModes.contains(.smartPlus))
        precondition(!state.selectableTransformModes.contains(.smartPlus))
        precondition(state.transformModes(for: .smartPlus).contains(.smartPlus))
        precondition(!state.transformModes(for: .smart).contains(.smartPlus))
        precondition(state.preferredTransformCleanupMode() == .smart)
        state.modelManager.selectCleanup(.light)
        state.modelManager.selectCleanup(.smartPlus)
        precondition(state.modelManager.cleanupMode == .light && !state.modelManager.selectableCleanupModes.contains(.smartPlus))
        precondition(state.modelManager.installedPackageFootprints.contains { $0.id == BundledModelCatalog.smartPlusCleanupID })
        print("PASS actual ModelManager/AppState: ready legacy survives restore, binding-specific availability, no new/fallback recommendation, retained Storage")
        state.appTheme = .dark
        precondition(NSApp.appearance?.name == .darkAqua && defaults.string(forKey: AppTheme.defaultsKey) == "dark")
        state.appTheme = .light
        precondition(NSApp.appearance?.name == .aqua)
        state.appTheme = .system
        precondition(NSApp.appearance == nil)
        var rules = state.dictationRules; rules.customRules = "Keep CarrotType"; state.dictationRules = rules
        precondition(DictationRules.load(defaults: defaults).customRules == "Keep CarrotType")
        let beforeClipboard = NSPasteboard.general.changeCount
        state.runFormattingTrial("I like this design\nSecond line")
        precondition(state.isFormattingTrialRunning && state.updates.installationGate.isBusy && !state.canRunFormattingTrial)
        let deadline = Date().addingTimeInterval(10)
        while state.isFormattingTrialRunning && Date() < deadline { RunLoop.main.run(until: Date().addingTimeInterval(0.03)) }
        precondition(!state.isFormattingTrialRunning && !state.updates.installationGate.isBusy)
        precondition(state.formattingTrialResult == "I like this design\nSecond line")
        precondition(state.lastDictationText == nil && NSPasteboard.general.changeCount == beforeClipboard)
        precondition(!FileManager.default.fileExists(atPath: fixture.appendingPathComponent("stats.json").path))
        state.clearFormattingTrial()
        print("PASS actual trial lease, output, no clipboard/history/statistics writes; live theme and rules persistence")
        // Missing/invalid local fixture model must fall back, never publish partial output.
        state.modelManager.selectCleanup(.gemma)
        state.runFormattingTrial("Ну ты и молодец")
        let fallbackDeadline = Date().addingTimeInterval(15)
        while state.isFormattingTrialRunning && Date() < fallbackDeadline { RunLoop.main.run(until: Date().addingTimeInterval(0.03)) }
        precondition(!state.isFormattingTrialRunning && state.formattingTrialOutcome?.usedFallback == true)
        precondition(state.formattingTrialResult == "Ну ты и молодец")
        state.clearFormattingTrial()
        state.modelManager.selectCleanup(.light)
        state.runFormattingTrial("cancelled fixture")
        state.cancelFormattingTrial()
        precondition(state.updates.installationGate.isBusy)
        let cancelDeadline = Date().addingTimeInterval(10)
        while state.isFormattingTrialRunning && Date() < cancelDeadline { RunLoop.main.run(until: Date().addingTimeInterval(0.03)) }
        precondition(!state.isFormattingTrialRunning && !state.updates.installationGate.isBusy && state.formattingTrialResult == nil)
        let lease = state.updates.installationGate.beginOperation()!
        state.runFormattingTrial("blocked fixture")
        precondition(!state.isFormattingTrialRunning)
        state.updates.installationGate.endOperation(lease)
        precondition(state.lastDictationText == nil && NSPasteboard.general.changeCount == beforeClipboard)
        precondition(!FileManager.default.fileExists(atPath: fixture.appendingPathComponent("stats.json").path))
        print("PASS actual trial fallback/cancellation/busy admission; lease survives until task teardown")
    }
}
