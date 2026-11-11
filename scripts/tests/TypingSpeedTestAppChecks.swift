import AppKit
import SwiftUI
@testable import CarrotType

private final class FakeClock {
    var now: TimeInterval = 0
    func read() -> TimeInterval { now }
}

@MainActor
private final class FakeDictationSession {
    var startCalls = 0
    var processCalls = 0
    let audioURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString + ".wav")

    func dependencies() -> AppDictationSession.Dependencies {
        .init(
            startCapture: { [self] _, _ in
                startCalls += 1
            },
            stopCapture: { [self] in
                try Data("audio fixture".utf8).write(to: audioURL)
                return DictationCapture(url: audioURL, duration: 1.5)
            },
            cancelCapture: {},
            unmute: { _ in },
            restoreMute: {},
            wantsPreview: { _ in false },
            startPreview: { _, _ in false },
            attachPreview: { _ in },
            stopPreview: {},
            process: { [self] _, _, _ in
                processCalls += 1
                return FormattedDictation(
                    text: "fixture",
                    formatting: FormattingOutcome(
                        requestedMode: .light,
                        actualMode: .light,
                        fallbackReason: nil
                    )
                )
            },
            unload: {}
        )
    }
}

@main
struct TypingSpeedTestAppChecks {
    @MainActor private static func pump(_ interval: TimeInterval = 0.12) {
        RunLoop.main.run(until: Date().addingTimeInterval(interval))
    }

    @MainActor static func main() async throws {
        let nsApp = NSApplication.shared
        nsApp.setActivationPolicy(.prohibited)
        let fixture = URL(fileURLWithPath: CommandLine.arguments[1])
        let snapshots = URL(fileURLWithPath: CommandLine.arguments[2])
        try? FileManager.default.createDirectory(at: fixture, withIntermediateDirectories: true)
        let defaults = UserDefaults.standard
        let bundleID = Bundle.main.bundleIdentifier!
        precondition(bundleID.contains(".update-test.typing-speed."))
        defer { defaults.removePersistentDomain(forName: bundleID) }
        defaults.set(true, forKey: "carrottype.didCompleteFirstRun")

        let fake = FakeDictationSession()
        let statsURL = fixture.appendingPathComponent("stats.json")
        let state = AppState(
            modelManager: ModelManager(modelsRoot: fixture.appendingPathComponent("models")),
            hotkey: HotkeyService(defaults: defaults, registersGlobalHotkeys: false),
            usageStats: UsageStatsStore(fileURL: statsURL),
            defaults: defaults,
            sessionDependenciesFactory: { fake.dependencies() }
        )

        precondition(!state.statsCollectionEnabled)
        precondition(!FileManager.default.fileExists(atPath: statsURL.path))
        precondition(state.canPresentTypingSpeedTest, "Text-only test must not require Readiness/models/permissions")
        precondition(state.readiness != .ready, "Fixture intentionally has no ready model")

        await coordinatorAndGateChecks(state: state)
        applyChecks(state: state, statsURL: statsURL)
        lifecycleChecks(state: state)
        inputAdapterChecks()
        await viewModelChecks(state: state, fixture: fixture)
        try await snapshotEvidence(state: state, output: snapshots)
        precondition(fake.startCalls == 0 && fake.processCalls == 0)
        precondition(!state.statsCollectionEnabled)
        precondition(!FileManager.default.fileExists(atPath: statsURL.path))
        print("PASS typing-speed actual AppState/input/hotkey/gate integration; no mic/model/clipboard/stats writes")
    }

