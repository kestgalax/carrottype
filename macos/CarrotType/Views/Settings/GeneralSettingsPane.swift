import SwiftUI

/// Settings → General: application-level preferences only.
/// Dictation controls live in Dictation; selected-text bindings live in Text actions.
struct GeneralSettingsPane: View {
    @ObservedObject var appState: AppState

    private var locale: Locale { appState.effectiveLocale }

    var body: some View {
        Form {
            AppUpdateSettingsSection(updates: appState.updates, locale: locale)

            Section {
                Picker(L10n.t("theme.title", locale: locale), selection: $appState.appTheme) {
                    ForEach(AppTheme.allCases) { theme in Text(theme.title(locale: locale)).tag(theme) }
                }
                Picker(L10n.t("language.section", locale: locale), selection: $appState.appLanguage) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.title(locale: locale)).tag(language)
                    }
                }
            } header: {
                Text(L10n.t("appearance.section", locale: locale))
            } footer: {
                Text(L10n.t("language.footer", locale: locale))
            }

            // Keep launch at sign-in as the final section, as requested by the maintainer.
            LaunchAtLoginSection(service: appState.launchAtLogin, locale: locale)
        }
        .formStyle(.grouped)
        .scrollIndicators(.never)
    }
}
