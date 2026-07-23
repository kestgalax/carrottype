import SwiftUI

struct SetupSettingsPane: View {
    @ObservedObject var appState: AppState
    @ObservedObject var permissions: PermissionService

    private var locale: Locale { appState.effectiveLocale }

    var body: some View {
        Form {
            Section {
                LabeledContent {
                    switch permissions.microphoneAuthorization {
                    case .authorized:
                        Label(L10n.t("permissions.allowed", locale: locale), systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    case .notDetermined:
                        Button(L10n.t("permissions.allow", locale: locale)) {
                            permissions.requestOrOpenMicrophone()
                        }
                        .buttonStyle(.borderedProminent)
                    case .denied, .restricted:
                        Button(L10n.t("permissions.open_settings", locale: locale)) {
                            permissions.openMicrophoneSettings()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } label: {
                    Label(L10n.t("permissions.microphone", locale: locale), systemImage: "mic.fill")
                }

                if permissions.microphoneGranted {
                    if appState.audioInput.devices.isEmpty {
                        Text(L10n.t("permissions.no_devices", locale: locale))
                            .foregroundStyle(.secondary)
                    } else {
                        Picker(L10n.t("permissions.input_device", locale: locale), selection: audioInputBinding) {
                            ForEach(appState.audioInput.devices) { device in
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
                        }

                        Toggle(
                            L10n.t("permissions.meter_toggle", locale: locale),
                            isOn: $appState.micMeterEnabled
                        )
                        if appState.micMeterEnabled {
                            MicrophoneMeterSettingsRow(
                                audioLevel: appState.audioLevel,
                                locale: locale
                            )
                        } else {
                            Text(L10n.t("permissions.meter_off_hint", locale: locale))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Toggle(
                            L10n.t("permissions.unmute_during_dictation", locale: locale),
                            isOn: $appState.unmuteMicDuringDictation
                        )
                        Text(L10n.t("permissions.unmute_during_dictation_hint", locale: locale))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                LabeledContent {
                    if permissions.accessibilityGranted {
                        Label(L10n.t("permissions.allowed", locale: locale), systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Button(L10n.t("permissions.open_settings", locale: locale)) {
                            permissions.openAccessibilitySettings()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } label: {
                    Label(L10n.t("permissions.accessibility", locale: locale), systemImage: "hand.raised.fill")
                }

                Group {
                    if permissions.accessibilityGranted {
                        EmptyView()
                    }
                }
                .id(permissions.permissionCheckTick)

                if !permissions.accessibilityGranted {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.t("permissions.accessibility_tip", locale: locale))
                            .font(.caption)
                            .foregroundStyle(.orange)

                        HStack {
                            Button(L10n.t("permissions.relaunch", locale: locale)) {
                                permissions.relaunchApp()
                            }
                            .buttonStyle(.borderedProminent)

                            Button(L10n.t("permissions.refresh", locale: locale)) {
                                appState.refreshPermissions()
                            }
                        }
                    }
                } else {
                    Button(L10n.t("permissions.refresh", locale: locale)) {
                        appState.refreshPermissions()
                    }
                }
            } header: {
                Text(L10n.t("permissions.section", locale: locale))
            }
        }
        .formStyle(.grouped)
    }

    private var audioInputBinding: Binding<String> {
        Binding(
            get: { appState.audioInput.selectedDeviceID },
            set: { appState.selectAudioInput($0) }
        )
    }
}

/// Isolated observer so the live meter does not invalidate the whole Settings Form.
struct MicrophoneMeterSettingsRow: View {
    @ObservedObject var audioLevel: AudioLevelMonitor
    let locale: Locale

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: audioLevel.level > 0.08 ? "mic.fill" : "mic")
                    .foregroundStyle(audioLevel.level > 0.08 ? .green : .secondary)
                    .frame(width: 16)
                MicrophoneLevelMeter(
                    level: audioLevel.level,
                    isActive: audioLevel.isRunning
                )
            }
            Text(
                audioLevel.isRunning
                    ? (audioLevel.level > 0.08
                        ? L10n.t("permissions.meter_hearing", locale: locale)
                        : L10n.t("permissions.meter_speak", locale: locale))
                    : L10n.t("permissions.meter_off", locale: locale)
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            if let error = audioLevel.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }
}
