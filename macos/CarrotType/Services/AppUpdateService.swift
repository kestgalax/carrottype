import AppKit
import Combine
import Sparkle

@MainActor
final class AppUpdateService: NSObject, ObservableObject, SPUUpdaterDelegate {
    let installationGate = UpdateInstallationGate()
    @Published private(set) var canCheckForUpdates = false
    @Published private(set) var automaticallyChecks = false
    @Published private(set) var automaticallyDownloads = false
    @Published private(set) var allowsAutomaticDownloads = false
    @Published private(set) var isWaitingForOperation = false
    private var controller: SPUStandardUpdaterController!
    private var installsOnQuit = false

    override init() {
        super.init()
        installationGate.onChange = { [weak self] in
            guard let self else { return }
            self.isWaitingForOperation = self.installationGate.isWaiting
        }
        controller = SPUStandardUpdaterController(
            startingUpdater: false, updaterDelegate: self, userDriverDelegate: nil
        )
        let updater = controller.updater
        // Do not allow a saved Sparkle preference to re-enable system profiling.
        updater.sendsSystemProfile = false
        updater.publisher(for: \.canCheckForUpdates).assign(to: &$canCheckForUpdates)
        updater.publisher(for: \.automaticallyChecksForUpdates).assign(to: &$automaticallyChecks)
        updater.publisher(for: \.automaticallyDownloadsUpdates).assign(to: &$automaticallyDownloads)
        updater.publisher(for: \.allowsAutomaticUpdates).assign(to: &$allowsAutomaticDownloads)
        controller.startUpdater()
    }

    func checkForUpdates() {
        NSApp.activate(ignoringOtherApps: true)
        controller.checkForUpdates(nil)
    }

    func setAutomaticallyChecks(_ value: Bool) {
        controller.updater.automaticallyChecksForUpdates = value
    }

    func setAutomaticallyDownloads(_ value: Bool) {
        controller.updater.automaticallyDownloadsUpdates = value
    }

    func updater(_ updater: SPUUpdater, shouldPostponeRelaunchForUpdate item: SUAppcastItem,
                 untilInvokingBlock installHandler: @escaping () -> Void) -> Bool {
        installationGate.postponeInstallation(installHandler)
    }

    func updater(_ updater: SPUUpdater, willInstallUpdateOnQuit item: SUAppcastItem,
                 immediateInstallationBlock immediateInstallHandler: @escaping () -> Void) -> Bool {
        installsOnQuit = true
        // Keep Sparkle's standard install-on-quit behavior; never force a background restart.
        return false
    }

    func updater(_ updater: SPUUpdater, willInstallUpdate item: SUAppcastItem) {
        installsOnQuit = true
    }

    func updater(_ updater: SPUUpdater, didAbortWithError error: Error) {
        installsOnQuit = false
        installationGate.resetInstallation()
    }

    /// Sparkle may skip the postponement delegate when resuming an earlier installer.
    /// NSApplication asks here immediately before termination, after any new operation.
    func shouldTerminate() -> NSApplication.TerminateReply {
        guard installsOnQuit || installationGate.isWaiting || installationGate.isInstalling else {
            return .terminateNow
        }
        guard installationGate.prepareForTermination() else {
            NSApp.activate(ignoringOtherApps: true)
            let alert = NSAlert()
            alert.messageText = L10n.t("updates.waiting", locale: L10n.preferredLocale)
            alert.informativeText = L10n.t("updates.waiting_detail", locale: L10n.preferredLocale)
            alert.runModal()
            return .terminateCancel
        }
        return .terminateNow
    }
}

@MainActor
final class CarrotTypeApplicationDelegate: NSObject, NSApplicationDelegate {
    weak var updates: AppUpdateService?

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        updates?.shouldTerminate() ?? .terminateNow
    }
}
