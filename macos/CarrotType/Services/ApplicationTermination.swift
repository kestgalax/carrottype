import AppKit

/// Single termination route shared by ordinary Quit and a staged update install.
/// It deliberately has no update-specific short circuit: AppKit permits exactly
/// one reply, and `AppState.prepareForQuit` owns draining or replying.
@MainActor
final class CarrotTypeApplicationDelegate: NSObject, NSApplicationDelegate {
    var prepareForQuit: (() -> NSApplication.TerminateReply)?

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        prepareForQuit?() ?? .terminateNow
    }
}
