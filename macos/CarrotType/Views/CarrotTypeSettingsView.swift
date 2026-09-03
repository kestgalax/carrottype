import SwiftUI

/// Native Settings: fixed sidebar + grouped Form detail panes.
/// Uses a plain HStack (not NavigationSplitView) to avoid the blue column focus ring
/// and the sidebar collapse control.
struct CarrotTypeSettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selection: SettingsPane = .general
    @State private var showStatusDetails = false
    @State private var didApplyInitialSelection = false

    private var locale: Locale { appState.effectiveLocale }
    private var needsStatusDetails: Bool {
        appState.readiness != .ready
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: 200)
                .frame(maxHeight: .infinity, alignment: .top)

            Divider()

            detailContent
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .environment(\.locale, locale)
        .onAppear {
            appState.settingsDidAppear()
            applyInitialSelectionIfNeeded()
        }
        .onDisappear {
            appState.settingsDidDisappear()
        }
        .onChange(of: appState.readiness) { _, readiness in
            if readiness == .ready {
                showStatusDetails = false
            }
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 10) {
            SettingsStatusHeader(
                appState: appState,
                showDetailsLink: needsStatusDetails,
                onDetails: {
                    showStatusDetails = true
                }
            )
            .padding(.horizontal, 10)
            .padding(.top, 12)

            VStack(alignment: .leading, spacing: 2) {
                ForEach(SettingsPane.allCases) { pane in
                    sidebarRow(pane)
                }
            }
            .padding(.horizontal, 8)

            Spacer(minLength: 0)
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
                .fill(isSelected ? Color.accentColor.opacity(0.18) : Color.clear)
        )
        .foregroundStyle(isSelected ? Color.primary : Color.primary.opacity(0.85))
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
                GeneralSettingsPane(appState: appState, hotkey: appState.hotkey)
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
        let permissionsOK = appState.permissions.microphoneGranted
            && appState.permissions.accessibilityGranted
        return permissionsOK ? .models : .setup
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
        selection = defaultPane
    }
}
