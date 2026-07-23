import AppKit
import SwiftUI

/// Native Settings content: grouped Form aligned with Apple HIG / Tahoe.
struct CarrotTypeSettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var alsoDownloadSmart = false

    private let recommendedSTTID = BundledModelCatalog.recommendedSTTID
    private let smartCleanupID = BundledModelCatalog.smartCleanupID

    var body: some View {
        CarrotTypeSettingsForm(
            appState: appState,
            models: appState.modelManager,
            permissions: appState.permissions,
            hotkey: appState.hotkey,
            alsoDownloadSmart: $alsoDownloadSmart,
            recommendedSTTID: recommendedSTTID,
            smartCleanupID: smartCleanupID
        )
    }
}

private struct CarrotTypeSettingsForm: View {
    @ObservedObject var appState: AppState
    @ObservedObject var models: ModelManager
    @ObservedObject var permissions: PermissionService
    @ObservedObject var hotkey: HotkeyService
    @Binding var alsoDownloadSmart: Bool
    let recommendedSTTID: String
    let smartCleanupID: String

    private var locale: Locale { appState.effectiveLocale }

    var body: some View {
        Form {
            if appState.showFirstRun {
                firstRunSection
            }

            statusSection
            permissionsSection
            sttSection
            cleanupSection
            hotkeySection
            languageSection
            storageSection
        }
        .formStyle(.grouped)
        .scrollIndicators(.automatic)
        .scrollIndicatorsFlash(onAppear: false)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .environment(\.locale, locale)
        // Do not `.id(appLanguage)` — remounting fires onDisappear/onAppear and kills the mic meter.
        .onAppear {
            appState.settingsDidAppear()
        }
        .onDisappear {
            appState.settingsDidDisappear()
        }
    }

    private var firstRunSection: some View {
        Section {
            Text(L10n.t("first_run.body", locale: locale))
                .foregroundStyle(.secondary)

            Button(L10n.t("first_run.continue", locale: locale)) {
                appState.refreshPermissions()
                appState.completeFirstRun()
            }
            .keyboardShortcut(.defaultAction)
        } header: {
            Text(L10n.t("first_run.header", locale: locale))
        } footer: {
            Text(L10n.t("first_run.footer", locale: locale))
        }
    }

    private var statusSection: some View {
        Section {
            LabeledContent {
                Text(appState.readiness.title(locale: locale))
                    .foregroundStyle(readinessColor)
                    .fontWeight(.semibold)
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("CarrotType")
                    Text(appVersionLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !appState.remainingHints.isEmpty {
                Text(
                    String(
                        format: L10n.t("status.remaining", locale: locale),
                        appState.remainingHints.joined(separator: ", ")
                    )
                )
                .foregroundStyle(.secondary)
            }

            if let error = appState.lastSessionError ?? models.lastErrorMessage {
                Text(error)
                    .foregroundStyle(.red)
            }

            Button(L10n.t("status.check_updates", locale: locale)) {
                if let url = URL(string: "https://github.com/kestgalax/carrottype/releases") {
                    NSWorkspace.shared.open(url)
                }
            }
        } header: {
            Text(L10n.t("status.section", locale: locale))
        }
    }

    private var appVersionLabel: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "—"
        return "v\(version)"
    }

    private var readinessColor: Color {
        switch appState.readiness {
        case .ready: return .green
        case .almost: return .orange
        case .blocked: return .red
        }
    }

    private var permissionsSection: some View {
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

    private var audioInputBinding: Binding<String> {
        Binding(
            get: { appState.audioInput.selectedDeviceID },
            set: { appState.selectAudioInput($0) }
        )
    }

    private var sttSection: some View {
        Section {
            if appState.showFirstRun {
                recommendedDownloadRow
            }

            Picker(L10n.t("stt.active", locale: locale), selection: activeSTTBinding) {
                if models.selectableSTTPackages.isEmpty {
                    Text(L10n.t("stt.download_below", locale: locale)).tag("")
                } else {
                    ForEach(models.selectableSTTPackages) { package in
                        Text(package.displayName).tag(package.id)
                    }
                }
            }
            .disabled(models.selectableSTTPackages.isEmpty)

            ForEach(models.sttPackages) { package in
                sttPackageRows(package)
            }
        } header: {
            Text(L10n.t("stt.section", locale: locale))
        } footer: {
            Text(L10n.t("stt.footer", locale: locale))
        }
    }

    private var activeSTTBinding: Binding<String> {
        Binding(
            get: {
                models.status(for: models.activeSTTID).isReady ? models.activeSTTID : ""
            },
            set: { newValue in
                guard !newValue.isEmpty else { return }
                models.selectSTT(newValue)
            }
        )
    }

    @ViewBuilder
    private var recommendedDownloadRow: some View {
        let status = models.status(for: recommendedSTTID)
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.t("stt.recommended", locale: locale))
            packageStatusControls(id: recommendedSTTID, status: status, prominentDownload: true)
        }
    }

