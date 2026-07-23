import SwiftUI

struct StorageSettingsPane: View {
    @ObservedObject var appState: AppState
    @ObservedObject var models: ModelManager

    private var locale: Locale { appState.effectiveLocale }

    private var totalBytes: Int64 { models.totalInstalledBytes }
    private var footprints: [InstalledPackageFootprint] { models.installedPackageFootprints }

    var body: some View {
        Form {
            Section {
                LabeledContent(L10n.t("storage.used", locale: locale)) {
                    Text(ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file))
                }

                if footprints.isEmpty {
                    Text(L10n.t("storage.empty", locale: locale))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(footprints) { footprint in
                        VStack(alignment: .leading, spacing: 2) {
                            LabeledContent(footprint.displayName) {
                                Text(ByteCountFormatter.string(fromByteCount: footprint.bytes, countStyle: .file))
                                    .foregroundStyle(.secondary)
                            }
                            if totalBytes > 0 {
                                Text(
                                    String(
                                        format: L10n.t("storage.share", locale: locale),
                                        Int((Double(footprint.bytes) / Double(totalBytes) * 100).rounded())
                                    )
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Button(L10n.t("storage.delete_unused", locale: locale), role: .destructive) {
                    appState.deleteUnusedModelPackages()
                }
            } header: {
                Text(L10n.t("storage.section", locale: locale))
            }
        }
        .formStyle(.grouped)
    }
}
