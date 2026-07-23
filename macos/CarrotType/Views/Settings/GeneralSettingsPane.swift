import SwiftUI

struct GeneralSettingsPane: View {
    @ObservedObject var appState: AppState
    @ObservedObject var hotkey: HotkeyService

    private var locale: Locale { appState.effectiveLocale }

    var body: some View {
        Form {
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
        .formStyle(.grouped)
    }
}
