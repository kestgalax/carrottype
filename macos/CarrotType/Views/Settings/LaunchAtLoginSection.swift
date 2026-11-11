import AppKit
import SwiftUI

struct LaunchAtLoginSection: View {
    @ObservedObject var service: LaunchAtLoginService
    let locale: Locale
    private func t(_ key: String) -> String { L10n.t(key, locale: locale) }

    var body: some View {
        Section {
            Toggle(t("login.toggle"), isOn: Binding(get: { service.isRequested }, set: { service.setEnabled($0) }))
                .disabled(!service.canChange)
            Text(t("login.hint")).font(.caption).foregroundStyle(.secondary)
            if !service.isInstalled {
                Text(t("login.install")).font(.caption).foregroundStyle(.secondary)
            }
            if service.status == .requiresApproval {
                Label(t("login.pending"), systemImage: "exclamationmark.triangle")
                    .font(.caption).foregroundStyle(.orange)
            }
            if service.status == .notFound || service.status == .unavailable {
                Text(t("login.unavailable")).font(.caption).foregroundStyle(.secondary)
            }
            if service.hasError {
                Text(t("login.error")).font(.caption).foregroundStyle(.orange)
            }
            if service.status == .requiresApproval || service.hasError {
                Button(t("login.settings")) { service.openSettings() }
            }
        } header: { Text(t("login.section")) }
        .onAppear { service.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in service.refresh() }
    }
}
