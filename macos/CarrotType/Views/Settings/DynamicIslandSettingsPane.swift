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
                IslandModeSelector(appState: appState, locale: locale)

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
                DynamicIslandSettingsPreview(
                    mode: appState.dynamicIslandMode,
                    showLiveDraft: appState.liveDraftEnabled && appState.activeSTTSupportsStreaming,
                    locale: locale
                )
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

/// Vertical radio list. A horizontal native radio group truncates long localized labels
/// in the real 519 pt detail column at the minimum Settings window width.
private struct IslandModeSelector: View {
    @ObservedObject var appState: AppState
    let locale: Locale

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            ForEach(DynamicIslandMode.allCases) { mode in
                let selected = appState.dynamicIslandMode == mode
                Button {
                    appState.dynamicIslandMode = mode
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                            .font(.system(size: 13))
                            .foregroundStyle(selected ? AppStyle.accent(colorScheme) : Color.secondary)
                        Text(mode.title(locale: locale))
                            .foregroundStyle(.primary)
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
                .accessibilityLabel(mode.title(locale: locale))
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(L10n.t("island.mode.title", locale: locale))
    }
}

/// Synthetic recording/processing chrome from the same views as the selected real mode.
/// It never captures audio, touches models/WAV/clipboard/statistics, or opens a status panel.
private struct DynamicIslandSettingsPreview: View {
    let mode: DynamicIslandMode
    let showLiveDraft: Bool
    let locale: Locale

    private var canvasHeight: CGFloat {
        mode == .full && showLiveDraft ? 104 : 44
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 14) {
                tile(title: L10n.t("island.preview.recording", locale: locale), phase: .listening)
                tile(title: L10n.t("island.preview.processing", locale: locale), phase: .understanding)
                Spacer(minLength: 0)
            }

            Text(L10n.t("island.preview.synthetic", locale: locale))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 2)
        .allowsHitTesting(false)
    }

    private func tile(title: String, phase: StatusCapsulePhase) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.primary.opacity(0.06))
                previewContent(phase: phase)
            }
            .frame(width: 210, height: canvasHeight)
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.5)
            }

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 210, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func previewContent(phase: StatusCapsulePhase) -> some View {
        switch mode {
        case .full:
            fullCapsule(phase: phase)
        case .minimal:
            minimalIndicator(phase: phase)
        case .menuOnly:
            menuBarGlyph(phase: phase)
        }
    }

    private func fullCapsule(phase: StatusCapsulePhase) -> some View {
        let hasDraft = phase == .listening && showLiveDraft
        return StatusCapsuleView(
            phase: phase,
            resultText: "",
            direction: nil,
            copiedFeedback: false,
            liveConfirmed: hasDraft ? L10n.t("island.preview.live_text", locale: locale) : "",
            liveVolatile: "",
            topInset: 0,
            locale: locale,
            onCopy: {},
            onClose: {}
        )
        .frame(width: hasDraft ? 196 : 148, height: hasDraft ? 96 : 36)
    }

    private func minimalIndicator(phase: StatusCapsulePhase) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color.black)
            MinimalStatusIndicatorView(
                phase: phase,
                topInset: 0,
                barWidth: 44,
                locale: locale
            )
        }
        .frame(width: 116, height: 24)
    }

    private func menuBarGlyph(phase: StatusCapsulePhase) -> some View {
        let mode: MenuBarMode = phase == .understanding ? .processing : .recording
        return ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color.black)
            MenuBarStatusAppearance.image(for: mode)
                .renderingMode(.template)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(MenuBarStatusAppearance.color(for: mode))
                .font(.system(size: 15, weight: .medium))
        }
        .frame(width: 116, height: 24)
    }
}
