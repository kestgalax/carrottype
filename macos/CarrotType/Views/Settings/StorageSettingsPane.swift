import SwiftUI

struct StorageSettingsPane: View {
    @ObservedObject var appState: AppState
    @ObservedObject var models: ModelManager

    private var locale: Locale { appState.effectiveLocale }

    private var totalBytes: Int64 { models.totalInstalledBytes }
    private var footprints: [InstalledPackageFootprint] { models.installedPackageFootprints }

    private var hasUnusedPackages: Bool {
        footprints.contains { !models.isActiveInstalledPackage($0.id) }
    }

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
                        packageRow(footprint)
                    }
                }

                Button(L10n.t("storage.delete_unused", locale: locale), role: .destructive) {
                    appState.deleteUnusedModelPackages()
                }
                .disabled(!hasUnusedPackages)
            } header: {
                Text(L10n.t("storage.section", locale: locale))
            } footer: {
                Text(L10n.t("storage.footer", locale: locale))
            }
        }
        .formStyle(.grouped)
    }

    @ViewBuilder
    private func packageRow(_ footprint: InstalledPackageFootprint) -> some View {
        let packageID = footprint.id
        let isActive = models.isActiveInstalledPackage(packageID)
        VStack(alignment: .leading, spacing: 2) {
            LabeledContent(footprint.displayName) {
                Text(ByteCountFormatter.string(fromByteCount: footprint.bytes, countStyle: .file))
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 6) {
                Text(
                    isActive
                        ? L10n.t("storage.active", locale: locale)
                        : L10n.t("storage.unused", locale: locale)
                )
                .font(.caption)
                .foregroundStyle(isActive ? Color.secondary : Color.orange)
                if totalBytes > 0 {
                    Text("·")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
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
}
