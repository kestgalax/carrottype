import SwiftUI

struct SetupSettingsPane: View {
    @ObservedObject var appState: AppState
    @ObservedObject var permissions: PermissionService

    private var locale: Locale { appState.effectiveLocale }

    var body: some View {
        Form {
            Section {
                SetupProgressView(appState: appState)
            }
            if permissions.microphoneGranted, !appState.audioInput.devices.isEmpty {
                Section {
                    Text(L10n.t("permissions.input_priority_hint", locale: locale))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    let entries = appState.audioInput.priorityEntries
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        AudioInputPriorityRow(
                            entry: entry,
                            canMoveUp: index > 0,
                            canMoveDown: index < entries.count - 1,
                            locale: locale,
                            moveUp: { appState.audioInput.movePriorityEntry(entry.id, by: -1) },
                            moveDown: { appState.audioInput.movePriorityEntry(entry.id, by: 1) }
                        )
                    }
                } header: {
                    Text(L10n.t("permissions.input_priority", locale: locale))
                }
            }
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
            Section {
                if let package = appState.modelManager.sttPackages.first {
                    LabeledContent(package.displayName) {
                        Text(SettingsPackageStatusControls.statusLabel(appState.modelManager.status(for: package.id), locale: locale))
                            .foregroundStyle(.secondary)
                    }
                    if appState.modelManager.status(for: package.id) != .ready {
                        SettingsPackageStatusControls(appState: appState, models: appState.modelManager,
                            id: package.id, locale: locale, prominentDownload: true)
                    }
                }
            } header: {
                Text(L10n.t("setup.step.model", locale: locale))
            }
            SetupTrialSection(appState: appState)
        }
        .formStyle(.grouped)
        .scrollIndicators(.never)
        .onDisappear { appState.cancelSetupTrial() }
    }

    private var audioInputBinding: Binding<String> {
        Binding(
            get: { appState.audioInput.selectedDeviceID },
            set: { appState.selectAudioInput($0) }
        )
    }
}

/// One row of the ordered failover list: availability/active state and explicit reordering.
/// Buttons (instead of drag) keep the native Form usable with keyboard and VoiceOver.
struct AudioInputPriorityRow: View {
    let entry: AudioInputPriorityEntry
    let canMoveUp: Bool
    let canMoveDown: Bool
    let locale: Locale
    let moveUp: () -> Void
    let moveDown: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: entry.isActive ? "mic.fill" : "mic")
                .foregroundStyle(entry.isActive ? Color.accentColor : Color.secondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name ?? L10n.t("permissions.input_unknown", locale: locale))

                HStack(spacing: 8) {
                    if entry.isActive {
                        Label(L10n.t("permissions.input_active", locale: locale), systemImage: "checkmark.circle.fill")
                    }
                    if entry.isDefault {
                        Text(L10n.t("permissions.input_system_default", locale: locale))
                    }
                    if !entry.isAvailable {
                        Label(L10n.t("permissions.input_unavailable", locale: locale), systemImage: "bolt.horizontal.circle")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            HStack(spacing: 2) {
                Button(action: moveUp) {
                    Image(systemName: "chevron.up")
                }
                .disabled(!canMoveUp)
                .help(L10n.t("permissions.input_move_up", locale: locale))
                .accessibilityLabel(Text(L10n.t("permissions.input_move_up", locale: locale)))

                Button(action: moveDown) {
                    Image(systemName: "chevron.down")
                }
                .disabled(!canMoveDown)
                .help(L10n.t("permissions.input_move_down", locale: locale))
                .accessibilityLabel(Text(L10n.t("permissions.input_move_down", locale: locale)))
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 1)
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
