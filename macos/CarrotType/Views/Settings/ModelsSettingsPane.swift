import SwiftUI

struct ModelsSettingsPane: View {
    @ObservedObject var appState: AppState
    @ObservedObject var models: ModelManager

    private let recommendedSTTID = BundledModelCatalog.recommendedSTTID

    private var locale: Locale { appState.effectiveLocale }

    var body: some View {
        Form {
            sttSection
            cleanupSection
        }
        .formStyle(.grouped)
    }

    private var sttSection: some View {
        Section {
            // Prominent CTA while the recommended package is not Ready (covers post–first-run Models).
            if !models.status(for: recommendedSTTID).isReady {
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
            SettingsPackageStatusControls(
                appState: appState,
                models: models,
                id: recommendedSTTID,
                status: status,
                locale: locale,
                prominentDownload: true
            )
        }
    }

    @ViewBuilder
    private func sttPackageRows(_ package: CatalogPackage) -> some View {
        let status = models.status(for: package.id)
        let isAppleSpeech = package.runtimeHint == "apple-speechanalyzer"
        VStack(alignment: .leading, spacing: 6) {
            LabeledContent(package.displayName) {
                Text(
                    SettingsPackageStatusControls.statusLabel(
                        status,
                        locale: locale,
                        prepareLabel: isAppleSpeech
                    )
                )
                .foregroundStyle(.secondary)
            }
            Text("\(package.approximateSizeLabel) · \(package.license)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(package.localizedBlurb(locale: locale))
                .font(.caption)
                .foregroundStyle(.secondary)
            if case .failed(let message) = status, isAppleSpeech {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if status.isReady {
                HStack {
                    if models.activeSTTID != package.id {
                        Button(L10n.t("format.make_active", locale: locale)) {
                            models.selectSTT(package.id)
                        }
                    }
                    Button(L10n.t("package.delete", locale: locale), role: .destructive) {
                        appState.deleteModelPackage(package.id)
                    }
                }
            } else {
                SettingsPackageStatusControls(
                    appState: appState,
                    models: models,
                    id: package.id,
                    status: status,
                    locale: locale,
                    prominentDownload: package.recommended,
                    prepareLabel: isAppleSpeech
                )
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

            ForEach(CleanupMode.allCases) { mode in
                if let packageID = mode.requiredPackageID {
                    let status = models.status(for: packageID)
                    VStack(alignment: .leading, spacing: 6) {
                        LabeledContent(mode.title(locale: locale)) {
                            Text(SettingsPackageStatusControls.statusLabel(status, locale: locale))
                                .foregroundStyle(.secondary)
                        }
                        if status.isReady {
                            HStack {
                                if models.cleanupMode != mode {
                                    Button(L10n.t("format.make_active", locale: locale)) {
                                        models.selectCleanup(mode)
                                    }
                                }
                                Button(L10n.t("package.delete", locale: locale), role: .destructive) {
                                    appState.deleteModelPackage(packageID)
                                }
                            }
                        } else {
                            SettingsPackageStatusControls(
                                appState: appState,
                                models: models,
                                id: packageID,
                                status: status,
                                locale: locale,
                                prominentDownload: false
                            )
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
}

struct SettingsPackageStatusControls: View {
    @ObservedObject var appState: AppState
    @ObservedObject var models: ModelManager
    let id: String
    let status: PackageInstallStatus
    let locale: Locale
    let prominentDownload: Bool
    var prepareLabel: Bool = false

    private var downloadTitle: String {
        L10n.t(prepareLabel ? "package.prepare" : "package.download", locale: locale)
    }

    var body: some View {
        if let progress = status.downloadProgress {
            ProgressView(value: progress)
            Text(String(format: L10n.t(prepareLabel ? "package.preparing" : "package.downloading", locale: locale), Int(progress * 100)))
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        HStack {
            switch status {
            case .notDownloaded:
                if prominentDownload {
                    Button(downloadTitle) {
                        models.download(id)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button(downloadTitle) {
                        models.download(id)
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
                    models.download(id)
                }
                .buttonStyle(.borderedProminent)
            case .unavailable(let reason):
                Text(reason)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    static func statusLabel(
        _ status: PackageInstallStatus,
        locale: Locale,
        prepareLabel: Bool = false
    ) -> String {
        switch status {
        case .notDownloaded:
            return L10n.t(prepareLabel ? "package.not_prepared" : "package.not_downloaded", locale: locale)
        case .downloading(let progress):
            return String(
                format: L10n.t(prepareLabel ? "package.preparing" : "package.downloading", locale: locale),
                Int(progress * 100)
            )
        case .ready:
            return L10n.t("package.status.ready", locale: locale)
        case .failed(let message):
            if prepareLabel {
                return L10n.t("package.apple_unavailable", locale: locale)
            }
            return String(format: L10n.t("package.failed", locale: locale), message)
        case .unavailable:
            return L10n.t("package.soon", locale: locale)
        }
    }
}
