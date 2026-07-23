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

                if let error = appState.lastSessionError ?? models.lastErrorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                }

                Button(L10n.t("status.check_updates", locale: locale)) {
                    if let url = URL(string: "https://github.com/kestgalax/carrottype/releases") {
                        NSWorkspace.shared.open(url)
                    }
                }
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
