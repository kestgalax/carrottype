import Foundation

/// Small ownership boundary for the typing test. It holds the existing install gate
/// only while a run is actually in progress, and suspends only CarrotType's global
/// hotkeys while the test input owns focus. Every release is idempotent.
@MainActor
final class TypingSpeedTestCoordinator {
    enum Interaction: Equatable {
        case idle
        case focused
        case running
    }

    private let gate: UpdateInstallationGate
    private let hotkey: HotkeyService
    private var lease: UUID?
    private var suspension: UUID?

    private(set) var interaction: Interaction = .idle
    /// Called for app deactivation/sleep/settings close/quit/install when an active
    /// test must return to Ready without applying a result.
    var onInvalidated: (() -> Void)?

    init(gate: UpdateInstallationGate, hotkey: HotkeyService) {
        self.gate = gate
        self.hotkey = hotkey
    }

    var isRunning: Bool { interaction == .running }
    var isInputFocused: Bool { interaction != .idle }

    /// Entry to the ready/armed state. No install-gate lease is held yet.
    @discardableResult
    func acquireInputFocus() -> Bool {
        if interaction == .focused { return true }
        guard interaction == .idle else { return false }
        guard !gate.isBusy, !gate.isInstalling, !gate.isWaiting else { return false }
        suspension = hotkey.suspendGlobalHotkeys()
        interaction = .focused
        return true
    }

    /// First committed printable grapheme: reserve the shared operation gate.
    @discardableResult
    func beginRun() -> Bool {
        guard interaction == .focused, lease == nil else { return false }
        guard !gate.isBusy, !gate.isInstalling, !gate.isWaiting else { return false }
        guard let lease = gate.beginOperation() else { return false }
        self.lease = lease
        interaction = .running
        return true
    }

    /// Completion/cancel of the timed attempt. The result screen does not hold the gate.
    func finishRun() {
        if let lease {
            gate.endOperation(lease)
            self.lease = nil
        }
        if interaction == .running {
            interaction = .focused
        }
    }

    /// Remove input focus and restore app hotkeys. Safe to call repeatedly.
    func releaseFocus() {
        if let lease {
            gate.endOperation(lease)
            self.lease = nil
        }
        if let suspension {
            hotkey.resumeGlobalHotkeys(suspension)
            self.suspension = nil
        }
        interaction = .idle
    }

    /// Lifecycle cancellation requested outside the sheet. The view model observes
    /// `onInvalidated` and returns to Ready with a fresh prompt.
    func invalidate() {
        let wasActive = interaction != .idle
        releaseFocus()
        if wasActive {
            onInvalidated?()
        }
    }
}
