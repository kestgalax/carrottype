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
        precondition(gate.prepareForTermination())
        precondition(gate.beginOperation() == nil)
        print("PASS: queued start, busy install, nested teardown, final termination guard, atomic handoff, abort/retry")
    }
}
