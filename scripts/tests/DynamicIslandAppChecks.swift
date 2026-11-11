import AppKit
import SwiftUI
@testable import CarrotType

@MainActor
private final class FakeDictationSession {
    var calls: [String] = []
    var configurations: [DictationSessionSettings] = []
    var previewStarts = 0
    var previewUpdates = 0
    var processCalls = 0
    var previewUpdate: ((String, String) -> Void)?
    var processResult = FormattedDictation(
        text: "fixture",
        formatting: FormattingOutcome(requestedMode: .light, actualMode: .light, fallbackReason: nil)
    )
    let audioURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString + ".wav")

    func dependencies() -> AppDictationSession.Dependencies {
        .init(
            startCapture: { [self] configuration, _ in
                configurations.append(configuration)
                calls.append("start")
            },
            stopCapture: { [self] in
                calls.append("stop")
                try Data("audio fixture".utf8).write(to: audioURL)
                return DictationCapture(url: audioURL, duration: 1.5)
            },
            cancelCapture: { [self] in calls.append("cancelCapture") },
            unmute: { [self] _ in calls.append("unmute") },
            restoreMute: { [self] in calls.append("restore") },
            wantsPreview: { [self] configuration in
                calls.append("wantsPreview")
                return configuration.liveDraft
            },
            startPreview: { [self] _, update in
                previewStarts += 1
                previewUpdate = update
                calls.append("preview")
                update("hello", "world")
                return true
            },
            attachPreview: { _ in },
            stopPreview: { [self] in calls.append("stopPreview") },
            process: { [self] _, _, _ in
                processCalls += 1
                calls.append("process")
                return processResult
            },
            unload: { [self] in calls.append("unload") }
        )
    }
}

@main
struct DynamicIslandAppChecks {
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

