import SwiftUI

struct StorageSettingsPane: View {
    @ObservedObject var appState: AppState
    @ObservedObject var models: ModelManager

    private var locale: Locale { appState.effectiveLocale }

    var body: some View {
        Form {
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
        .formStyle(.grouped)
    }
}
