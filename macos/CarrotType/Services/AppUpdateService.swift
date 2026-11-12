import AppKit
import Combine
import Sparkle

@MainActor
final class AppUpdateService: NSObject, ObservableObject, SPUUpdaterDelegate {
    let installationGate = UpdateInstallationGate()
    let releaseNotes = ReleaseNotesStore()
    @Published private(set) var canCheckForUpdates = false
    @Published private(set) var automaticallyChecks = false
    @Published private(set) var automaticallyDownloads = false
    @Published private(set) var allowsAutomaticDownloads = false
    @Published private(set) var isWaitingForOperation = false
    @Published private(set) var installsOnQuit = false
    private var controller: SPUStandardUpdaterController!

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
        installationGate.markInstallOnQuitPending()
        // Returning false is Sparkle's documented install-on-quit path: the
        // installer tool stays alive and applies the staged update after this
        // process exits, without relaunching the app. Returning true and
        // invoking the handler would force an immediate relaunch (ADR-017).
        return false
    }

    func updater(_ updater: SPUUpdater, willInstallUpdate item: SUAppcastItem) {
        installsOnQuit = true
        installationGate.markInstallOnQuitPending()
    }

    func updater(_ updater: SPUUpdater, didAbortWithError error: Error) {
        installsOnQuit = false
        installationGate.resetInstallation()
    }

    /// Called by `AppState.prepareForQuit` after any active operation has been
    /// drained. It must never cancel a quit: AppKit's terminateLater reply is
    /// owned by the caller, so busy work is drained rather than refused.
    func prepareForTermination() -> Bool {
        installationGate.prepareForTermination()
    }
}
