import Foundation

/// Main-thread reservation shared by operation entry points and Sparkle's install handoff.
/// Reserve before creating a Task; a menu-bar status alone misses queued starts/teardown.
@MainActor
final class UpdateInstallationGate {
    private var operations = Set<UUID>()
    private var postponedInstall: (() -> Void)?
    private(set) var isInstalling = false
    /// True after Sparkle prepared a background update for silent installation on quit.
    private(set) var hasPendingInstallOnQuit = false
    var onChange: (() -> Void)?

    var isBusy: Bool { !operations.isEmpty }
    var isWaiting: Bool { postponedInstall != nil }

    func beginOperation() -> UUID? {
        guard !isInstalling else { return nil }
        let token = UUID()
        operations.insert(token)
        onChange?()
        return token
    }

    func markInstallOnQuitPending() {
        hasPendingInstallOnQuit = true
        onChange?()
    }

    func endOperation(_ token: UUID) {
        guard operations.remove(token) != nil else { return }
        if !isBusy, let install = postponedInstall {
            postponedInstall = nil
            // No await: new hotkeys cannot slip between the last operation and installation.
            isInstalling = true
            onChange?()
            install()
        } else {
            onChange?()
        }
    }

    /// Return true to let Sparkle retain this callback; false continues immediately.
    func postponeInstallation(_ install: @escaping () -> Void) -> Bool {
        if isBusy {
            postponedInstall = install
            onChange?()
            return true
        }
        isInstalling = true
        onChange?()
        return false
    }

    /// Final synchronous check, including install-on-quit/resumed installer paths.
    /// Returning false means the caller must drain active operations first; it must
    /// never cancel the user's quit on our behalf.
    func prepareForTermination() -> Bool {
        guard !isBusy else { return false }
        postponedInstall = nil // a quit is not a relaunch request; do not force one
        // Lock new operations only when an install is actually staged; an
        // ordinary quit must not leave the gate permanently locked if AppKit
        // or a test inspects it afterwards.
        if hasPendingInstallOnQuit || isInstalling {
            isInstalling = true
        }
        onChange?()
        return true
    }

    func resetInstallation() {
        postponedInstall = nil
        hasPendingInstallOnQuit = false
        isInstalling = false
        onChange?()
    }
}
