import SwiftUI

/// Native Settings: fixed sidebar + grouped Form detail panes.
/// Uses a plain HStack (not NavigationSplitView) to avoid the blue column focus ring
/// and the sidebar collapse control.
struct CarrotTypeSettingsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var focusedPane: SettingsPane?
    @State private var selection: SettingsPane = .general
    @State private var showStatusDetails = false
    @State private var didApplyInitialSelection = false

    /// Fixture-only initial selection; `nil` preserves normal runtime behavior.
    private let initialPane: SettingsPane?

    init(initialPane: SettingsPane? = nil) {
        self.initialPane = initialPane
    }

    private var locale: Locale { appState.effectiveLocale }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: AppStyle.sidebarWidth)
                .frame(maxHeight: .infinity, alignment: .top)

            Divider()

            VStack(spacing: 0) {
                if !appState.showFirstRun {
                    SettingsPaneHeading(
                        title: showStatusDetails ? L10n.t("settings.details_title", locale: locale) : selection.title(locale: locale),
                        subtitle: L10n.t("settings.description.\(showStatusDetails ? "details" : selection.rawValue)", locale: locale)
                    )
                }
                detailContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .environment(\.locale, locale)
        .tint(AppStyle.controlAccent)
        .onAppear {
            appState.settingsDidAppear()
            applyInitialSelectionIfNeeded()
        }
        .onDisappear {
            appState.settingsDidDisappear()
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 9) {
                Image("CarrotMark").resizable().renderingMode(.template)
                    .scaledToFit().frame(width: 22, height: 28)
                    .foregroundStyle(AppStyle.accent(colorScheme)).accessibilityHidden(true)
                Text("CarrotType").font(.headline)
            }
            .padding(.horizontal, 18).padding(.top, 22).padding(.bottom, 16)

            VStack(alignment: .leading, spacing: 2) {
                ForEach(SettingsPane.allCases) { pane in
                    sidebarRow(pane)
                }
            }
            .padding(.horizontal, 8)

            Spacer(minLength: 12)

            SettingsStatusHeader(appState: appState, showDetailsLink: true) {
                showStatusDetails = true
            }
            .padding(.horizontal, 10)
            WhatsNewButton(notes: appState.updates.releaseNotes, locale: locale)
                .controlSize(.small)
                .padding(.horizontal, 20)
                .padding(.bottom, 18)
        }
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.35))
    }

    private func sidebarRow(_ pane: SettingsPane) -> some View {
        let isSelected = !showStatusDetails && !appState.showFirstRun && selection == pane
        return Button {
            selection = pane
            showStatusDetails = false
        } label: {
            Label(pane.title(locale: locale), systemImage: pane.systemImage)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isSelected ? AppStyle.accent(colorScheme).opacity(0.14) : Color.clear)
        )
        .foregroundStyle(isSelected ? Color.primary : Color.primary.opacity(0.85))
        .focused($focusedPane, equals: pane)
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(focusedPane == pane ? AppStyle.accent(colorScheme) : .clear, lineWidth: 2)
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var detailContent: some View {
        if appState.showFirstRun {
            FirstRunWelcomePane(appState: appState) {
                selection = paneAfterFirstRun
                showStatusDetails = false
            }
        } else if showStatusDetails {
            StatusDetailsPane(
                appState: appState,
                models: appState.modelManager,
                onOpenSetup: {
                    selection = .setup
                    showStatusDetails = false
                },
                onOpenModels: {
                    selection = .models
                    showStatusDetails = false
                }
            )
        } else {
            switch selection {
            case .general:
                GeneralSettingsPane(appState: appState, hotkey: appState.hotkey, onOpenModels: {
                    selection = .models
                    showStatusDetails = false
                })
            case .dynamicIsland:
                DynamicIslandSettingsPane(appState: appState)
            case .setup:
                SetupSettingsPane(appState: appState, permissions: appState.permissions)
            case .models:
                ModelsSettingsPane(
                    appState: appState,
                    models: appState.modelManager
                )
            case .storage:
                StorageSettingsPane(appState: appState, models: appState.modelManager)
            case .statistics:
                StatisticsSettingsPane(appState: appState, usageStats: appState.usageStats)
            }
        }
    }

    private var paneAfterFirstRun: SettingsPane {
        .setup
    }

    private var defaultPane: SettingsPane {
        appState.readiness == .ready ? .general : .setup
    }

    private func applyInitialSelectionIfNeeded() {
        guard !didApplyInitialSelection else { return }
        didApplyInitialSelection = true
        if appState.showFirstRun {
            return
        }
        selection = initialPane ?? defaultPane
    }
}