    @MainActor private static func pump(_ interval: TimeInterval = 0.15) {
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
        precondition(bundleID.contains(".update-test.dynamic-island."))
        defer { defaults.removePersistentDomain(forName: bundleID) }
        defaults.set(true, forKey: "carrottype.didCompleteFirstRun")

        let fake = FakeDictationSession()
        let state = AppState(
            modelManager: ModelManager(modelsRoot: fixture.appendingPathComponent("models")),
            hotkey: HotkeyService(registersGlobalHotkeys: false),
            usageStats: UsageStatsStore(fileURL: fixture.appendingPathComponent("stats.json")),
            defaults: defaults,
            sessionDependenciesFactory: { fake.dependencies() }
        )

        // Sidebar order and localized titles.
        precondition(SettingsPane.allCases == [.general, .dynamicIsland, .setup, .models, .storage, .statistics])
        for locale in [Locale(identifier: "ru"), Locale(identifier: "en")] {
            for pane in SettingsPane.allCases { precondition(!pane.title(locale: locale).isEmpty) }
            for mode in DynamicIslandMode.allCases {
                precondition(!mode.title(locale: locale).isEmpty)
                precondition(!mode.detail(locale: locale).isEmpty)
            }
        }
        print("PASS settings: Dynamic Island directly after General, all six panes localized RU/EN")

        // Preference survives reload; the moved live-draft switch keeps its exact key/value.
        state.dynamicIslandMode = .minimal
        precondition(defaults.string(forKey: DynamicIslandMode.defaultsKey) == "minimal")
        state.liveDraftEnabled = true
        precondition(defaults.bool(forKey: "carrottype.liveDraftEnabled"))
        state.dynamicIslandMode = .full
        pump(0.05)
        precondition(state.liveDraftEnabled && defaults.bool(forKey: "carrottype.liveDraftEnabled"))
        let restored = AppState(
            modelManager: ModelManager(modelsRoot: fixture.appendingPathComponent("models")),
            hotkey: HotkeyService(registersGlobalHotkeys: false),
            usageStats: UsageStatsStore(fileURL: fixture.appendingPathComponent("stats.json")),
            defaults: defaults
        )
        precondition(restored.dynamicIslandMode == .full && restored.liveDraftEnabled)
        defaults.set("invalid-island", forKey: DynamicIslandMode.defaultsKey)
        let invalid = AppState(
            modelManager: ModelManager(modelsRoot: fixture.appendingPathComponent("models")),
            hotkey: HotkeyService(registersGlobalHotkeys: false),
            usageStats: UsageStatsStore(fileURL: fixture.appendingPathComponent("stats.json")),
            defaults: defaults
        )
        precondition(invalid.dynamicIslandMode == .full)
        print("PASS preference: absent/invalid → full, mode and live-draft value persist, switch value never reset")

        // Full session captures preview on; mid-session changes do not alter this session.
        state.dynamicIslandMode = .full
        state.liveDraftEnabled = true
        let previewBeforeFull = fake.previewStarts
        precondition(state.startDictationSession(destination: .caret))
        waitUntil("full recording") { state.dictationSessionPhase == .recording && state.capsulePhase == .listening }
        waitUntil("preview text") { state.liveDraftConfirmed == "hello" }
        precondition(fake.configurations.last?.liveDraft == true)
        precondition(fake.previewStarts == previewBeforeFull + 1)
        precondition(state.activeDictationMode == .full)
        precondition(state.islandPresentation == .full)
        precondition(state.isStatusPanelVisible)

        state.dynamicIslandMode = .minimal
        state.liveDraftEnabled = false
        pump(0.2)
        precondition(state.activeDictationMode == .full)
        precondition(state.capsulePhase == .listening)
        precondition(state.islandPresentation == .full)
        precondition(state.isStatusPanelVisible)
        precondition(fake.previewStarts == previewBeforeFull + 1, "A live setting change must not start a second preview")
        NotificationCenter.default.post(name: NSApplication.didChangeScreenParametersNotification, object: nil)
        pump(0.1)
        precondition(state.isStatusPanelVisible, "Screen change must keep a captured full session visible")

        await state.cancelDictationSession()
        waitUntil("full cancel result") {
            state.dictationSessionPhase == .idle && state.capsulePhase == .liveDraftResult
        }
        precondition(state.transformResultText == "hello world")
        precondition(state.islandPresentation == .full)
        state.dismissLiveDraftResult()
        pump(0.05)
        print("PASS full session snapshot: mid-session mode/switch changes keep full chrome and copy snapshot")

        // Minimal session: no preview invocation; Escape has no draft/Copy result.
        state.dynamicIslandMode = .minimal
        state.liveDraftEnabled = true
        let previewBeforeMinimal = fake.previewStarts
        precondition(state.startDictationSession(destination: .caret))
        waitUntil("minimal recording") { state.dictationSessionPhase == .recording && state.capsulePhase == .listening }
        precondition(fake.configurations.last?.liveDraft == false)
        precondition(fake.previewStarts == previewBeforeMinimal, "Minimal must not invoke preview at all")
        precondition(state.activeDictationMode == .minimal)
        precondition(state.islandPresentation == .minimal)
        precondition(state.isStatusPanelVisible)
        pump(0.2)
        precondition(fake.previewStarts == previewBeforeMinimal)
        await state.cancelDictationSession()
        waitUntil("minimal cancel") { state.dictationSessionPhase == .idle }
        precondition(state.capsulePhase == nil)
        precondition(!state.isStatusPanelVisible)
        print("PASS minimal session: zero preview starts, recording indicator shown, Escape cancels without Copy")

        // Menu-bar-only: logical listening/processing stay, no panel from screen changes.
        state.dynamicIslandMode = .menuOnly
        let previewBeforeMenu = fake.previewStarts
        precondition(state.startDictationSession(destination: .caret))
        waitUntil("menu recording") { state.dictationSessionPhase == .recording && state.capsulePhase == .listening }
        precondition(fake.configurations.last?.liveDraft == false)
        precondition(fake.previewStarts == previewBeforeMenu)
        precondition(state.islandPresentation == .hidden)
        precondition(!state.isStatusPanelVisible)
        NotificationCenter.default.post(name: NSApplication.didChangeScreenParametersNotification, object: nil)
        pump(0.15)
        precondition(state.capsulePhase == .listening, "Logical phase must not be erased to hide UI")
        precondition(!state.isStatusPanelVisible, "Screen change must not resurrect a suppressed panel")
        await state.cancelDictationSession()
        waitUntil("menu cancel") { state.dictationSessionPhase == .idle }
        precondition(state.capsulePhase == nil)
        print("PASS menu-only session: zero preview starts, no status panel, screen changes stay hidden")

        // Transform status/result (and recovery) remain full in menu-only.
        state.beginTransformPresentation()
        precondition(state.capsulePhase == .understanding)
        precondition(state.islandPresentation == .full)
        pump(0.1)
        precondition(state.isStatusPanelVisible)
        state.presentTransformResult("translated", direction: "EN → RU")
        precondition(state.capsulePhase == .transformResult)
        precondition(state.islandPresentation == .full)
        pump(0.1)
        precondition(state.isStatusPanelVisible)
        state.dismissTransformResult()
        state.endTransformPresentation()
        pump(0.05)
        precondition(!state.isStatusPanelVisible)
        state.presentDictationRecovery("recover me")
        precondition(state.capsulePhase == .dictationRecovery)
        precondition(state.islandPresentation == .full)
        pump(0.1)
        precondition(state.isStatusPanelVisible)
        state.dismissTransformResult()
        pump(0.05)
        print("PASS transform/recovery: processing and Copy/Close results visible in menu-only mode")

        // Delayed old success UI cannot paint over a newer session.
        state.dynamicIslandMode = .full
        let oldSequence = Task { await state.presentSuccessCapsuleSequence(usedFormattingFallback: false) }
        waitUntil("old writing phase") { state.capsulePhase == .writing }
        precondition(state.startDictationSession(destination: .caret))
        waitUntil("new recording during old sequence") { state.dictationSessionPhase == .recording }
        pump(0.5)
        precondition(state.capsulePhase == .listening, "Old delayed callback must not replace the new session UI")
        await oldSequence.value
        precondition(state.capsulePhase == .listening)
        await state.cancelDictationSession()
        waitUntil("new session cancel") { state.dictationSessionPhase == .idle }
        print("PASS delayed sequence: stale Writing/Inserted tokens are invalidated by the next session")

        // Empty result with a real fallback stays in RAM and drives the suppressed-panel warning.
        state.dynamicIslandMode = .minimal
        state.liveDraftEnabled = false
        fake.processResult = FormattedDictation(
            text: "",
            formatting: FormattingOutcome(
                requestedMode: .gemma,
                actualMode: .light,
                fallbackReason: .modelUnavailable
            )
        )
        precondition(state.startDictationSession(destination: .caret))
        waitUntil("fallback recording") { state.dictationSessionPhase == .recording }
        state.finishDictationSession()
        waitUntil("fallback delivery") { state.dictationSessionPhase == .idle }
        precondition(state.lastFormattingOutcome?.usedFallback == true)
        precondition(state.lastDictationIslandMode == .minimal)
        precondition(state.showsSuppressedFallbackWarning)
        // The warning refers to the last completed dictation, not the newly selected mode.
        state.dynamicIslandMode = .full
        precondition(state.showsSuppressedFallbackWarning)
        precondition(state.lastFormattingOutcome?.actualMode == .light)

        // A full-capsule session already announced fallback, so the menu does not duplicate it.
        precondition(state.startDictationSession(destination: .caret))
        waitUntil("full fallback recording") { state.dictationSessionPhase == .recording }
        state.finishDictationSession()
        waitUntil("full fallback delivery") { state.dictationSessionPhase == .idle }
        precondition(state.lastDictationIslandMode == .full)
        precondition(!state.showsSuppressedFallbackWarning)
        precondition(state.lastFormattingOutcome?.usedFallback == true)
        print("PASS fallback signaling: warning follows the captured last-session mode, not the current setting")

        // Native offscreen visual evidence: real Settings pane and real minimal components.
        try renderNativeEvidence(state: state, output: output)
        precondition(state.lastDictationText == nil)
        precondition(!FileManager.default.fileExists(atPath: fixture.appendingPathComponent("stats.json").path))
        print("PASS no clipboard/history/statistics side effects in these checks")
    }

