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
            // Show which mic will be used before the local trial — same compact editor as Dictation.
            MicrophonePrioritySettingsSection(
                appState: appState,
                permissions: permissions,
                locale: locale
            )
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
}

/// Dictation compact summary: active mic + sheet editor (full list is rare to edit).
struct MicrophonePrioritySettingsSection: View {
    @ObservedObject var appState: AppState
    @ObservedObject var permissions: PermissionService
    let locale: Locale
    @State private var showEditor = false

    var body: some View {
        Section {
            if !permissions.microphoneGranted {
                Text(L10n.t("permissions.input_priority_needs_mic", locale: locale))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if appState.audioInput.devices.isEmpty {
                Text(L10n.t("permissions.no_devices", locale: locale))
                    .foregroundStyle(.secondary)
            } else {
                LabeledContent {
                    HStack(spacing: 10) {
                        Text(activeMicrophoneName)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Button(L10n.t("permissions.input_priority_configure", locale: locale)) {
                            appState.audioInput.refreshDevices()
                            showEditor = true
                        }
                        .controlSize(.small)
                    }
                } label: {
                    Text(L10n.t("permissions.input_active_microphone", locale: locale))
                }
            }
        } header: {
            Text(L10n.t("permissions.input_priority", locale: locale))
        }
        .sheet(isPresented: $showEditor) {
            MicrophonePrioritySheet(appState: appState, locale: locale)
        }
    }

    private var activeMicrophoneName: String {
        if let name = appState.audioInput.selectedDevice?.name, !name.isEmpty {
            return name
        }
        return L10n.t("permissions.input_unknown", locale: locale)
    }
}

/// Full ordered failover editor shown from Dictation → «Настроить…».
struct MicrophonePrioritySheet: View {
    @ObservedObject var appState: AppState
    let locale: Locale
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(L10n.t("permissions.input_priority", locale: locale))
                    .font(.headline)
                Spacer()
                Button(L10n.t("permissions.input_priority_done", locale: locale)) {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 10)

            Text(L10n.t("permissions.input_priority_hint", locale: locale))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

            Divider()

            if appState.audioInput.priorityEntries.isEmpty {
                Text(L10n.t("permissions.no_devices", locale: locale))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(20)
            } else {
                List {
                    ForEach(appState.audioInput.priorityEntries) { entry in
                        AudioInputPriorityRow(entry: entry, locale: locale)
                    }
                    .onMove { source, destination in
                        appState.audioInput.movePriorityEntries(from: source, to: destination)
                    }
                }
                .listStyle(.inset)
                // `onMove` enables native macOS row dragging (editMode is iOS-only).
                .environment(\.defaultMinListRowHeight, 36)
            }
        }
        .frame(minWidth: 480, idealWidth: 520, minHeight: 360, idealHeight: 420)
        .onAppear {
            appState.audioInput.refreshDevices()
        }
    }
}

/// One row of the ordered failover list. Sheet reorder uses native List drag (`onMove`).
struct AudioInputPriorityRow: View {
    let entry: AudioInputPriorityEntry
    let locale: Locale

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: entry.isActive ? "mic.fill" : "mic")
                .foregroundStyle(entry.isActive ? Color.accentColor : Color.secondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name ?? L10n.t("permissions.input_unknown", locale: locale))
                    .foregroundStyle(entry.isAvailable ? Color.primary : Color.secondary)

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
        }
        .padding(.vertical, 1)
        .accessibilityHint(Text(L10n.t("permissions.input_priority_drag_hint", locale: locale)))
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
