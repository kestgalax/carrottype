import SwiftUI

/// Compact Ready / Almost / Blocked strip at the top of the Settings sidebar.
struct SettingsStatusHeader: View {
    @ObservedObject var appState: AppState
    let showDetailsLink: Bool
    let onDetails: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var locale: Locale { appState.effectiveLocale }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Circle()
                    .fill(readinessColor)
                    .frame(width: 8, height: 8)
                Text(appState.readiness.title(locale: locale))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(readinessColor)
                Spacer(minLength: 0)
            }

            Text(appVersionLabel)
                .font(.caption)
                .foregroundStyle(.secondary)

            if appState.lastSessionError != nil || appState.modelManager.lastErrorMessage != nil {
                Label(L10n.t("status.last_error", locale: locale), systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            if !appState.hasCompletedSetupTrial {
                Text(String(format: L10n.t("setup.progress", locale: locale), appState.setupProgress.completedCount))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if showDetailsLink {
                Button(L10n.t("status.details", locale: locale), action: onDetails)
                    .buttonStyle(.plain)
                    .foregroundStyle(AppStyle.accent(colorScheme))
                    .font(.caption)
                    .accessibilityIdentifier("settings.footer.details")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)

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
