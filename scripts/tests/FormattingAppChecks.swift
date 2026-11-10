import AppKit
import SwiftUI
@testable import CarrotType

@MainActor private final class ThemeReading {
    var scheme: ColorScheme?
    var mounts = 0
    var unmounts = 0
}

private struct ThemeReadingView: View {
    @Environment(\.colorScheme) private var scheme
    let reading: ThemeReading
    var body: some View {
        Color.clear.frame(height: 1)
            .onAppear { reading.scheme = scheme; reading.mounts += 1 }
            .onDisappear { reading.unmounts += 1 }
            .onChange(of: scheme) { _, value in reading.scheme = value }
    }
}

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
        var checkedEngineContracts = false
        Task {
            let engine = QwenCleanupEngine()
            do {
                _ = try await engine.cleanup(text: "fixture", mode: .gemma, modelDirectory: nil, instructions: "Translate")
                preconditionFailure("Missing transform model must fail")
            } catch CleanupEngineError.modelMissing {} catch { preconditionFailure("Transform lost its localised error contract") }
            do {
                _ = try await engine.formatDictation(text: "fixture", mode: .gemma, modelDirectory: nil, rules: DictationRules())
                preconditionFailure("Missing dictation model must fail")
            } catch DictationModelFailure.modelUnavailable {} catch { preconditionFailure("Dictation lost its typed stage failure") }
            checkedEngineContracts = true
        }
        let contractDeadline = Date().addingTimeInterval(10)
        while !checkedEngineContracts && Date() < contractDeadline { RunLoop.main.run(until: Date().addingTimeInterval(0.03)) }
        precondition(checkedEngineContracts)
        print("PASS actual cleanup engine: independent transform localised-error and dictation typed-failure contracts")
        // Exercise SwiftUI's *observed* scheme in an existing native Settings host,
        // not just the AppKit preference. A nil preference alone missed the reported bug.
        state.appTheme = .system
        let systemScheme: ColorScheme = NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? .dark : .light
        let reading = ThemeReading()
        let host = NSHostingView(rootView: VStack {
            CarrotTypeSettingsView().environmentObject(state).environment(\.locale, state.effectiveLocale)
            ThemeReadingView(reading: reading)
        })
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 720, height: 520),
                              styleMask: [.titled], backing: .buffered, defer: false)
        window.contentView = host
        func settleTheme() {
            host.layoutSubtreeIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.25))
        }
        settleTheme()
        for theme in [AppTheme.light, .system, .dark, .system, .light, .dark, .system] {
            state.appTheme = theme
            settleTheme()
            let expected: ColorScheme = theme == .system ? systemScheme : (theme == .light ? .light : .dark)
            precondition(reading.scheme == expected, "SwiftUI did not follow \(theme)")
            precondition(window.appearance == nil, "Window must inherit the application's appearance")
            precondition(defaults.string(forKey: AppTheme.defaultsKey) == theme.rawValue)
            precondition(reading.mounts == 1 && reading.unmounts == 0, "Theme changes must not remount Settings")
        }
        precondition(NSApp.appearance == nil)
        window.contentView = nil
        print("PASS native Settings host: repeated Light/Dark → System reaches inherited SwiftUI scheme without remount")
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
        var exactRules = DictationRules()
        exactRules.removedWords = "ну"; exactRules.lowercase = true; exactRules.omitFinalPeriod = true
        exactRules.businessStyle = true
        state.dictationRules = exactRules
        for mode in [CleanupMode.off, .light, .gemma] {
            state.modelManager.selectCleanup(mode)
            state.runFormattingTrial("Ну, Нам нужен Отчёт.")
            let exactDeadline = Date().addingTimeInterval(15)
            while state.isFormattingTrialRunning && Date() < exactDeadline { RunLoop.main.run(until: Date().addingTimeInterval(0.03)) }
            precondition(!state.isFormattingTrialRunning && !state.updates.installationGate.isBusy)
            precondition(state.formattingTrialResult == "нам нужен отчёт" && state.formattingTrialOutcome?.exactRulesApplied == true)
            precondition(state.formattingTrialOutcome?.style == (mode.usesMLXHelper ? .failed : .unavailable))
            state.clearFormattingTrial()
        }
        state.dictationRules = DictationRules()
        print("PASS actual AppState exact rules: Off/Light/failing-model share final controls, stage outcome and preserved lease")
        var firstLetter = DictationRules()
        firstLetter.lowercaseFirstLetter = true
        state.dictationRules = firstLetter
        state.modelManager.selectCleanup(.light)
        state.runFormattingTrial("Привет, Анна. Проверим CarrotType.")
        let firstDeadline = Date().addingTimeInterval(10)
        while state.isFormattingTrialRunning && Date() < firstDeadline { RunLoop.main.run(until: Date().addingTimeInterval(0.03)) }
        precondition(!state.isFormattingTrialRunning && !state.updates.installationGate.isBusy)
        precondition(state.formattingTrialResult == "привет, Анна. Проверим CarrotType.")
        precondition(state.formattingTrialOutcome?.exactRulesApplied == true)
        precondition(DictationRules.load(defaults: defaults).lowercaseFirstLetter)
        state.clearFormattingTrial()
        state.dictationRules = DictationRules()
        print("PASS actual first-letter trial: persisted switch, only initial letter changes, rest of case preserved")
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