    @MainActor private static func coordinatorAndGateChecks(state: AppState) async {
        let coordinator = state.typingSpeedTest
        let gate = state.updates.installationGate
        let hotkey = state.hotkey

        precondition(state.presentTypingSpeedTest())
        precondition(state.typingSpeedTestSheetVisible)
        precondition(!state.presentTypingSpeedTest(), "Only one sheet")
        precondition(coordinator.acquireInputFocus())
        precondition(coordinator.isInputFocused)
        precondition(hotkey.isGlobalHotkeySuspended)
        precondition(!gate.isBusy, "Ready/armed does not hold the install gate")
        precondition(coordinator.beginRun())
        precondition(coordinator.isRunning)
        precondition(gate.isBusy, "Running holds the shared operation gate")
        precondition(!coordinator.beginRun(), "One run lease per attempt")
        coordinator.releaseFocus()
        precondition(!gate.isBusy)
        precondition(!hotkey.isGlobalHotkeySuspended)
        precondition(coordinator.interaction == .idle)
        coordinator.releaseFocus() // idempotent
        state.typingSpeedTestSheetDidClose()

        // Nested token ownership restores exactly once.
        let first = hotkey.suspendGlobalHotkeys()
        let second = hotkey.suspendGlobalHotkeys()
        precondition(hotkey.isGlobalHotkeySuspended)
        hotkey.resumeGlobalHotkeys(first)
        precondition(hotkey.isGlobalHotkeySuspended)
        hotkey.resumeGlobalHotkeys(first) // unknown token is ignored
        precondition(hotkey.isGlobalHotkeySuspended)
        hotkey.resumeGlobalHotkeys(second)
        precondition(!hotkey.isGlobalHotkeySuspended)

        // A real operation excludes entry and cannot be overlapped by the test.
        let lease = gate.beginOperation()!
        precondition(!state.canPresentTypingSpeedTest)
        precondition(!coordinator.acquireInputFocus())
        gate.endOperation(lease)

        var installs = 0
        precondition(!gate.postponeInstallation { installs += 1 })
        precondition(installs == 0 && gate.isInstalling)
        precondition(!state.canPresentTypingSpeedTest)
        gate.resetInstallation()
        precondition(!gate.isInstalling)

        // Waiting-for-operation state also disables entry until the lease releases.
        let waitingLease = gate.beginOperation()!
        precondition(gate.postponeInstallation { installs += 1 })
        precondition(gate.isWaiting)
        precondition(!state.canPresentTypingSpeedTest)
        gate.endOperation(waitingLease)
        precondition(installs == 1)
        precondition(gate.isInstalling)
        gate.resetInstallation()
        print("PASS coordinator: focus/running/gate/token nesting, busy/installing/waiting exclusion, idempotent release")
    }

    @MainActor private static func applyChecks(state: AppState, statsURL: URL) {
        let before = state.typingSpeedWPM
        precondition(state.applyMeasuredTypingSpeed(64))
        precondition(state.typingSpeedWPM == 64)
        precondition(!state.statsCollectionEnabled)
        precondition(!FileManager.default.fileExists(atPath: statsURL.path))
        precondition(!state.applyMeasuredTypingSpeed(UsageStatsEstimate.minimumWPM - 1))
        precondition(!state.applyMeasuredTypingSpeed(UsageStatsEstimate.maximumWPM + 1))
        precondition(state.typingSpeedWPM == 64)
        state.typingSpeedWPM = before
        print("PASS Apply writes only carrottype.typingSpeedWPM; out-of-range values refuse silently and stats stay off")
    }

