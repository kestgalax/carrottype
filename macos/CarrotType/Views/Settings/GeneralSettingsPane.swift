import SwiftUI

struct GeneralSettingsPane: View {
    @ObservedObject var appState: AppState
    @ObservedObject var hotkey: HotkeyService

    private var locale: Locale { appState.effectiveLocale }

    var body: some View {
        Form {
            Section {
                HotkeySettingsRow(hotkey: hotkey, target: .dictation)
                Toggle(
                    L10n.t("hotkey.retain_clipboard", locale: locale),
                    isOn: $appState.retainDictationInClipboard
                )
            } header: {
                Text(L10n.t("hotkey.section", locale: locale))
            } footer: {
                Text(
                    hotkey.isRecording && hotkey.captureTarget == .dictation
                        ? L10n.t("hotkey.footer_recording", locale: locale)
                        : L10n.t("hotkey.retain_clipboard_footer", locale: locale)
                )
            }

            Section {
                if appState.transformBindings.isEmpty {
                    Text(L10n.t("transform.bindings_empty", locale: locale))
                        .foregroundStyle(.secondary)
                }

                ForEach(appState.transformBindings) { binding in
                    TransformBindingEditor(
                        appState: appState,
                        hotkey: hotkey,
                        binding: binding,
                        locale: locale
                    )
                }

                Button(L10n.t("transform.binding_add", locale: locale)) {
                    appState.addTransformBinding()
                }
                .disabled(!appState.canAddTransformBinding)

                if appState.selectableTransformModes.isEmpty {
                    Text(L10n.t("transform.model_none", locale: locale))
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text(L10n.t("transform.section", locale: locale))
            } footer: {
                if hotkey.isRecording,
                   case .transformBinding = hotkey.captureTarget {
                    Text(L10n.t("hotkey.footer_recording", locale: locale))
                }
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

private struct TransformBindingEditor: View {
    @ObservedObject var appState: AppState
    @ObservedObject var hotkey: HotkeyService
    let binding: TransformBinding
    let locale: Locale

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HotkeySettingsRow(
                hotkey: hotkey,
                target: .transformBinding(binding.id),
                combinationLabel: L10n.t("transform.binding_hotkey", locale: locale)
            )

            Picker(L10n.t("transform.kind", locale: locale), selection: kindBinding) {
                ForEach(TransformKind.allCases) { kind in
                    Text(kind.title(locale: locale)).tag(kind)
                }
            }

            if appState.selectableTransformModes.isEmpty {
                Text(L10n.t("transform.model_none", locale: locale))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Picker(L10n.t("transform.model", locale: locale), selection: modeBinding) {
                    ForEach(appState.selectableTransformModes) { mode in
                        Text(mode.title(locale: locale)).tag(mode)
                    }
                }
            }

            if binding.kind == .translate {
                HStack(spacing: 8) {
                    Picker("", selection: languageABinding) {
                        ForEach(TransformLanguageCatalog.codes, id: \.self) { code in
                            Text(TransformLanguageCatalog.displayName(code: code, locale: locale)).tag(code)
                        }
                    }
                    .labelsHidden()

                    Text("↔")
                        .foregroundStyle(.secondary)

                    Picker("", selection: languageBBinding) {
                        ForEach(TransformLanguageCatalog.codes, id: \.self) { code in
                            Text(TransformLanguageCatalog.displayName(code: code, locale: locale)).tag(code)
                        }
                    }
                    .labelsHidden()
                }
            } else {
                TextEditor(text: customInstructionBinding)
                    .font(.body)
                    .frame(minHeight: 56, maxHeight: 100)
            }

            HStack {
                Spacer()
                Button(L10n.t("transform.binding_delete", locale: locale), role: .destructive) {
                    appState.removeTransformBinding(id: binding.id)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var kindBinding: Binding<TransformKind> {
        Binding(
            get: { current.kind },
            set: { kind in
                var next = current
                next.kind = kind
                appState.updateTransformBinding(next)
            }
        )
    }

    private var modeBinding: Binding<CleanupMode> {
        Binding(
            get: {
                let modes = appState.selectableTransformModes
                if modes.contains(current.cleanupMode) { return current.cleanupMode }
                return modes.first ?? .smart
            },
            set: { mode in
                var next = current
                next.cleanupMode = mode
                appState.updateTransformBinding(next)
            }
        )
    }

    private var languageABinding: Binding<String> {
        Binding(
            get: { current.languageA },
            set: { code in
                var next = current
                next.languageA = code
                next.ensureDistinctLanguages()
                appState.updateTransformBinding(next)
            }
        )
    }

    private var languageBBinding: Binding<String> {
        Binding(
            get: { current.languageB },
            set: { code in
                var next = current
                next.languageB = code
                next.ensureDistinctLanguages()
                appState.updateTransformBinding(next)
            }
        )
    }

    private var customInstructionBinding: Binding<String> {
        Binding(
            get: { current.customInstruction },
            set: { text in
                var next = current
                next.customInstruction = text
                appState.updateTransformBinding(next)
            }
        )
    }

    private var current: TransformBinding {
        appState.transformBindings.first(where: { $0.id == binding.id }) ?? binding
    }
}
