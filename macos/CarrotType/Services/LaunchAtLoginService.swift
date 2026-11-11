import Combine
import Foundation
import ServiceManagement

enum LoginItemStatus: Equatable { case notRegistered, enabled, requiresApproval, notFound, unavailable }

@MainActor protocol LoginItemClient {
    var status: LoginItemStatus { get }
    func register() throws
    func unregister() throws
    func openSettings()
}

@MainActor private final class SystemLoginItemClient: LoginItemClient {
    var status: LoginItemStatus {
        switch SMAppService.mainApp.status {
        case .notRegistered: return .notRegistered
        case .enabled: return .enabled
        case .requiresApproval: return .requiresApproval
        case .notFound: return .notFound
        @unknown default: return .unavailable
        }
    }
    func register() throws { try SMAppService.mainApp.register() }
    func unregister() throws { try SMAppService.mainApp.unregister() }
    func openSettings() { SMAppService.openSystemSettingsLoginItems() }
}

/// macOS owns the state. Constructing/refreshing this object never changes login items.
@MainActor final class LaunchAtLoginService: ObservableObject {
    @Published private(set) var status: LoginItemStatus
    @Published private(set) var hasError = false
    let isInstalled: Bool
    private let client: any LoginItemClient

    init(client: (any LoginItemClient)? = nil, installed: Bool? = nil) {
        let client = client ?? SystemLoginItemClient()
        self.client = client
        self.isInstalled = installed ?? Self.isInstalledApplication(Bundle.main.bundleURL)
        self.status = client.status
    }

    var isRequested: Bool { status == .enabled || status == .requiresApproval }
    var canChange: Bool { status != .unavailable && (isInstalled || isRequested) }

    func refresh() {
        let next = client.status
        if next != status { hasError = false }
        status = next
    }

    func setEnabled(_ enabled: Bool) {
        refresh()
        guard canChange, !enabled || isInstalled else { return }
        hasError = false
        guard enabled != isRequested else { return }
        do {
            if enabled { try client.register() } else { try client.unregister() }
        } catch { hasError = true }
        // Registration can succeed but still require approval; do not claim it is enabled.
        status = client.status
    }

    func openSettings() { client.openSettings() }

    static func isInstalledApplication(_ bundle: URL, home: URL = FileManager.default.homeDirectoryForCurrentUser) -> Bool {
        let path = bundle.resolvingSymlinksInPath().standardizedFileURL.path
        return [URL(fileURLWithPath: "/Applications"), home.appendingPathComponent("Applications")].contains { root in
            path.hasPrefix(root.resolvingSymlinksInPath().standardizedFileURL.path + "/") && bundle.pathExtension == "app"
        }
    }
}