    @MainActor
    private static func renderNativeEvidence(state: AppState, output: URL) throws {
        let snapshots = output.appendingPathComponent("native")
        try FileManager.default.createDirectory(at: snapshots, withIntermediateDirectories: true)
        // Show the saved switch ON; non-Full renders must show it disabled without resetting it.
        state.liveDraftEnabled = true

        // Actual Settings shell at the documented minimum window size (720×520), with
        // Dynamic Island selected. The 200 pt sidebar leaves about 519 pt for the real pane.
        var renderedBottomScroll = false
        for (language, code) in [(AppLanguage.russian, "ru"), (AppLanguage.english, "en")] {
            for theme in [AppTheme.light, .dark] {
                for mode in DynamicIslandMode.allCases {
                    state.appLanguage = language
                    state.appTheme = theme
                    state.dynamicIslandMode = mode
                    let view = CarrotTypeSettingsView(initialPane: .dynamicIsland)
                        .environmentObject(state)
                        .environment(\.locale, language.effectiveLocale)
                    let name = "settings-\(code)-\(theme.rawValue)-\(mode.rawValue)"
                    let info = try render(
                        view: view,
                        size: NSSize(width: 720, height: 520),
                        appearance: theme.appearance,
                        to: snapshots.appendingPathComponent("\(name).png")
                    )
                    precondition(info.found, "Whole Settings shell must expose its Form scroll container at minimum size")
                    print("LAYOUT \(name) overflow=\(info.overflow)")
                    if info.overflow > 0, !renderedBottomScroll {
                        let bottom = try render(
                            view: CarrotTypeSettingsView(initialPane: .dynamicIsland)
                                .environmentObject(state)
                                .environment(\.locale, language.effectiveLocale),
                            size: NSSize(width: 720, height: 520),
                            appearance: theme.appearance,
                            scrollToBottom: true,
                            to: snapshots.appendingPathComponent("\(name)-bottom.png")
                        )
                        precondition(bottom.found)
                        renderedBottomScroll = true
                    }
                }
            }
        }
        state.dynamicIslandMode = .full

        // Real minimal-indicator components at native geometry (offscreen, not a device screenshot).
        let geometry = StatusCapsuleGeometry.preferred()
        let notchedSize = geometry.panelSize(for: .listening, presentation: .minimal)
        let notch = ZStack(alignment: .top) {
            Color(white: 0.16)
            VStack(spacing: 0) {
                Rectangle().fill(Color.black).frame(width: geometry.hasNotch ? geometry.notchWidth : 110,
                                                    height: max(geometry.notchHeight, 22))
                DynamicIslandRootView(
                    presentation: .minimal,
                    phase: .listening,
                    resultText: "",
                    direction: nil,
                    copiedFeedback: false,
                    topInset: 0,
                    minimalBarWidth: geometry.minimalBarWidth,
                    locale: Locale(identifier: "en"),
                    onCopy: {},
                    onClose: {}
                )
                .frame(width: notchedSize.width, height: notchedSize.height - max(geometry.notchHeight, 22))
            }
        }
        .frame(width: max(notchedSize.width, 220), height: max(notchedSize.height, 58))
        try render(
            view: notch,
            size: NSSize(width: max(notchedSize.width, 220), height: max(notchedSize.height, 54)),
            appearance: nil,
            to: snapshots.appendingPathComponent("minimal-recording-native-geometry.png")
        )

        try render(
            view: HStack(spacing: 6) {
                ProcessingDots(diameter: MinimalIslandMetrics.dotDiameter,
                               spacing: MinimalIslandMetrics.dotSpacing,
                               ink: .orange)
            }
            .frame(width: MinimalIslandMetrics.nonNotchPanelSize.width,
                   height: MinimalIslandMetrics.nonNotchPanelSize.height)
            .background(Color(white: 0.16)),
            size: MinimalIslandMetrics.nonNotchPanelSize,
            appearance: nil,
            to: snapshots.appendingPathComponent("minimal-processing-non-notch.png")
        )
        print("SNAPSHOTS \(snapshots.path)")
        print("GEOMETRY notched=\(geometry.hasNotch) notch=\(geometry.notchWidth)x\(geometry.notchHeight) bar=\(geometry.minimalBarWidth)")
    }

