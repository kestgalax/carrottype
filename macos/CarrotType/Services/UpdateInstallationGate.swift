import Foundation

/// Main-thread reservation shared by operation entry points and Sparkle's install handoff.
/// Reserve before creating a Task; a menu-bar status alone misses queued starts/teardown.
@MainActor
final class UpdateInstallationGate {
    private var operations = Set<UUID>()
    private var postponedInstall: (() -> Void)?
    private(set) var isInstalling = false
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
    func prepareForTermination() -> Bool {
        guard !isBusy else { return false }
        isInstalling = true
        onChange?()
        return true
    }

    func resetInstallation() {
        postponedInstall = nil
        isInstalling = false
        onChange?()
    }
}
