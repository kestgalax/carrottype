import SwiftUI

struct FormattingRulesSection: View {
    @ObservedObject var appState: AppState
    let locale: Locale
    @State private var showTrial = false
    @State private var trialInput = ""
    private var usesModel: Bool { appState.modelManager.cleanupMode.usesMLXHelper }
    private func t(_ key: String) -> String { L10n.t(key, locale: locale) }

    var body: some View {
        Section {
            if usesModel {
                Text(t("rules.intent")).font(.caption).foregroundStyle(.secondary)
                Toggle(t("rules.fillers"), isOn: $appState.dictationRules.removeFillers)
                Toggle(t("rules.repetitions"), isOn: $appState.dictationRules.removeRepetitions)
                Toggle(t("rules.corrections"), isOn: $appState.dictationRules.applySelfCorrections)
                Picker(t("rules.layout"), selection: $appState.dictationRules.paragraphs) {
                    Text(t("rules.preserve")).tag(false)
                    Text(t("rules.paragraphs")).tag(true)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(t("rules.custom"))
                    TextEditor(text: $appState.dictationRules.customRules)
                        .scrollIndicators(.automatic)
                        .font(.body).frame(height: 64)
                        .accessibilityLabel(t("rules.custom"))
                    Text(t("rules.examples")).font(.caption).foregroundStyle(.secondary)
                    Text("\(appState.dictationRules.customRules.count)/\(DictationRules.customLimit)")
                        .font(.caption).foregroundStyle(.secondary)
                }
                DisclosureGroup(t("rules.summary")) {
                    Text(t("rules.intent"))
                    ForEach(summary, id: \.self) { Text($0).font(.caption).foregroundStyle(.secondary) }
                    if !appState.dictationRules.customRules.isEmpty {
                        Text(appState.dictationRules.customRules).textSelection(.enabled)
                    }
                }
                Button(t("rules.reset")) { appState.dictationRules = DictationRules() }
            } else {
                Text(t("rules.no_model")).font(.caption).foregroundStyle(.secondary)
            }
            DisclosureGroup(t("rules.trial"), isExpanded: $showTrial) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(t("rules.trial_hint")).font(.caption).foregroundStyle(.secondary)
                    TextEditor(text: $trialInput).frame(height: 78)
                        .scrollIndicators(.automatic)
                        .accessibilityLabel(t("rules.trial_input"))
                        .disabled(appState.isFormattingTrialRunning)
                        .onChange(of: trialInput) { _, value in
                            if value.count > 6000 { trialInput = String(value.prefix(6000)) }
                            appState.clearFormattingTrial()
                        }
                    HStack {
                        Button(t("rules.try")) { appState.runFormattingTrial(trialInput) }
                            .disabled(!appState.canRunFormattingTrial || trialInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        if appState.isFormattingTrialRunning {
                            ProgressView().controlSize(.small)
                            Button(t("rules.cancel")) { appState.cancelFormattingTrial() }
                        }
                    }
                    if let error = appState.formattingTrialError { Text(error).foregroundStyle(.red) }
                    if let result = appState.formattingTrialResult {
                        Text(t("rules.result") + (appState.formattingTrialOutcome.map { " · " + $0.actualMode.title(locale: locale) } ?? ""))
                            .font(.caption).foregroundStyle(.secondary)
                        Text(result.isEmpty ? t("rules.empty") : result)
                            .textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
                        if appState.formattingTrialOutcome?.usedFallback == true {
                            Label(t("rules.fallback"), systemImage: "exclamationmark.triangle").font(.callout).foregroundStyle(.orange)
                        }
                    }
                }
            }
        } header: { Text(t("rules.title")) }
        footer: { Text(t("rules.next_session")).font(.caption) }
        .onDisappear { appState.clearFormattingTrial() }
    }

    private var summary: [String] {
        let r = appState.dictationRules
        return [("rules.fillers", r.removeFillers), ("rules.repetitions", r.removeRepetitions),
                ("rules.corrections", r.applySelfCorrections)].map { t($0.0) + ": " + t($0.1 ? "rules.on" : "rules.off") }
            + [t(r.paragraphs ? "rules.paragraphs" : "rules.preserve")]
    }
}
