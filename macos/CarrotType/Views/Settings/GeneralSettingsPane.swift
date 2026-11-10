import SwiftUI

struct GeneralSettingsPane: View {
    @ObservedObject var appState: AppState
    @ObservedObject var hotkey: HotkeyService
    let onOpenModels: () -> Void
    @State private var expandedBindingIDs = Set<UUID>()

    private var locale: Locale { appState.effectiveLocale }

    private var liveDraftFooter: String {
        if appState.activeSTTSupportsStreaming {
            return L10n.t("hotkey.live_draft_footer", locale: locale)
        }
        return L10n.t("hotkey.live_draft_unavailable", locale: locale)
    }

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
                SettingsToggleRow(
                    title: L10n.t("hotkey.live_draft", locale: locale),
                    hint: liveDraftFooter,
                    isOn: $appState.liveDraftEnabled,
                    isEnabled: appState.activeSTTSupportsStreaming
                )
            } header: {
                Text(L10n.t("hotkey.section", locale: locale))
            }

            GeneralFormattingSection(models: appState.modelManager, locale: locale, onOpenModels: onOpenModels)

            FormattingRulesSection(appState: appState, locale: locale)

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
                        locale: locale,
                        expanded: Binding(
                            get: { expandedBindingIDs.contains(binding.id) },
                            set: { if $0 { expandedBindingIDs.insert(binding.id) } else { expandedBindingIDs.remove(binding.id) } }
                        ),
                        onOpenModels: onOpenModels
                    )
                }

                Button(L10n.t("transform.binding_add", locale: locale)) {
                    let count = appState.transformBindings.count
                    appState.addTransformBinding()
                    if appState.transformBindings.count > count, let added = appState.transformBindings.last {
                        expandedBindingIDs.insert(added.id)
                    }
                }
                .disabled(!appState.canAddTransformBinding)

                if appState.selectableTransformModes.isEmpty {
                    Text(L10n.t("transform.model_none", locale: locale))
                        .foregroundStyle(.secondary)
                    Button(L10n.t("status.open_models", locale: locale), action: onOpenModels)
                }
            } header: {
                Text(L10n.t("transform.section", locale: locale))
            } footer: {
                if hotkey.isRecording,
                   case .transformBinding = hotkey.captureTarget {
                    Text(L10n.t("hotkey.footer_recording", locale: locale))
                }
            }

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
        }
        .formStyle(.grouped)
        .onDisappear {
            if hotkey.isRecording { hotkey.cancelRecording() }
        }
    }
}

private struct TransformBindingEditor: View {
    @ObservedObject var appState: AppState
    @ObservedObject var hotkey: HotkeyService
    let binding: TransformBinding
    let locale: Locale
    @Binding var expanded: Bool
    let onOpenModels: () -> Void

    var body: some View {
        DisclosureGroup(isExpanded: $expanded) {
            editor.padding(.top, 8)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(current.kind.title(locale: locale))
                    Text(current.kind == .translate
                         ? "\(TransformLanguageCatalog.shortLabel(code: current.languageA)) ↔ \(TransformLanguageCatalog.shortLabel(code: current.languageB))"
                         : (current.customInstruction.isEmpty ? L10n.t("transform.instruction_required", locale: locale) : current.customInstruction))
                        .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 3) {
                    Text(current.chord.displayString).monospaced()
                    Text(current.cleanupMode.title(locale: locale)).font(.caption).foregroundStyle(.secondary)
                }
                if !appState.transformModes(for: current.cleanupMode).contains(current.cleanupMode) {
                    Image(systemName: "exclamationmark.circle").foregroundStyle(.orange)
                }
            }
            .padding(.vertical, 4)
        }
        .onChange(of: expanded) { _, isExpanded in
            if !isExpanded { cancelHotkeyCaptureIfNeeded() }
        }
        .onDisappear { cancelHotkeyCaptureIfNeeded() }
    }

    private func cancelHotkeyCaptureIfNeeded() {
        if hotkey.captureTarget == .transformBinding(binding.id) { hotkey.cancelRecording() }
    }

    private var editor: some View {
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

            Picker(L10n.t("transform.model", locale: locale), selection: modeBinding) {
                if !appState.transformModes(for: current.cleanupMode).contains(current.cleanupMode) {
                    Text(String(format: L10n.t("transform.model_unavailable", locale: locale), current.cleanupMode.title(locale: locale)))
                        .tag(current.cleanupMode)
                        .disabled(true)
                }
                ForEach(appState.transformModes(for: current.cleanupMode)) { mode in
                    Text(mode.title(locale: locale)).tag(mode)
                }
            }
            if !appState.transformModes(for: current.cleanupMode).contains(current.cleanupMode) {
                if let fallback = TransformModelSelection.resolve(requested: current.cleanupMode, available: appState.transformModes(for: current.cleanupMode)) {
                    Text(String(format: L10n.t("transform.model_fallback", locale: locale), current.cleanupMode.title(locale: locale), fallback.title(locale: locale)))
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    Text(L10n.t("transform.model_none", locale: locale)).font(.caption).foregroundStyle(.secondary)
                }
                Button(L10n.t("status.open_models", locale: locale), action: onOpenModels)
            }

            if current.kind == .translate {
                HStack(spacing: 8) {
                    Picker(L10n.t("transform.language_a", locale: locale), selection: languageABinding) {
                        ForEach(TransformLanguageCatalog.codes, id: \.self) { code in
                            Text(TransformLanguageCatalog.displayName(code: code, locale: locale)).tag(code)
                        }
                    }
                    .labelsHidden()

                    Text("↔")
                        .foregroundStyle(.secondary)

                    Picker(L10n.t("transform.language_b", locale: locale), selection: languageBBinding) {
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
                    .accessibilityLabel(L10n.t("transform.instruction_label", locale: locale))
                if current.customInstruction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(L10n.t("transform.instruction_required", locale: locale))
                        .font(.caption).foregroundStyle(.orange)
                }
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
            get: { current.cleanupMode },
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

/// Shares the exact selection/status source with Models, including Ready-only choices.
private struct GeneralFormattingSection: View {
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
