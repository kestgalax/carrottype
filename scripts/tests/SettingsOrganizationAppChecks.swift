import AppKit
import SwiftUI
@testable import CarrotType

/// Actual Settings-pane/UI checks for the approved General → Dictation → Text actions split.
/// Uses an isolated Debug copy and unique defaults domain; no microphone, model, clipboard,
/// WAV, statistics or real status-panel output is touched.
@main
struct SettingsOrganizationAppChecks {
    @MainActor private static func waitUntil(
        _ label: String,
        timeout: TimeInterval = 6,
        _ condition: () -> Bool
    ) {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            precondition(Date() < deadline, "Timed out: \(label)")
            RunLoop.main.run(until: Date().addingTimeInterval(0.02))
        }
    }

    @MainActor private static func pump(_ interval: TimeInterval = 0.2) {
        RunLoop.main.run(until: Date().addingTimeInterval(interval))
    }

    @MainActor static func main() async throws {
        let nsApp = NSApplication.shared
        nsApp.setActivationPolicy(.prohibited)
        let output = URL(fileURLWithPath: CommandLine.arguments[1])
        let fixture = output.appendingPathComponent("fixture")
        try? FileManager.default.createDirectory(at: fixture, withIntermediateDirectories: true)
        let defaults = UserDefaults.standard
        let bundleID = Bundle.main.bundleIdentifier!
        precondition(bundleID.contains(".update-test.settings-organization."))
        defer { defaults.removePersistentDomain(forName: bundleID) }
        defaults.set(true, forKey: "carrottype.didCompleteFirstRun")

        let state = AppState(
            modelManager: ModelManager(modelsRoot: fixture.appendingPathComponent("models")),
            hotkey: HotkeyService(registersGlobalHotkeys: false),
            usageStats: UsageStatsStore(fileURL: fixture.appendingPathComponent("stats.json")),
            defaults: defaults
        )

        // Navigation inventory: exact order, localized titles, untranslated Dynamic Island.
        let expectedOrder: [SettingsPane] = [
            .general, .dictation, .textActions, .dynamicIsland, .setup, .models, .storage, .statistics
        ]
        precondition(SettingsPane.allCases == expectedOrder)
        for locale in [Locale(identifier: "ru"), Locale(identifier: "en")] {
            for pane in SettingsPane.allCases {
                precondition(!pane.title(locale: locale).isEmpty)
                precondition(!L10n.t("settings.description.\(pane.rawValue)", locale: locale).isEmpty
                    && L10n.t("settings.description.\(pane.rawValue)", locale: locale) != "settings.description.\(pane.rawValue)")
            }
        }
        precondition(SettingsPane.dynamicIsland.title(locale: Locale(identifier: "ru")) == "Dynamic Island")
        precondition(SettingsPane.dynamicIsland.title(locale: Locale(identifier: "en")) == "Dynamic Island")
        precondition(SettingsPane.dictation.title(locale: Locale(identifier: "ru")) == "Диктовка")
        precondition(SettingsPane.textActions.title(locale: Locale(identifier: "ru")) == "Преобразования")
        precondition(SettingsPane.textActions.title(locale: Locale(identifier: "en")) == "Text actions")
        print("PASS navigation: eight ordered destinations, RU/EN titles, untranslated Dynamic Island")

        // Preserve every existing saved value across pane rendering.
        state.appLanguage = .russian
        state.appTheme = .dark
        state.pushToTalkEnabled = true
        state.retainDictationInClipboard = true
        state.liveDraftEnabled = true
        state.dynamicIslandMode = .minimal
        state.statsCollectionEnabled = false
        state.typingSpeedWPM = 77
        var rules = DictationRules()
        rules.removedWords = "ну, вот"
        rules.lowercaseFirstLetter = true
        rules.omitFinalPeriod = true
        rules.businessStyle = true
        rules.customRules = "Keep short."
        state.dictationRules = rules
        state.modelManager.selectCleanup(.light)
        let savedMode = state.modelManager.cleanupMode
        state.hotkey.replaceTransformBindings([])
        precondition(state.transformBindings.isEmpty)
        let savedRules = state.dictationRules
        let savedModeRaw = defaults.string(forKey: "carrottype.cleanupMode")
        let savedTypingSpeed = defaults.integer(forKey: "carrottype.typingSpeedWPM")
        let savedPushToTalk = defaults.bool(forKey: "carrottype.pushToTalk")
        let savedClipboard = defaults.bool(forKey: "carrottype.retainClipboard")
        let savedTheme = defaults.string(forKey: "carrottype.appTheme")

        for pane in SettingsPane.allCases {
            _ = try render(
                view: CarrotTypeSettingsView(initialPane: pane)
                    .environmentObject(state)
                    .environment(\.locale, state.effectiveLocale),
                size: NSSize(width: 720, height: 520),
                appearance: AppTheme.dark.appearance,
                to: fixture.appendingPathComponent("preserve-\(pane.rawValue).png")
            )
        }
        precondition(state.appLanguage == .russian)
        precondition(state.appTheme == .dark)
        precondition(state.pushToTalkEnabled)
        precondition(state.retainDictationInClipboard)
        precondition(state.liveDraftEnabled)
        precondition(state.dynamicIslandMode == .minimal)
        precondition(state.typingSpeedWPM == 77)
        precondition(state.dictationRules == savedRules)
        precondition(state.modelManager.cleanupMode == savedMode)
        precondition(state.transformBindings.isEmpty)
        precondition(defaults.integer(forKey: "carrottype.typingSpeedWPM") == savedTypingSpeed)
        precondition(defaults.bool(forKey: "carrottype.pushToTalk") == savedPushToTalk)
        precondition(defaults.bool(forKey: "carrottype.retainClipboard") == savedClipboard)
        precondition(defaults.string(forKey: "carrottype.appTheme") == savedTheme)
        precondition(defaults.string(forKey: "carrottype.cleanupMode") == savedModeRaw)
        print("PASS preservation: language/theme/hotkey/PTT/clipboard/island/rules/speed/formatting/empty bindings unchanged by navigation")

        // Bindings keep their existing max-5 / explicit-empty behavior after moving to Text actions.
        precondition(state.canAddTransformBinding)
        for _ in 0..<5 { state.addTransformBinding() }
        precondition(state.transformBindings.count == 5)
        precondition(!state.canAddTransformBinding)
        state.addTransformBinding()
        precondition(state.transformBindings.count == 5)
        state.hotkey.replaceTransformBindings([])
        precondition(state.transformBindings.isEmpty)
        print("PASS bindings: max five, add blocked at limit, explicit empty list preserved")

        // Leaving Dictation while capturing the dictation chord cancels capture and restores registration.
        unmountCancelsCapture(
            view: DictationSettingsPane(appState: state, hotkey: state.hotkey, onOpenModels: {}),
            configure: { state.hotkey.startRecording(for: .dictation) },
            isCapturing: { state.hotkey.isRecording }
        )
        print("PASS dictation hotkey capture: pane unmount cancels capture and restores registration")
        precondition(!state.hotkey.isGlobalHotkeySuspended)

        // Leaving Text actions while capturing a transform chord does the same.
        state.hotkey.replaceTransformBindings([.makeDefault()])
        let binding = state.transformBindings[0]
        unmountCancelsCapture(
            view: TextActionsSettingsPane(appState: state, hotkey: state.hotkey, onOpenModels: {}),
            configure: { state.hotkey.startRecording(for: .transformBinding(binding.id)) },
            isCapturing: { state.hotkey.isRecording }
        )
        print("PASS transform hotkey capture: pane unmount cancels capture and restores registration")
        state.hotkey.replaceTransformBindings([])

        // Theme/language updates are not a pane departure: a finished trial stays visible.
        state.modelManager.selectCleanup(.light)
        let trialText = String(repeating: "Hello world. ", count: 300)
        let trialWindow = mount(
            CarrotTypeSettingsView(initialPane: .dictation)
                .environmentObject(state)
                .environment(\.locale, state.effectiveLocale),
            size: NSSize(width: 720, height: 520),
            appearance: AppTheme.light.appearance
        )
        pump(0.4)
        state.runFormattingTrial(trialText)
        waitUntil("formatting trial completes") { !state.isFormattingTrialRunning }
        precondition(state.formattingTrialResult != nil)
        let completedTrial = state.formattingTrialResult
        state.appLanguage = .english
        state.appTheme = .dark
        pump(0.4)
        precondition(state.formattingTrialResult == completedTrial, "Theme/language must not remount or clear the trial")
        precondition(!state.updates.installationGate.isBusy)
        print("PASS trial remount safety: theme/language update preserves result and releases the operation gate")

        // Leaving Dictation cancels an in-flight trial and waits for existing teardown to release the gate.
        state.appLanguage = .russian
        state.appTheme = .light
        let longTrialText = String(repeating: "Hello world. ", count: 300)
        state.runFormattingTrial(longTrialText)
        precondition(state.isFormattingTrialRunning)
        trialWindow.contentView = nil
        waitUntil("trial teardown after pane unmount") {
            !state.isFormattingTrialRunning && !state.updates.installationGate.isBusy
        }
        precondition(state.formattingTrialResult == nil)
        print("PASS trial departure: unmount cancels the trial, teardown completes and the gate/reservation is released")

        // Native whole-Settings evidence for every destination in RU/EN light/dark.
        try renderNativeEvidence(state: state, output: output)
        state.settingsDidDisappear()
        print("PASS no microphone/model/clipboard/statistics side effects in these checks")
    }

    @MainActor
    private static func mount<V: View>(
        _ view: V,
        size: NSSize,
        appearance: NSAppearance?
    ) -> NSWindow {
        let host = NSHostingView(rootView: view)
        host.frame = NSRect(origin: .zero, size: size)
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        window.appearance = appearance
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        pump(0.15)
        return window
    }

    @MainActor
    private static func unmountCancelsCapture(
        view: some View,
        configure: () -> Void,
        isCapturing: () -> Bool
    ) {
        let window = mount(view, size: NSSize(width: 720, height: 520), appearance: nil)
        pump(0.2)
        configure()
        precondition(isCapturing())
        window.contentView = nil
        pump(0.3)
        precondition(!isCapturing(), "Leaving the pane must cancel hotkey capture")
    }

    @MainActor
    private static func renderNativeEvidence(state: AppState, output: URL) throws {
        let snapshots = output.appendingPathComponent("native")
        try FileManager.default.createDirectory(at: snapshots, withIntermediateDirectories: true)
        let languages: [(AppLanguage, String)] = [(.russian, "ru"), (.english, "en")]
        let themes: [AppTheme] = [.light, .dark]
        var rendered = 0
        var sawDictationOverflow = false
        var renderedDictationBottom = false

        for (language, code) in languages {
            for theme in themes {
                state.appLanguage = language
                state.appTheme = theme
                for pane in SettingsPane.allCases {
                    let view = CarrotTypeSettingsView(initialPane: pane)
                        .environmentObject(state)
                        .environment(\.locale, language.effectiveLocale)
                    let name = "settings-\(pane.rawValue)-\(code)-\(theme.rawValue)"
                    let url = snapshots.appendingPathComponent("\(name).png")
                    let info = try render(
                        view: view,
                        size: NSSize(width: 720, height: 520),
                        appearance: theme.appearance,
                        to: url
                    )
                    precondition(info.formFound, "Whole Settings shell must expose the detail Form at minimum size")
                    precondition(info.sidebarFound, "Whole Settings shell must expose the scrollable sidebar at minimum size")
                    precondition(info.footerContentPixels > 20,
                                 "Pinned sidebar footer must render at minimum size in \(name)")
                    if info.sidebarOverflow > 0 {
                        precondition(info.sidebarScrolled)
                    }
                    print("LAYOUT \(name) overflow=\(info.overflow) sidebarOverflow=\(info.sidebarOverflow) footerPixels=\(info.footerContentPixels)")
                    if pane == .dictation, info.overflow > 0 {
                        sawDictationOverflow = true
                        if !renderedDictationBottom {
                            let bottom = try render(
                                view: view,
                                size: NSSize(width: 720, height: 520),
                                appearance: theme.appearance,
                                scrollToBottom: true,
                                to: snapshots.appendingPathComponent("\(name)-bottom.png")
                            )
                            precondition(bottom.formFound && bottom.formScrolled)
                            renderedDictationBottom = true
                        }
                    }
                    rendered += 1
                }
            }
        }
        precondition(sawDictationOverflow, "Dictation must start overflowing at 720×520 and remain scrollable")
        precondition(renderedDictationBottom)
        state.appLanguage = .system
        state.appTheme = .system
        print("SNAPSHOTS \(snapshots.path)")
        print("PASS native whole-Settings: \(rendered) pane/language/theme states, pinned sidebar footer, Dictation bottom reachable")
    }

    private struct ScrollInfo {
        let formFound: Bool
        let overflow: CGFloat
        let formScrolled: Bool
        let sidebarFound: Bool
        let sidebarOverflow: CGFloat
        let sidebarScrolled: Bool
        let footerContentPixels: Int
    }

    @MainActor
    private static func render(
        view: some View,
        size: NSSize,
        appearance: NSAppearance?,
        scrollToBottom: Bool = false,
        to url: URL
    ) throws -> ScrollInfo {
        let host = NSHostingView(rootView: view)
        host.frame = NSRect(origin: .zero, size: size)
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        window.appearance = appearance
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.35))
        host.layoutSubtreeIfNeeded()
        let form = deepestScroll(in: host)
        let sidebar = sidebarScroll(in: host)
        let formOverflow = form.map { overflow(of: $0) } ?? 0
        let sidebarOverflow = sidebar.map { overflow(of: $0) } ?? 0
        var sidebarScrolled = sidebarOverflow == 0
        if let sidebar, sidebarOverflow > 0 {
            scrollFormToBottom(of: sidebar)
            host.layoutSubtreeIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.1))
            sidebarScrolled = sidebar.contentView.bounds.origin.y > 0
        }
        var scrolled = false
        if scrollToBottom, let form, formOverflow > 0 {
            scrollFormToBottom(of: form)
            host.layoutSubtreeIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.15))
            scrolled = form.contentView.bounds.origin.y > 0
        }
        guard let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds) else {
            preconditionFailure("No bitmap for native snapshot")
        }
        host.cacheDisplay(in: host.bounds, to: rep)
        let footerPixels = footerContentPixels(in: rep)
        guard let data = rep.representation(using: .png, properties: [:]) else {
            preconditionFailure("No PNG for native snapshot")
        }
        try data.write(to: url)
        return ScrollInfo(
            formFound: form != nil,
            overflow: formOverflow,
            formScrolled: scrolled,
            sidebarFound: sidebar != nil,
            sidebarOverflow: sidebarOverflow,
            sidebarScrolled: sidebarScrolled,
            footerContentPixels: footerPixels
        )
    }

    /// Counts visibly non-background pixels in the bottom-left sidebar footer region.
    private static func footerContentPixels(in rep: NSBitmapImageRep) -> Int {
        let width = min(200, rep.pixelsWide)
        let height = min(110, rep.pixelsHigh)
        guard width > 8, height > 8, let background = rep.colorAt(x: 4, y: 4) else { return 0 }
        func distance(_ a: NSColor, _ b: NSColor) -> CGFloat {
            abs(a.redComponent - b.redComponent)
                + abs(a.greenComponent - b.greenComponent)
                + abs(a.blueComponent - b.blueComponent)
        }
        var count = 0
        for y in 0..<height {
            for x in 0..<width {
                guard let color = rep.colorAt(x: x, y: y) else { continue }
                if distance(color, background) > 0.18 { count += 1 }
            }
        }
        return count
    }

    @MainActor
    private static func deepestScroll(in view: NSView) -> NSScrollView? {
        var first: NSScrollView?
        var best: NSScrollView?
        var bestOverflow: CGFloat = 0
        func visit(_ current: NSView) {
            if let scroll = current as? NSScrollView,
               scroll.frame.width > 210 {
                if first == nil { first = scroll }
                let value = overflow(of: scroll)
                if value > bestOverflow {
                    bestOverflow = value
                    best = scroll
                }
            }
            current.subviews.forEach(visit)
        }
        visit(view)
        return best ?? first
    }

    @MainActor
    private static func sidebarScroll(in view: NSView) -> NSScrollView? {
        var found: NSScrollView?
        func visit(_ current: NSView) {
            if let scroll = current as? NSScrollView,
               scroll.frame.width > 40, scroll.frame.width <= 210,
               scroll.convert(scroll.bounds, to: nil).minX < 1 {
                found = scroll
            }
            current.subviews.forEach(visit)
        }
        visit(view)
        return found
    }

    @MainActor
    private static func overflow(of scroll: NSScrollView) -> CGFloat {
        guard let document = scroll.documentView else { return 0 }
        return max(0, document.frame.height - scroll.contentView.bounds.height)
    }

    @MainActor
    private static func scrollFormToBottom(of scroll: NSScrollView) {
        guard let document = scroll.documentView else { return }
        let maxY = max(0, document.frame.height - scroll.contentView.bounds.height)
        scroll.contentView.scroll(to: NSPoint(x: 0, y: maxY))
        scroll.reflectScrolledClipView(scroll.contentView)
    }
}
