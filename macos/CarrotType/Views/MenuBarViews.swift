import AppKit
import SwiftUI

struct MenuBarLabelView: View {
    @EnvironmentObject private var appState: AppState

    private var locale: Locale { appState.effectiveLocale }

    var body: some View {
        Image(systemName: symbolName)
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(iconColor)
            .accessibilityLabel(Text(accessibilityLabel))
    }

    private var iconColor: Color {
        switch appState.menuBarMode {
        case .recording: return .red
        case .processing, .cleanup: return .orange
        case .error: return .yellow
        default: return .primary
        }
    }

    private var symbolName: String {
        switch appState.menuBarMode {
        case .idle: return "waveform"
        case .needsSetup: return "waveform.badge.exclamationmark"
        case .recording: return "record.circle.fill"
        case .processing: return "ellipsis.circle.fill"
        case .cleanup: return "text.badge.checkmark"
        case .error: return "exclamationmark.triangle"
        }
    }

    private var accessibilityLabel: String {
        switch appState.menuBarMode {
        case .idle: return L10n.t("a11y.idle", locale: locale)
        case .needsSetup: return L10n.t("a11y.setup", locale: locale)
        case .recording: return L10n.t("a11y.recording", locale: locale)
        case .processing: return L10n.t("a11y.processing", locale: locale)
        case .cleanup: return L10n.t("a11y.cleanup", locale: locale)
        case .error: return L10n.t("a11y.error", locale: locale)
        }
    }
}

struct MenuBarContentView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.openSettings) private var openSettings

    private var locale: Locale { appState.effectiveLocale }

    var body: some View {
        Text(statusLine)
            .foregroundStyle(.secondary)

        if !appState.remainingHints.isEmpty {
            Menu(String(format: L10n.t("menu.remaining", locale: locale), appState.remainingHints.count)) {
                ForEach(appState.remainingHints, id: \.self) { hint in
                    Text(hint)
                }
                Divider()
                Button(L10n.t("menu.open_settings", locale: locale)) {
                    openSettingsAndRefresh()
                }
            }
        }

        Divider()

        microphoneMenu

        Divider()

        Button(L10n.t("menu.settings", locale: locale)) {
            openSettingsAndRefresh()
        }
        .keyboardShortcut(",", modifiers: .command)

        Button(L10n.t("menu.quit", locale: locale)) {
            NSApplication.shared.terminate(nil)
        }
        .onAppear {
            appState.refreshPermissions()
            if appState.permissions.microphoneGranted {
                appState.audioInput.refreshDevices()
            }
            guard appState.showFirstRun else { return }
            openSettingsAndRefresh()
        }
    }

    private var statusLine: String {
        switch appState.menuBarMode {
        case .recording: return L10n.t("menu.status.recording", locale: locale)
        case .processing: return L10n.t("menu.status.processing", locale: locale)
        case .cleanup: return L10n.t("menu.status.cleanup", locale: locale)
        case .error:
            if let error = appState.lastSessionError, !error.isEmpty {
                return L10n.t("menu.status.error", locale: locale)
            }
            return appState.readiness.title(locale: locale)
        default:
            return appState.readiness.title(locale: locale)
        }
    }

    @ViewBuilder
    private var microphoneMenu: some View {
        let audio = appState.audioInput
        if !appState.permissions.microphoneGranted {
            Button(L10n.t("menu.mic_no_access", locale: locale)) {
                appState.permissions.requestOrOpenMicrophone()
            }
        } else if audio.devices.isEmpty {
            Text(L10n.t("menu.mic_not_found", locale: locale))
                .foregroundStyle(.secondary)
        } else {
            Picker(selection: microphoneBinding) {
                ForEach(audio.devices) { device in
                    Text(
                        device.isDefault
                            ? String(
                                format: L10n.t("permissions.default_suffix", locale: locale),
                                device.name
                            )
                            : device.name
                    )
                    .tag(device.id)
                }
            } label: {
                Text(microphoneTitle)
            }
        }
    }

    private var microphoneBinding: Binding<String> {
        Binding(
            get: { appState.audioInput.selectedDeviceID },
            set: { appState.selectAudioInput($0) }
        )
    }

    private var microphoneTitle: String {
        let name = appState.audioInput.selectedDevice?.name
            ?? L10n.t("permissions.microphone", locale: locale)
        if name.count > 22 {
            return String(format: L10n.t("menu.mic_prefix", locale: locale), "\(name.prefix(20))…")
        }
        return String(format: L10n.t("menu.mic_prefix", locale: locale), name)
    }

    private func openSettingsAndRefresh() {
        appState.refreshPermissions()
        openSettings()
        NSApp.activate(ignoringOtherApps: true)
    }
}
