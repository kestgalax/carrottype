import SwiftUI

struct HotkeySettingsRow: View {
    @ObservedObject var hotkey: HotkeyService
    var target: HotkeyCaptureTarget = .dictation
    var combinationLabel: String? = nil
    @Environment(\.locale) private var locale

    private var isCapturingThis: Bool {
        hotkey.isRecording && hotkey.captureTarget == target
    }

    private var display: String {
        switch target {
        case .dictation:
            return hotkey.displayString
        case .transformBinding(let id):
            return hotkey.binding(id: id)?.chord.displayString ?? "—"
        }
    }

    private var label: String {
        combinationLabel ?? L10n.t("hotkey.combination", locale: locale)
    }

    var body: some View {
        LabeledContent(label) {
            Text(isCapturingThis ? L10n.t("hotkey.press_combo", locale: locale) : display)
                .font(.body.monospaced())
                .foregroundStyle(isCapturingThis ? Color.accentColor : Color.primary)
        }

        HStack {
            if isCapturingThis {
                Button(L10n.t("hotkey.cancel", locale: locale)) {
                    hotkey.cancelRecording()
                }
            } else {
                Button(L10n.t("hotkey.change", locale: locale)) {
                    hotkey.startRecording(for: target)
                }
                Button(L10n.t("hotkey.reset", locale: locale)) {
                    switch target {
                    case .dictation:
                        hotkey.resetToDefault()
                    case .transformBinding(let id):
                        hotkey.resetTransformBindingToDefault(id: id)
                    }
                }
            }
        }

        if hotkey.lastCaptureConflict, hotkey.lastConflictTarget == target {
            Text(L10n.t("hotkey.conflict", locale: locale))
                .font(.caption)
                .foregroundStyle(.red)
        }
    }
}
