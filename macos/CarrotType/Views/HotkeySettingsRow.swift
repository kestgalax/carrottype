import SwiftUI

struct HotkeySettingsRow: View {
    @ObservedObject var hotkey: HotkeyService
    @Environment(\.locale) private var locale

    var body: some View {
        LabeledContent(L10n.t("hotkey.combination", locale: locale)) {
            Text(hotkey.isRecording ? L10n.t("hotkey.press_combo", locale: locale) : hotkey.displayString)
                .font(.body.monospaced())
                .foregroundStyle(hotkey.isRecording ? Color.accentColor : Color.primary)
        }

        HStack {
            if hotkey.isRecording {
                Button(L10n.t("hotkey.cancel", locale: locale)) {
                    hotkey.cancelRecording()
                }
            } else {
                Button(L10n.t("hotkey.change", locale: locale)) {
                    hotkey.startRecording()
                }
                Button(L10n.t("hotkey.reset", locale: locale)) {
                    hotkey.resetToDefault()
                }
            }
        }
    }
}
