import AppKit

@main
struct ApplicationTerminationChecks {
    @MainActor static func main() {
        let delegate = CarrotTypeApplicationDelegate()
        let app = NSApplication.shared
        // No prepared handler: terminate normally without inventing a cancel.
        precondition(delegate.applicationShouldTerminate(app) == .terminateNow)

        var calls = 0
        delegate.prepareForQuit = {
            calls += 1
            return .terminateLater
        }
        precondition(delegate.applicationShouldTerminate(app) == .terminateLater)
        precondition(calls == 1)

        // Sparkle install-on-quit and ordinary quit share one drain path; the
        // delegate must never swallow the call or return .terminateCancel.
        delegate.prepareForQuit = {
            calls += 1
            return .terminateNow
        }
        precondition(delegate.applicationShouldTerminate(app) == .terminateNow)
        precondition(calls == 2)
        print("PASS application termination: always routes through prepareForQuit, never short-circuits or cancels")
    }
}
