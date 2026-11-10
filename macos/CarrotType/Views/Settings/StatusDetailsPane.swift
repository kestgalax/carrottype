import AppKit
import SwiftUI

/// Full Status checklist shown via Details… (not a sidebar item).
struct StatusDetailsPane: View {
    @ObservedObject var appState: AppState
    @ObservedObject var models: ModelManager
    let onOpenSetup: () -> Void
    let onOpenModels: () -> Void

    private var locale: Locale { appState.effectiveLocale }

    var body: some View {
        Form {
            Section {
                LabeledContent {
                    Text(appState.readiness.title(locale: locale))
                        .foregroundStyle(readinessColor)
                        .fontWeight(.semibold)
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("CarrotType")
                        Text(appVersionLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        WhatsNewButton(notes: appState.updates.releaseNotes, locale: locale)
                    }
                }

                if !appState.permissions.microphoneGranted {
                    Button {
                        onOpenSetup()
                    } label: {
                        Label(L10n.t("hint.microphone", locale: locale), systemImage: "mic.fill")
                    }
                }

                if !appState.permissions.accessibilityGranted {
                    Button {
                        onOpenSetup()
                    } label: {
                        Label(L10n.t("hint.accessibility", locale: locale), systemImage: "hand.raised.fill")
                    }
                }

                if models.activeSTTStatus != .ready {
                    Button {
                        onOpenModels()
                    } label: {
                        Label(L10n.t("hint.stt_model", locale: locale), systemImage: "cpu")
                    }
                }

                if let error = appState.lastSessionError {
                    Text(L10n.t("status.last_error", locale: locale))
                        .font(.headline)
                    Text(error)
                        .foregroundStyle(.red)
                    Button(L10n.t("status.dismiss_error", locale: locale)) {
                        appState.dismissSessionError()
                    }
                }
                if let error = models.lastErrorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                    Button(L10n.t("status.open_models", locale: locale), action: onOpenModels)
                }
                if appState.lastSessionError != nil {
                    Button(L10n.t("status.open_setup", locale: locale), action: onOpenSetup)
                }
                if appState.lastDictationText != nil {
                    Button(L10n.t("recovery.copy_last", locale: locale)) {
                        appState.copyLastDictation()
                    }
                    Button(L10n.t("recovery.clear_last", locale: locale)) {
                        appState.clearLastDictation()
                    }
                    Text(L10n.t("recovery.memory_hint", locale: locale))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let outcome = appState.lastFormattingOutcome {
                    Text(L10n.t("format.last_dictation", locale: locale)).font(.headline)
                    FormattingOutcomeView(outcome: outcome, locale: locale)
                }
                CheckForAppUpdatesButton(updates: appState.updates, locale: locale)
            } header: {
                Text(L10n.t("status.section", locale: locale))
            } footer: {
                if !appState.remainingHints.isEmpty {
                    Text(
                        String(
                            format: L10n.t("status.remaining", locale: locale),
                            appState.remainingHints.joined(separator: ", ")
                        )
                    )
                }
            }
        }
        .formStyle(.grouped)
    }

    private var appVersionLabel: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "—"
        return "v\(version)"
    }

    private var readinessColor: Color {
        switch appState.readiness {
        case .ready: return .green
        case .almost: return .orange
        case .blocked: return .red
        }
    }
}