    @ViewBuilder
    private func sttPackageRows(_ package: CatalogPackage) -> some View {
        let status = models.status(for: package.id)
        VStack(alignment: .leading, spacing: 6) {
            LabeledContent(package.displayName) {
                Text(statusLabel(status))
                    .foregroundStyle(.secondary)
            }
            Text("\(package.approximateSizeLabel) · \(package.license)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(package.localizedBlurb(locale: locale))
                .font(.caption)
                .foregroundStyle(.secondary)
            if !status.isReady {
                packageStatusControls(
                    id: package.id,
                    status: status,
                    prominentDownload: package.recommended && appState.showFirstRun
                )
            } else if models.activeSTTID != package.id {
                Button(L10n.t("format.make_active", locale: locale)) {
                    models.selectSTT(package.id)
                }
            }
        }
    }

    private var cleanupSection: some View {
        Section {
            Picker(L10n.t("format.mode", locale: locale), selection: cleanupBinding) {
                ForEach(models.selectableCleanupModes) { mode in
                    Text(mode.title(locale: locale)).tag(mode)
                }
            }

            if appState.showFirstRun {
                Toggle(L10n.t("format.download_smart", locale: locale), isOn: $alsoDownloadSmart)
                    .onChange(of: alsoDownloadSmart) { _, enabled in
                        if enabled {
                            let status = models.status(for: smartCleanupID)
                            if !status.isReady, !status.isDownloading {
                                models.download(smartCleanupID)
                            } else if status.isReady {
                                models.selectCleanup(.smart)
                            }
                        } else if models.status(for: smartCleanupID).isDownloading {
                            models.cancelDownload(smartCleanupID)
                        } else if models.cleanupMode == .smart {
                            models.selectCleanup(.light)
                        }
                    }
                    .onChange(of: models.status(for: smartCleanupID).isReady) { _, ready in
                        if alsoDownloadSmart, ready {
                            models.selectCleanup(.smart)
                        }
                    }

                if alsoDownloadSmart {
                    packageStatusControls(
                        id: smartCleanupID,
                        status: models.status(for: smartCleanupID),
                        prominentDownload: false
                    )
                }
            }

            ForEach(CleanupMode.allCases) { mode in
                if let packageID = mode.requiredPackageID {
                    let status = models.status(for: packageID)
                    VStack(alignment: .leading, spacing: 6) {
                        LabeledContent(mode.title(locale: locale)) {
                            Text(statusLabel(status))
                                .foregroundStyle(.secondary)
                        }
                        if !status.isReady {
                            packageStatusControls(id: packageID, status: status, prominentDownload: false)
                        } else if models.cleanupMode != mode {
                            Button(L10n.t("format.make_active", locale: locale)) {
                                models.selectCleanup(mode)
                            }
                        }
                    }
                } else if mode == .light {
                    LabeledContent(mode.title(locale: locale)) {
                        Text(L10n.t("format.built_in", locale: locale))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            Text(L10n.t("format.section", locale: locale))
        } footer: {
            Text(L10n.t("format.footer", locale: locale))
        }
    }

    private var cleanupBinding: Binding<CleanupMode> {
        Binding(
            get: { models.cleanupMode },
            set: { mode in
                models.selectCleanup(mode)
            }
        )
    }

    private var hotkeySection: some View {
        Section {
            HotkeySettingsRow(hotkey: hotkey)
            Toggle(
                L10n.t("hotkey.retain_clipboard", locale: locale),
                isOn: $appState.retainDictationInClipboard
            )
        } header: {
            Text(L10n.t("hotkey.section", locale: locale))
        } footer: {
            Text(
                hotkey.isRecording
                    ? L10n.t("hotkey.footer_recording", locale: locale)
                    : L10n.t("hotkey.retain_clipboard_footer", locale: locale)
            )
        }
    }

    private var languageSection: some View {
        Section {
            Picker(L10n.t("language.section", locale: locale), selection: $appState.appLanguage) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.title(locale: locale)).tag(language)
                }
            }
        } header: {
            Text(L10n.t("language.section", locale: locale))
        } footer: {
            Text(L10n.t("language.footer", locale: locale))
        }
    }

    private var storageSection: some View {
        Section {
            LabeledContent(L10n.t("storage.used", locale: locale)) {
                Text(ByteCountFormatter.string(fromByteCount: models.totalInstalledBytes, countStyle: .file))
            }
            Button(L10n.t("storage.delete_unused", locale: locale), role: .destructive) {
                appState.deleteUnusedModelPackages()
            }
        } header: {
            Text(L10n.t("storage.section", locale: locale))
        }
    }

    @ViewBuilder
    private func packageStatusControls(
        id: String,
        status: PackageInstallStatus,
        prominentDownload: Bool
    ) -> some View {
        if let progress = status.downloadProgress {
            ProgressView(value: progress)
            Text(String(format: L10n.t("package.downloading", locale: locale), Int(progress * 100)))
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        HStack {
            switch status {
            case .notDownloaded:
                if prominentDownload {
                    Button(L10n.t("package.download", locale: locale)) {
                        startDownload(id)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button(L10n.t("package.download", locale: locale)) {
                        startDownload(id)
                    }
                }
            case .downloading:
                Button(L10n.t("package.cancel", locale: locale)) {
                    models.cancelDownload(id)
                }
            case .ready:
                Label(L10n.t("package.ready", locale: locale), systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Button(L10n.t("package.delete", locale: locale), role: .destructive) {
                    appState.deleteModelPackage(id)
                }
            case .failed:
                Button(L10n.t("package.retry", locale: locale)) {
                    startDownload(id)
                }
                .buttonStyle(.borderedProminent)
            case .unavailable(let reason):
                Text(reason)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func startDownload(_ id: String) {
        models.download(id)
    }

    private func statusLabel(_ status: PackageInstallStatus) -> String {
        switch status {
        case .notDownloaded:
            return L10n.t("package.not_downloaded", locale: locale)
        case .downloading(let progress):
            return String(format: L10n.t("package.downloading", locale: locale), Int(progress * 100))
        case .ready:
            return L10n.t("package.status.ready", locale: locale)
        case .failed(let message):
            return String(format: L10n.t("package.failed", locale: locale), message)
        case .unavailable:
            return L10n.t("package.soon", locale: locale)
        }
    }
}

/// Isolated observer so the live meter does not invalidate the whole Settings Form.
private struct MicrophoneMeterSettingsRow: View {
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
