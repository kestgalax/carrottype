import Foundation

@main
struct UpdateInstallationGateChecks {
    @MainActor static func main() {
        let gate = UpdateInstallationGate()
        // Reserve synchronously before Tasks run; a queued start is already busy.
        let capture = gate.beginOperation()!
        var installs = 0
        precondition(gate.postponeInstallation {
            precondition(!gate.isBusy && gate.isInstalling)
            precondition(gate.beginOperation() == nil) // no new hotkey at handoff
            installs += 1
        })
        precondition(gate.isWaiting)
        precondition(!gate.prepareForTermination()) // resumed install path rechecks
        // Downloading/waiting must not disable a user's next operation.
        let transform = gate.beginOperation()!
        gate.endOperation(capture)
        precondition(installs == 0) // transform/cleanup/mute restoration still in progress
        gate.endOperation(transform)
        precondition(installs == 1 && !gate.isWaiting)
        gate.endOperation(transform) // stale completion cannot invoke installer twice
        precondition(installs == 1)
        gate.resetInstallation() // failed/cancelled update restores hotkeys
        let next = gate.beginOperation()!
        precondition(gate.postponeInstallation { installs += 1 })
        gate.resetInstallation() // abort must discard postponed callback
        gate.endOperation(next)
        precondition(installs == 1 && !gate.isInstalling)
        precondition(!gate.postponeInstallation { fatalError("idle callback must not be retained") })
        precondition(gate.isInstalling && gate.beginOperation() == nil)
        gate.resetInstallation()
        // An ordinary quit with no staged install must not lock operations.
        precondition(gate.prepareForTermination())
        let afterOrdinaryQuit = gate.beginOperation()!
        gate.endOperation(afterOrdinaryQuit)
        precondition(!gate.isInstalling)
        gate.resetInstallation()
        // A staged install-on-quit must survive a busy quit long enough to drain,
        // then allow termination. It must never cancel the user's quit.
        let quitOperation = gate.beginOperation()!
        gate.markInstallOnQuitPending()
        precondition(!gate.prepareForTermination()) // caller drains, then replies
        gate.endOperation(quitOperation)
        precondition(gate.hasPendingInstallOnQuit)
        precondition(gate.prepareForTermination())
        precondition(gate.beginOperation() == nil)
        gate.resetInstallation()
        precondition(!gate.hasPendingInstallOnQuit)
        print("PASS: queued start, busy install, nested teardown, final termination guard, atomic handoff, abort/retry")
        print("PASS quit install: busy drain defers termination, then allows Sparkle install-on-quit; abort clears pending state")
    }
}