    private struct ScrollInfo {
        let found: Bool
        let overflow: CGFloat
    }

    @MainActor
    @discardableResult
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
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        host.layoutSubtreeIfNeeded()
        let info = scrollInfo(in: host)
        if scrollToBottom, info.overflow > 0 {
            _ = scrollSettingsToBottom(in: host)
            host.layoutSubtreeIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.15))
        }
        guard let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds) else {
            preconditionFailure("No bitmap for native snapshot")
        }
        host.cacheDisplay(in: host.bounds, to: rep)
        guard let data = rep.representation(using: .png, properties: [:]) else {
            preconditionFailure("No PNG for native snapshot")
        }
        try data.write(to: url)
        window.contentView = nil
        return info
    }

    @MainActor
    private static func deepestScroll(in view: NSView) -> NSScrollView? {
        var first: NSScrollView?
        var best: NSScrollView?
        var bestOverflow: CGFloat = 0
        func visit(_ current: NSView) {
            if let scroll = current as? NSScrollView, let document = scroll.documentView {
                if first == nil { first = scroll }
                let overflow = document.frame.height - scroll.contentView.bounds.height
                if overflow > bestOverflow {
                    bestOverflow = overflow
                    best = scroll
                }
            }
            current.subviews.forEach(visit)
        }
        visit(view)
        return best ?? first
    }

    @MainActor
    private static func scrollInfo(in view: NSView) -> ScrollInfo {
        guard let scroll = deepestScroll(in: view), let document = scroll.documentView else {
            return ScrollInfo(found: false, overflow: 0)
        }
        return ScrollInfo(
            found: true,
            overflow: max(0, document.frame.height - scroll.contentView.bounds.height)
        )
    }

    @MainActor
    private static func scrollSettingsToBottom(in view: NSView) -> Bool {
        guard let scroll = deepestScroll(in: view), let document = scroll.documentView else {
            return false
        }
        let maxY = max(0, document.frame.height - scroll.contentView.bounds.height)
        scroll.contentView.scroll(to: NSPoint(x: 0, y: maxY))
        scroll.reflectScrolledClipView(scroll.contentView)
        if maxY > 0 {
            precondition(scroll.contentView.bounds.origin.y > 0, "Settings content did not scroll to the bottom")
        }
        return true
    }
}