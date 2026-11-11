import SwiftUI

struct StorageSettingsPane: View {
    @ObservedObject var appState: AppState
    @ObservedObject var models: ModelManager
    @State private var confirmClearCache = false
    @State private var confirmDeleteUnused = false
    @State private var unusedDescription = ""
    @State private var legacyToDelete: LegacySTTPackage?
    @State private var confirmLegacyDelete = false

    private var locale: Locale { appState.effectiveLocale }

    private var totalBytes: Int64 { models.totalInstalledBytes }
    private var footprints: [InstalledPackageFootprint] { models.installedPackageFootprints }
    private var cacheBytes: Int64 { models.downloadCacheBytes }

    private var hasUnusedPackages: Bool {
        footprints.contains { !models.isActiveInstalledPackage($0.id) }
    }

    var body: some View {
        Form {
            Section {
                LabeledContent(L10n.t("storage.packages_used", locale: locale)) {
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
                    unusedDescription = footprints.filter { !models.isActiveInstalledPackage($0.id) }
                        .map { "\($0.displayName) · \(ByteCountFormatter.string(fromByteCount: $0.bytes, countStyle: .file))" }
                        .joined(separator: "\n")
                    confirmDeleteUnused = true
                }
                .disabled(!hasUnusedPackages)
            } header: {
                Text(L10n.t("storage.packages_section", locale: locale))
            } footer: {
                Text(L10n.t("storage.packages_footer", locale: locale))
            }

            if !models.legacySTTPackages.isEmpty {
                Section {
                    ForEach(models.legacySTTPackages) { package in
                        LabeledContent(package.name) {
                            HStack(spacing: 10) {
                                Text(ByteCountFormatter.string(fromByteCount: package.bytes, countStyle: .file))
                                    .foregroundStyle(.secondary)
                                Button(L10n.t("package.delete", locale: locale), role: .destructive) {
                                    legacyToDelete = package
                                    confirmLegacyDelete = true
                                }
                            }
                        }
                    }
                } header: {
                    Text(L10n.t("storage.legacy_section", locale: locale))
                } footer: {
                    Text(L10n.t("storage.legacy_footer", locale: locale))
                }
            }

            Section {
                LabeledContent(L10n.t("storage.cache_used", locale: locale)) {
                    Text(ByteCountFormatter.string(fromByteCount: cacheBytes, countStyle: .file))
                }

                if cacheBytes == 0 {
                    Text(L10n.t("storage.cache_empty", locale: locale))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button(L10n.t("storage.clear_cache", locale: locale), role: .destructive) {
                    confirmClearCache = true
                }
                .disabled(cacheBytes == 0)
            } header: {
                Text(L10n.t("storage.cache_section", locale: locale))
            } footer: {
                Text(L10n.t("storage.cache_footer", locale: locale))
            }
        }
        .formStyle(.grouped)
        .scrollIndicators(.never)
        .onAppear {
            models.refreshDownloadCacheBytes()
            models.refreshLegacySTTPackages()
        }
        .confirmationDialog(
            L10n.t("storage.delete_unused_confirm_title", locale: locale),
            isPresented: $confirmDeleteUnused, titleVisibility: .visible
        ) {
            Button(L10n.t("storage.delete_unused", locale: locale), role: .destructive) {
                appState.deleteUnusedModelPackages()
            }
            Button(L10n.t("package.cancel", locale: locale), role: .cancel) {}
        } message: {
            Text(unusedDescription + "\n\n" + L10n.t("storage.delete_unused_confirm_body", locale: locale))
        }
        .confirmationDialog(
            String(format: L10n.t("storage.legacy_confirm", locale: locale), legacyToDelete?.name ?? ""),
            isPresented: $confirmLegacyDelete,
            titleVisibility: .visible,
            presenting: legacyToDelete
        ) { package in
            Button(L10n.t("package.delete", locale: locale), role: .destructive) {
                models.deleteLegacySTTPackage(package.id)
                legacyToDelete = nil
            }
            Button(L10n.t("package.cancel", locale: locale), role: .cancel) { legacyToDelete = nil }
        } message: { _ in
            Text(L10n.t("storage.legacy_confirm_body", locale: locale))
        }
        .confirmationDialog(
            L10n.t("storage.clear_cache_confirm_title", locale: locale),
            isPresented: $confirmClearCache,
            titleVisibility: .visible
        ) {
            Button(L10n.t("storage.clear_cache", locale: locale), role: .destructive) {
                appState.clearModelDownloadCache()
            }
            Button(L10n.t("package.cancel", locale: locale), role: .cancel) {}
        } message: {
            Text(L10n.t("storage.clear_cache_confirm_message", locale: locale))
        }
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
