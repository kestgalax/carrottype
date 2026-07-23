import AppKit
import SwiftUI

private let settingsMinSize = NSSize(width: 720, height: 520)
private let settingsDefaultSize = NSSize(width: 880, height: 680)

@main
struct CarrotTypeApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView()
                .environmentObject(appState)
                .environment(\.locale, appState.effectiveLocale)
                .id(appState.appLanguage.rawValue + "-" + appState.effectiveLocale.identifier)
        } label: {
            MenuBarLabelView()
                .environmentObject(appState)
                .environment(\.locale, appState.effectiveLocale)
                .id(appState.appLanguage.rawValue)
        }

        Settings {
            CarrotTypeSettingsView()
                .environmentObject(appState)
                .environment(\.locale, appState.effectiveLocale)
                .frame(
                    minWidth: settingsMinSize.width,
                    maxWidth: .infinity,
                    minHeight: settingsMinSize.height,
                    maxHeight: .infinity
                )
                .background(SettingsWindowChromeFix())
                // Avoid remounting Settings on language change: that races onDisappear
                // (clears settingsVisible / mic meter) with onAppear and breaks the meter.
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: settingsDefaultSize.width, height: settingsDefaultSize.height)
    }
}

/// SwiftUI `Settings` often strips `.resizable` after show. Apply chrome on attach, then a
/// quiet watchdog restores **only** a missing `.resizable` bit — never rewrite styleMask
/// every frame (that made the zoom button blink).
private struct SettingsWindowChromeFix: NSViewRepresentable {
    final class Helper: NSView {
        private var becomeKeyObserver: NSObjectProtocol?
        private var watchdog: Timer?
        private var configuredWindow: ObjectIdentifier?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            tearDown()
            guard let window else { return }

            applyFullChrome(to: window)
            startWatchdog(for: window)
            observeBecomeKey(for: window)

            // SwiftUI may strip the mask shortly after first layout.
            for delay in [0.05, 0.3, 1.0] as [TimeInterval] {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self, weak window] in
                    guard let self, let window, self.window === window else { return }
                    self.restoreResizableIfNeeded(on: window)
                }
            }
        }

        deinit {
            tearDown()
        }

        private func tearDown() {
            if let becomeKeyObserver {
                NotificationCenter.default.removeObserver(becomeKeyObserver)
                self.becomeKeyObserver = nil
            }
            watchdog?.invalidate()
            watchdog = nil
            configuredWindow = nil
        }

        private func observeBecomeKey(for window: NSWindow) {
            becomeKeyObserver = NotificationCenter.default.addObserver(
                forName: NSWindow.didBecomeKeyNotification,
                object: window,
                queue: .main
            ) { [weak self, weak window] _ in
                guard let self, let window else { return }
                self.restoreResizableIfNeeded(on: window)
            }
        }

        private func startWatchdog(for window: NSWindow) {
            // Slow poll: only mutates when `.resizable` is actually missing.
            let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self, weak window] timer in
                guard let self, let window, self.window === window else {
                    timer.invalidate()
                    return
                }
                self.restoreResizableIfNeeded(on: window)
            }
            RunLoop.main.add(timer, forMode: .common)
            watchdog = timer
        }

        private func applyFullChrome(to window: NSWindow) {
            let id = ObjectIdentifier(window)
            if configuredWindow == id, window.styleMask.contains(.resizable) {
                return
            }

            var mask = window.styleMask
            mask.insert([.titled, .closable, .miniaturizable, .resizable])
            if mask != window.styleMask {
                window.styleMask = mask
            }

            if window.title != "carrottype" {
                window.title = "carrottype"
            }
            if window.minSize != settingsMinSize {
                window.minSize = settingsMinSize
                window.contentMinSize = settingsMinSize
            }
            let unconstrained = NSSize(width: 10_000, height: 10_000)
            if window.maxSize.width < 5_000 {
                window.maxSize = unconstrained
                window.contentMaxSize = unconstrained
            }
            if let zoom = window.standardWindowButton(.zoomButton) {
                if !zoom.isEnabled { zoom.isEnabled = true }
                if zoom.isHidden { zoom.isHidden = false }
            }
            if window.collectionBehavior.contains(.fullScreenPrimary) {
                var behavior = window.collectionBehavior
                behavior.remove(.fullScreenPrimary)
                behavior.insert(.fullScreenAuxiliary)
                window.collectionBehavior = behavior
            }
            if window.frameAutosaveName != "carrottype.settings" {
                window.setFrameAutosaveName("carrottype.settings")
            }

            configuredWindow = id
        }

        private func restoreResizableIfNeeded(on window: NSWindow) {
            guard !window.styleMask.contains(.resizable) else { return }
            // Minimal write — do not reassign unrelated chrome (avoids traffic-light flicker).
            window.styleMask.insert(.resizable)
            if window.minSize.width < settingsMinSize.width {
                window.minSize = settingsMinSize
                window.contentMinSize = settingsMinSize
            }
            window.standardWindowButton(.zoomButton)?.isEnabled = true
        }
    }

    func makeNSView(context: Context) -> NSView { Helper() }

    func updateNSView(_ nsView: NSView, context: Context) {
        // Do not mutate NSWindow here — SwiftUI calls this frequently.
    }
}
