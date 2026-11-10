import SwiftUI

struct SetupProgressView: View {
    @ObservedObject var appState: AppState
    private var locale: Locale { appState.effectiveLocale }

    var body: some View {
        let progress = appState.setupProgress
        VStack(alignment: .leading, spacing: 8) {
            Text(String(format: L10n.t("setup.progress", locale: locale), progress.completedCount))
                .font(.headline)
            ForEach(SetupProgress.Step.allCases, id: \.rawValue) { step in
                Label {
                    Text(L10n.t(step.titleKey, locale: locale))
                        .fontWeight(progress.nextStep == step ? .semibold : .regular)
                } icon: {
                    Image(systemName: progress.isComplete(step) ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(progress.isComplete(step) ? Color.green : Color.secondary)
                }
            }
            if let next = progress.nextStep {
                Text(L10n.t("setup.next.\(next.rawValue)", locale: locale))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text(L10n.t("setup.finished", locale: locale))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct SetupTrialSection: View {
    @ObservedObject var appState: AppState
    private var locale: Locale { appState.effectiveLocale }

    var body: some View {
        Section {
            Text(L10n.t("setup.trial_hint", locale: locale))
                .foregroundStyle(.secondary)
            if appState.isSetupTrialActive {
                HStack {
                    if appState.menuBarMode == .recording {
                        Button(L10n.t("setup.trial_stop", locale: locale)) { appState.finishSetupTrial() }
                            .buttonStyle(.borderedProminent)
                    } else {
                        ProgressView().controlSize(.small)
                        Text(L10n.t(appState.isSetupTrialCancelling ? "setup.trial_cancelling" : "setup.trial_processing", locale: locale))
                    }
                    Button(L10n.t("package.cancel", locale: locale)) { appState.cancelSetupTrial() }
                        .disabled(appState.isSetupTrialCancelling)
                }
            } else {
                Button(L10n.t("setup.trial_start", locale: locale)) { appState.startSetupTrial() }
                    .buttonStyle(.borderedProminent)
                    .disabled(!appState.canStartSetupTrial)
            }
            if appState.readiness != .ready {
                Text(L10n.t("setup.trial_not_ready", locale: locale))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            TextEditor(text: $appState.setupTrialText)
                .font(.body)
                .frame(minHeight: 88)
                .disabled(appState.isSetupTrialActive)
                .accessibilityLabel(L10n.t("setup.trial_result", locale: locale))
            if let outcome = appState.setupTrialFormatting {
                FormattingOutcomeView(outcome: outcome, locale: locale)
            }
            if let error = appState.lastSessionError {
                Text(error).font(.caption).foregroundStyle(.red)
            }
        } header: {
            Text(L10n.t("setup.step.trial", locale: locale))
        } footer: {
            Text(String(format: L10n.t("setup.trial_hotkey_hint", locale: locale), appState.hotkey.displayString))
        }
    }
}

struct FormattingOutcomeView: View {
    let outcome: FormattingOutcome
    let locale: Locale

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(String(format: L10n.t("format.actual", locale: locale), outcome.actualMode.title(locale: locale)))
            if let reason = outcome.fallbackReason {
                Text(String(format: L10n.t(reason == .modelUnavailable ? "format.fallback_missing" : "format.fallback_failed", locale: locale),
                            outcome.requestedMode.title(locale: locale)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