    @MainActor private static func lifecycleChecks(state: AppState) {
        let coordinator = state.typingSpeedTest
        let gate = state.updates.installationGate
        var invalidations = 0
        coordinator.onInvalidated = { invalidations += 1 }

        precondition(state.presentTypingSpeedTest())
        precondition(coordinator.acquireInputFocus())
        precondition(coordinator.beginRun())
        NotificationCenter.default.post(name: NSApplication.didResignActiveNotification, object: nil)
        pump(0.02)
        precondition(invalidations == 1)
        precondition(!coordinator.isRunning && !gate.isBusy && !state.hotkey.isGlobalHotkeySuspended)
        state.typingSpeedTestSheetDidClose()

        precondition(state.presentTypingSpeedTest())
        precondition(coordinator.acquireInputFocus())
        precondition(coordinator.beginRun())
        NSWorkspace.shared.notificationCenter.post(name: NSWorkspace.willSleepNotification, object: nil)
        pump(0.02)
        precondition(invalidations == 2)
        precondition(!coordinator.isRunning && !gate.isBusy && !state.hotkey.isGlobalHotkeySuspended)
        state.typingSpeedTestSheetDidClose()

        state.settingsDidAppear()
        precondition(state.presentTypingSpeedTest())
        precondition(coordinator.acquireInputFocus())
        precondition(coordinator.beginRun())
        state.settingsDidDisappear()
        pump(0.02)
        precondition(invalidations == 3)
        precondition(!coordinator.isRunning && !gate.isBusy && !state.hotkey.isGlobalHotkeySuspended)
        state.typingSpeedTestSheetDidClose()

        // Queued hotkey callback must not record into the test; it dismisses it instead.
        precondition(state.presentTypingSpeedTest())
        precondition(coordinator.acquireInputFocus())
        precondition(coordinator.beginRun())
        state.hotkey.handleCarbonHotkeyPressed()
        pump(0.02)
        precondition(state.typingSpeedTestDismissRequest != nil)
        precondition(!coordinator.isRunning && !gate.isBusy && !state.hotkey.isGlobalHotkeySuspended)
        state.typingSpeedTestSheetDidClose()

        // Quit path releases the test lease before the final termination check.
        precondition(state.presentTypingSpeedTest())
        precondition(coordinator.acquireInputFocus())
        precondition(coordinator.beginRun())
        let reply = state.prepareForQuit()
        precondition(reply == .terminateNow)
        precondition(!coordinator.isRunning && !gate.isBusy && !state.hotkey.isGlobalHotkeySuspended)
        state.typingSpeedTestSheetDidClose()

        // A postponed updater install runs once after the test releases its lease.
        var installs = 0
        precondition(state.presentTypingSpeedTest())
        precondition(coordinator.acquireInputFocus())
        precondition(coordinator.beginRun())
        precondition(gate.postponeInstallation { installs += 1 })
        precondition(gate.isWaiting)
        coordinator.releaseFocus()
        precondition(installs == 1 && gate.isInstalling)
        gate.resetInstallation()
        state.typingSpeedTestSheetDidClose()
        coordinator.onInvalidated = nil
        print("PASS lifecycle: deactivation/sleep/Settings close/quit/install restore gate and hotkeys exactly once")
    }

    @MainActor private static func inputAdapterChecks() {
        let controller = TypingTestInputController()
        var edits: [TypingTestEdit] = []
        var composition = ""
        var escapes = 0
        var focusLosses = 0
        let token = UUID()
        let representable = TypingTestInputView(
            text: "",
            documentToken: token,
            isEnabled: true,
            locale: Locale(identifier: "ru"),
            controller: controller,
            onEdit: { edits.append($0) },
            onCompositionChange: { composition = $0 },
            onEscape: { escapes += 1 },
            onFocusLost: { focusLosses += 1 }
        )
        let host = NSHostingView(rootView: representable.frame(width: 520, height: 88))
        host.frame = NSRect(x: 0, y: 0, width: 520, height: 88)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 88),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        pump(0.02)
        guard let field = controller.textView else {
            preconditionFailure("Native input field was not created")
        }
        precondition(controller.focus())
        precondition(window.firstResponder === field)
        field.insertText("a", replacementRange: field.selectedRange())
        pump(0.02)
        field.insertText("b", replacementRange: field.selectedRange())
        pump(0.02)
        precondition(edits.count == 2)
        precondition(edits[0].replacement == ["a"])
        precondition(edits[1].replacement == ["b"])
        precondition(field.string == "ab")

        let beforeDelete = edits.count
        field.deleteBackward(nil)
        pump(0.02)
        precondition(edits.count == beforeDelete + 1)
        precondition(edits.last?.replacement.isEmpty == true)
        precondition(field.string == "a")

        let beforePaste = field.string
        field.paste(nil)
        field.pasteAsPlainText(nil)
        pump(0.02)
        precondition(field.string == beforePaste, "Paste is disabled in the test input")

