import SwiftUI

/// Settings → Dynamic Island: presentation mode and the moved live-draft switch.
struct DynamicIslandSettingsPane: View {
    @ObservedObject var appState: AppState

    private var locale: Locale { appState.effectiveLocale }

    private var liveDraftControlEnabled: Bool {
        appState.dynamicIslandMode == .full && appState.activeSTTSupportsStreaming
    }

    private var liveDraftHint: String {
        if appState.dynamicIslandMode != .full {
            return L10n.t("island.live_draft_disabled", locale: locale)
        }
        if !appState.activeSTTSupportsStreaming {
            return L10n.t("hotkey.live_draft_unavailable", locale: locale)
        }
        return L10n.t("hotkey.live_draft_footer", locale: locale)
    }

    var body: some View {
        Form {
            Section {
                Picker(L10n.t("island.mode.title", locale: locale), selection: $appState.dynamicIslandMode) {
                    ForEach(DynamicIslandMode.allCases) { mode in
                        Text(mode.title(locale: locale)).tag(mode)
                    }
                }
                .pickerStyle(.radioGroup)

                Text(appState.dynamicIslandMode.detail(locale: locale))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if appState.dynamicIslandMode == .menuOnly {
                    Text(L10n.t("island.menu_only_note", locale: locale))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } header: {
                Text(L10n.t("island.mode.section", locale: locale))
            }

            Section {
                DynamicIslandSettingsPreview(locale: locale)
            } header: {
                Text(L10n.t("island.preview.title", locale: locale))
            }

            Section {
                SettingsToggleRow(
                    title: L10n.t("hotkey.live_draft", locale: locale),
                    hint: liveDraftHint,
                    isOn: $appState.liveDraftEnabled,
                    isEnabled: liveDraftControlEnabled
                )
            } footer: {
                Text(L10n.t("island.footer", locale: locale))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .formStyle(.grouped)
        .scrollIndicators(.never)
    }
}

/// Synthetic recording/processing chrome from the same views as the real indicator.
/// It never captures audio, touches models/WAV/clipboard/statistics, or opens a status panel.
private struct DynamicIslandSettingsPreview: View {
    let locale: Locale

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            tile(
                title: L10n.t("island.preview.recording", locale: locale),
                content: { RecordingGlowBar(width: 44) }
            )
            tile(
                title: L10n.t("island.preview.processing", locale: locale),
                content: {
                    ProcessingDots(
                        diameter: MinimalIslandMetrics.dotDiameter,
                        spacing: MinimalIslandMetrics.dotSpacing,
                        ink: .orange
                    )
                }
            )
            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)

        Text(L10n.t("island.preview.caption", locale: locale))
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.top, 2)
    }

    private func tile<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.black)
                content()
                    .frame(height: 18)
            }
            .frame(width: 116, height: 24)
            .overlay {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.14), lineWidth: 0.5)
            }

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 150, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
