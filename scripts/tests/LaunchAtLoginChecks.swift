import Foundation

@MainActor private final class FakeLoginItem: LoginItemClient {
    enum Failure: Error { case denied }
    var status = LoginItemStatus.notRegistered
    var registrations = 0, unregistrations = 0, openedSettings = 0
    var fails = false
    var registrationStatus = LoginItemStatus.enabled
    func register() throws {
        registrations += 1
        if fails { throw Failure.denied }
        status = registrationStatus
    }
    func unregister() throws {
        unregistrations += 1
        if fails { throw Failure.denied }
        status = .notRegistered
    }
    func openSettings() { openedSettings += 1 }
}

@main struct LaunchAtLoginChecks {
    @MainActor static func main() {
        let fake = FakeLoginItem()
        let service = LaunchAtLoginService(client: fake, installed: true)
        precondition(!service.isRequested && fake.registrations == 0 && fake.unregistrations == 0)
        service.refresh()
        precondition(fake.registrations == 0)
        service.setEnabled(true)
        precondition(service.isRequested && service.status == .enabled && fake.registrations == 1)
        service.setEnabled(true)
        precondition(fake.registrations == 1)
        service.setEnabled(false)
        precondition(!service.isRequested && fake.unregistrations == 1)
        fake.registrationStatus = .requiresApproval
        service.setEnabled(true)
        precondition(service.isRequested && service.status == .requiresApproval)
        service.openSettings()
        precondition(fake.openedSettings == 1)
        service.setEnabled(false)
        precondition(!service.isRequested)
        fake.fails = true
        service.setEnabled(true)
        precondition(service.hasError && !service.isRequested)
        fake.status = .enabled // External System Settings change, never auto-register.
        service.refresh()
        precondition(service.isRequested && !service.hasError)
        service.setEnabled(false)
        precondition(service.hasError && service.isRequested) // Failed removal retains real state.
        fake.fails = false
        service.setEnabled(false)
        precondition(!service.hasError && !service.isRequested)
        print("PASS startup: explicit enable/disable, idempotence, pending approval, external refresh and registration/unregistration errors")

        let temporaryFake = FakeLoginItem()
        let temporary = LaunchAtLoginService(client: temporaryFake, installed: false)
        temporary.setEnabled(true)
        precondition(!temporary.canChange && temporaryFake.registrations == 0)
        temporaryFake.status = .enabled
        temporary.refresh()
        precondition(temporary.canChange)
        temporary.setEnabled(false) // Moving an app must not prevent explicitly removing its item.
        precondition(temporaryFake.unregistrations == 1 && !temporary.isRequested)
        temporaryFake.status = .unavailable
        temporary.refresh()
        temporary.setEnabled(true)
        precondition(!temporary.canChange && temporaryFake.registrations == 0)
        let home = URL(fileURLWithPath: "/fixture/home")
        for path in ["/Applications/CarrotType.app", "/Applications/Tools/CarrotType.app", "/fixture/home/Applications/CarrotType.app"] {
            precondition(LaunchAtLoginService.isInstalledApplication(URL(fileURLWithPath: path), home: home))
        }
        for path in ["/Applications-other/CarrotType.app", "/fixture/home/Applications-other/CarrotType.app", "/Volumes/CarrotType/CarrotType.app", "/tmp/CarrotType.app", "/Applications/file.txt"] {
            precondition(!LaunchAtLoginService.isInstalledApplication(URL(fileURLWithPath: path), home: home))
        }
        print("PASS install policy: temporary/DMG/path boundaries blocked; explicit removal allowed; no real login item or System Settings changes")
    }
}
