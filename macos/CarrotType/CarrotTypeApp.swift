import AppKit
import SwiftUI

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
                // Min size only — height/width may grow with zoom / user resize.
                .frame(minWidth: 640, minHeight: 480)
                .background(SettingsWindowChromeFix())
                // Avoid remounting Settings on language change: that races onDisappear
                // (clears settingsVisible / mic meter) with onAppear and breaks the meter.
        }
        // Settings default to contentSize (non-zooming). contentMinSize matches
        // other macOS windows: grow freely above the minimum.
        .windowResizability(.contentMinSize)
        .defaultSize(width: 700, height: 560)
    }
}

/// SwiftUI `Settings` often omits AppKit `.resizable`, so the green zoom / maximize
/// control does nothing. Re-insert the mask like other production menu-bar apps.
private struct SettingsWindowChromeFix: NSViewRepresentable {
    final class Helper: NSView {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let window else { return }
            window.styleMask.insert(.resizable)
            window.title = "carrottype"
            // Allow Option-click / zoom to use the visible display height.
            window.setContentSize(window.frame.size)
        }
    }

    func makeNSView(context: Context) -> NSView { Helper() }
    func updateNSView(_ nsView: NSView, context: Context) {}
}
