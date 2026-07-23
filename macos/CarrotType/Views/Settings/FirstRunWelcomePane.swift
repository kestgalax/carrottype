import SwiftUI

struct FirstRunWelcomePane: View {
    @ObservedObject var appState: AppState
    let onContinue: () -> Void

    private var locale: Locale { appState.effectiveLocale }

    var body: some View {
        Form {
            Section {
                Text(L10n.t("first_run.body", locale: locale))
                    .foregroundStyle(.secondary)

                Button(L10n.t("first_run.continue", locale: locale)) {
                    appState.refreshPermissions()
                    appState.completeFirstRun()
                    onContinue()
                }
                .keyboardShortcut(.defaultAction)
            } header: {
                Text(L10n.t("first_run.header", locale: locale))
            } footer: {
                Text(L10n.t("first_run.footer", locale: locale))
            }
        }
        .formStyle(.grouped)
    }
}