        field.cancelOperation(nil)
        precondition(escapes == 1)

        // Marked IME text is visible as composition but is not an attempt/edit.
        let beforeMarked = edits.count
        field.setMarkedText(
            "か",
            selectedRange: NSRange(location: 1, length: 0),
            replacementRange: NSRange(location: (field.string as NSString).length, length: 0)
        )
        pump(0.02)
        precondition(field.hasMarkedText())
        precondition(composition == "か")
        precondition(edits.count == beforeMarked)
        field.insertText("か", replacementRange: field.selectedRange())
        pump(0.02)
        precondition(!field.hasMarkedText())
        precondition(edits.count == beforeMarked + 1, "Only the committed IME grapheme is an edit")

        window.makeFirstResponder(nil)
        pump(0.02)
        precondition(focusLosses >= 1)
        precondition(!field.isRichText)
        precondition(!field.isAutomaticQuoteSubstitutionEnabled)
        precondition(!field.isAutomaticTextReplacementEnabled)
        precondition(!field.isAutomaticSpellingCorrectionEnabled)
        precondition(!field.isContinuousSpellCheckingEnabled)
        precondition(!field.allowsUndo)
        window.contentView = nil
        print("PASS native NSTextView adapter: committed inserts/backspace/edit diff, paste disabled, IME only on commit, Escape/focus")
    }

    @MainActor private static func viewModelChecks(state: AppState, fixture: URL) async {
        let clock = FakeClock()
        let model = TypingSpeedTestSheetModel(
            appState: state,
            locale: Locale(identifier: "ru"),
            initialLanguage: .russian,
            initialLevel: .medium,
            clock: clock.read,
            makeSeed: { 1234 },
            tickInterval: 10,
            focusInput: { true }
        )
        precondition(model.screen == .ready)
        precondition(model.promptText.count >= 650)
        precondition(!model.isTimerRunning)
        let firstPrompt = model.promptText

        model.start()
        precondition(model.screen == .armed)
        precondition(state.typingSpeedTest.interaction == .focused)
        precondition(!model.isTimerRunning, "No countdown in armed")
        let firstCharacter = String(model.promptText.prefix(1))
        model.handleEdit(TypingTestEdit.between("", firstCharacter)!)
        precondition(model.screen == .running)
        precondition(model.isTimerRunning)
        precondition(state.updates.installationGate.isBusy)
        precondition(state.hotkey.isGlobalHotkeySuspended)
        clock.now = 30
        model.handleTick()
        precondition(model.screen == .result)
        precondition(!model.isTimerRunning)
        precondition(model.result != nil)
        precondition(!state.updates.installationGate.isBusy)
        precondition(!state.hotkey.isGlobalHotkeySuspended)

        model.repeatAttempt()
        precondition(model.screen == .ready)
        precondition(model.promptText != firstPrompt, "Repeat uses a new prompt")
        precondition(!model.isTimerRunning)

        // 20 attempt cycles must leave no timer/gate/hotkey ownership behind.
        for cycle in 0..<20 {
            clock.now = TimeInterval(cycle * 100)
            model.start()
            precondition(model.screen == .armed, "cycle \(cycle)")
            let text = String(model.promptText.prefix(8))
            if let edit = TypingTestEdit.between("", text) {
                model.handleEdit(edit)
            }
            precondition(model.screen == .running)
            if cycle % 2 == 0 {
                model.handleLifecycleInvalidation()
                precondition(model.screen == .ready)
            } else {
                clock.now += 30
                model.handleTick()
                precondition(model.screen == .result)
                model.repeatAttempt()
                precondition(model.screen == .ready)
            }
            precondition(!model.isTimerRunning)
            precondition(!state.updates.installationGate.isBusy)
            precondition(!state.hotkey.isGlobalHotkeySuspended)
        }

        // Explicit close releases the same ownership and the timer.
        model.start()
        if let edit = TypingTestEdit.between("", String(model.promptText.prefix(4))) {
            model.handleEdit(edit)
        }
        model.requestClose()
        precondition(!model.isTimerRunning)
        precondition(!state.updates.installationGate.isBusy)
        precondition(!state.hotkey.isGlobalHotkeySuspended)
        model.sheetDidDisappear()
        precondition(!model.isTimerRunning)
        precondition(!state.updates.installationGate.isBusy)
        precondition(!state.hotkey.isGlobalHotkeySuspended)
        print("PASS sheet model: armed vs running timer, fixed deadline, repeat variation, 20-cycle cleanup")
    }

    @MainActor private static func snapshotEvidence(state: AppState, output: URL) async throws {
        let directory = output.appendingPathComponent("native")
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var rendered: [String] = []
        var sawOverflow = false

        for language in [AppLanguage.russian, .english] {
            for theme in [AppTheme.light, .dark] {
                state.appLanguage = language
                state.appTheme = theme
                let locale = language.effectiveLocale
                for level in TypingTestLevel.allCases {
                    for kind in ["ready", "running", "result"] {
                        let clock = FakeClock()
                        let model = TypingSpeedTestSheetModel(
                            appState: state,
                            locale: locale,
                            initialLanguage: language == .russian ? .russian : .english,
                            initialLevel: level,
                            clock: clock.read,
                            makeSeed: { 9000 + UInt64(level.rawValue.count) },
                            tickInterval: 10,
                            focusInput: { true }
                        )
                        if kind != "ready" {
                            model.start()
                            let count = min(120, model.promptText.count)
                            let prefix = String(model.promptText.prefix(count))
                            if let edit = TypingTestEdit.between("", prefix) {
                                model.handleEdit(edit)
                            }
                            if kind == "result" {
                                clock.now = 30
                                model.handleTick()
                            }
                        }
                        let name = "settings-\(language.effectiveLanguageCode)-\(theme.rawValue)-\(level.rawValue)-\(kind)"
                        let info = try render(
                            view: wholeShellWithSheet(state: state, model: model, locale: locale),
                            size: NSSize(width: 720, height: 520),
                            appearance: theme.appearance,
                            to: directory.appendingPathComponent("\(name).png")
                        )
                        precondition(info.found, "Whole Settings shell must keep a Form at minimum size")
                        sawOverflow = sawOverflow || info.overflow > 0
                        rendered.append(name)
                        model.sheetDidDisappear()
                    }
                }
            }
        }

        // Honest out-of-range and low-accuracy result states.
        state.appLanguage = .russian
        state.appTheme = .light
        let locale = Locale(identifier: "ru")
        let fastClock = FakeClock()
        let fast = TypingSpeedTestSheetModel(
            appState: state, locale: locale, initialLanguage: .russian, initialLevel: .advanced,
            clock: fastClock.read, makeSeed: { 77 }, tickInterval: 10, focusInput: { true }
        )
        fast.start()
        fast.handleEdit(TypingTestEdit.between("", fast.promptText)!)
        fastClock.now = 30
        fast.handleTick()
        precondition(fast.result?.isWPMInExistingRange == false)
        _ = try render(
            view: wholeShellWithSheet(state: state, model: fast, locale: locale),
            size: NSSize(width: 720, height: 520),
            appearance: AppTheme.light.appearance,
            to: directory.appendingPathComponent("settings-ru-light-out-of-range.png")
        )
        fast.sheetDidDisappear()

        let lowClock = FakeClock()
        let low = TypingSpeedTestSheetModel(
            appState: state, locale: locale, initialLanguage: .english, initialLevel: .medium,
            clock: lowClock.read, makeSeed: { 88 }, tickInterval: 10, focusInput: { true }
        )
        low.start()
        let good = String(low.promptText.prefix(100))
        let wrong = String(repeating: "x", count: 20)
        low.handleEdit(TypingTestEdit.between("", good + wrong)!)
        lowClock.now = 30
        low.handleTick()
        precondition((low.result?.accuracyPercent ?? 100) < 90)
        _ = try render(
            view: wholeShellWithSheet(state: state, model: low, locale: locale),
            size: NSSize(width: 720, height: 520),
            appearance: AppTheme.light.appearance,
            to: directory.appendingPathComponent("settings-ru-light-low-accuracy.png")
        )
        low.sheetDidDisappear()

        state.appLanguage = .english
        state.appTheme = .light
        _ = try render(
            view: wholeShellWithSheet(
                state: state,
                model: TypingSpeedTestSheetModel(
                    appState: state, locale: Locale(identifier: "en"), initialLanguage: .english,
                    initialLevel: .advanced, clock: { 0 }, makeSeed: { 99 }, tickInterval: 10,
                    focusInput: { true }
                ),
                locale: Locale(identifier: "en")
            ),
            size: NSSize(width: 720, height: 520),
            appearance: AppTheme.light.appearance,
            to: directory.appendingPathComponent("settings-en-light-long-advanced-ready.png")
        )
        // Reachability at the documented minimum window: the Statistics Form scrolls
        // to the Measure row without enlarging the main window.
        state.appLanguage = .russian
        state.appTheme = .light
        let bottomModel = TypingSpeedTestSheetModel(
            appState: state, locale: Locale(identifier: "ru"), initialLanguage: .russian,
            initialLevel: .medium, clock: { 0 }, makeSeed: { 111 }, tickInterval: 10,
            focusInput: { true }
        )
        let bottomInfo = try render(
            view: wholeShellWithSheet(state: state, model: bottomModel, locale: Locale(identifier: "ru")),
            size: NSSize(width: 720, height: 520),
            appearance: AppTheme.light.appearance,
            scrollToBottomEdge: true,
            to: directory.appendingPathComponent("settings-ru-light-minimum-bottom-sheet.png")
        )
        precondition(bottomInfo.found && bottomInfo.overflow > 0)
        bottomModel.sheetDidDisappear()
        _ = try render(
            view: CarrotTypeSettingsView(initialPane: .statistics)
                .environmentObject(state)
                .environment(\.locale, Locale(identifier: "ru")),
            size: NSSize(width: 720, height: 520),
            appearance: AppTheme.light.appearance,
            scrollToBottomEdge: true,
            to: directory.appendingPathComponent("settings-ru-light-minimum-statistics-bottom.png")
        )

        state.appLanguage = .system
        state.appTheme = .system
        print("SNAPSHOTS \(directory.path)")
        print("PASS native whole-Settings+sheet snapshots \(rendered.count) states, overflow=\(sawOverflow)")
    }

    @MainActor private static func wholeShellWithSheet(
        state: AppState,
        model: TypingSpeedTestSheetModel,
        locale: Locale
    ) -> some View {
        ZStack {
            CarrotTypeSettingsView(initialPane: .statistics)
                .environmentObject(state)
                .environment(\.locale, locale)
            Color.black.opacity(0.16)
            TypingSpeedTestSheet(appState: state, fixtureModel: model)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: .black.opacity(0.28), radius: 24, y: 10)
        }
        .frame(width: 720, height: 520)
        .environment(\.locale, locale)
    }

    private struct ScrollInfo {
        let found: Bool
        let overflow: CGFloat
    }

    @MainActor
    private static func render(
        view: some View,
        size: NSSize,
        appearance: NSAppearance?,
        scrollToBottomEdge: Bool = false,
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
        RunLoop.main.run(until: Date().addingTimeInterval(0.25))
        host.layoutSubtreeIfNeeded()
        var info = scrollInfo(in: host)
        if scrollToBottomEdge, info.overflow > 0 {
            _ = scrollToBottom(in: host)
            host.layoutSubtreeIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.15))
            info = scrollInfo(in: host)
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
    @discardableResult
    private static func scrollToBottom(in view: NSView) -> Bool {
        guard let scroll = deepestScroll(in: view), let document = scroll.documentView else {
            return false
        }
        let maxY = max(0, document.frame.height - scroll.contentView.bounds.height)
        scroll.contentView.scroll(to: NSPoint(x: 0, y: maxY))
        scroll.reflectScrolledClipView(scroll.contentView)
        return maxY > 0
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
}
