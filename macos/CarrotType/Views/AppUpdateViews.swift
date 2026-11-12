import SwiftUI

struct CheckForAppUpdatesButton: View {
    @ObservedObject var updates: AppUpdateService
    let locale: Locale

    var body: some View {
        Button(L10n.t("status.check_updates", locale: locale)) {
            updates.checkForUpdates()
        }
        .disabled(!updates.canCheckForUpdates)
    }
}

struct AppUpdateSettingsSection: View {
    @ObservedObject var updates: AppUpdateService
    let locale: Locale

    var body: some View {
        Section {
            HStack {
                Text("CarrotType v\(updates.releaseNotes.version)")
                    .fontWeight(.medium)
                Spacer()
                WhatsNewButton(notes: updates.releaseNotes, locale: locale)
            }
            Toggle(L10n.t("updates.automatic_checks", locale: locale), isOn: Binding(
                get: { updates.automaticallyChecks }, set: updates.setAutomaticallyChecks
            ))
            Toggle(L10n.t("updates.automatic_downloads", locale: locale), isOn: Binding(
                get: { updates.automaticallyDownloads }, set: updates.setAutomaticallyDownloads
            ))
            .disabled(!updates.allowsAutomaticDownloads)
            if !updates.allowsAutomaticDownloads {
                // Sparkle only downloads in the background during a scheduled
                // check, so this is a real dependency, not a broken toggle.
                Text(L10n.t("updates.downloads_need_checks", locale: locale))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if updates.installsOnQuit {
                Text(L10n.t("updates.install_on_quit_pending", locale: locale))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            CheckForAppUpdatesButton(updates: updates, locale: locale)
            if updates.isWaitingForOperation {
                Text(L10n.t("updates.waiting", locale: locale))
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text(L10n.t("updates.section", locale: locale))
        } footer: {
            Text(L10n.t("updates.footer", locale: locale))
        }
    }
}
