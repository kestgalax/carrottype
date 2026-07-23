import SwiftUI

/// Native Settings: fixed sidebar + grouped Form detail panes.
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
        NavigationSplitView(columnVisibility: .constant(.all)) {
            VStack(alignment: .leading, spacing: 10) {
                SettingsStatusHeader(
                    appState: appState,
                    showDetailsLink: needsStatusDetails,
                    onDetails: {
                        showStatusDetails = true
                    }
                )
                .padding(.horizontal, 8)
                .padding(.top, 8)

                List(selection: sidebarSelection) {
                    ForEach(SettingsPane.allCases) { pane in
                        Label(pane.title(locale: locale), systemImage: pane.systemImage)
                            .tag(pane)
                    }
                }
                .listStyle(.sidebar)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
        } detail: {
            detailContent
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .navigationSplitViewStyle(.balanced)
        .navigationTitle("carrottype")
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

    /// Clears status-details mode when the user picks a sidebar pane.
    private var sidebarSelection: Binding<SettingsPane?> {
        Binding(
            get: { showStatusDetails || appState.showFirstRun ? nil : selection },
            set: { newValue in
                guard let newValue else { return }
                selection = newValue
                showStatusDetails = false
            }
        )
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
