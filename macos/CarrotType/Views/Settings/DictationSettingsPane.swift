import SwiftUI

/// Settings → Dictation: the recording shortcut and everything that shapes the inserted text.
struct DictationSettingsPane: View {
    @ObservedObject var appState: AppState
    @ObservedObject var hotkey: HotkeyService
    let onOpenModels: () -> Void

    private var locale: Locale { appState.effectiveLocale }

    var body: some View {
        Form {
            Section {
                HotkeySettingsRow(hotkey: hotkey, target: .dictation)
                if hotkey.isRecording, hotkey.captureTarget == .dictation {
                    Text(L10n.t("hotkey.footer_recording", locale: locale))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                SettingsToggleRow(
                    title: L10n.t("hotkey.push_to_talk", locale: locale),
                    hint: L10n.t("hotkey.push_to_talk_footer", locale: locale),
                    isOn: $appState.pushToTalkEnabled
                )
                SettingsToggleRow(
                    title: L10n.t("hotkey.retain_clipboard", locale: locale),
                    hint: L10n.t("hotkey.retain_clipboard_footer", locale: locale),
                    isOn: $appState.retainDictationInClipboard
                )
            } header: {
                Text(L10n.t("hotkey.section", locale: locale))
            }

            DictationFormattingSection(models: appState.modelManager, locale: locale, onOpenModels: onOpenModels)

            FormattingRulesSection(appState: appState, locale: locale)
        }
        .formStyle(.grouped)
        .scrollIndicators(.never)
        .onDisappear {
            // Leaving the pane must cancel chord capture and restore global registration.
            // This is the hotkey editor's capture flag, not an active dictation session.
            if hotkey.isRecording { hotkey.cancelRecording() }
        }
    }
}

/// Shares the exact selection/status source with Models, including Ready-only choices.
private struct DictationFormattingSection: View {
    @ObservedObject var models: ModelManager
    let locale: Locale
    let onOpenModels: () -> Void

    var body: some View {
        Section {
            Picker(L10n.t("format.mode", locale: locale), selection: Binding(
                get: { models.cleanupMode }, set: { models.selectCleanup($0) }
            )) {
                ForEach(models.selectableCleanupModes) { mode in
                    Text(mode.title(locale: locale)).tag(mode)
                }
            }
            Button(L10n.t("status.open_models", locale: locale), action: onOpenModels)
        } header: {
            Text(L10n.t("format.section", locale: locale))
        } footer: {
            Text(L10n.t("format.general_footer", locale: locale))
                .font(.caption).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
