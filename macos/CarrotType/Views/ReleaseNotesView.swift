import SwiftUI

private enum ReleaseNotesStyle {
    static func accent(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 1, green: 0.68, blue: 0.45)
            : Color(red: 0.64, green: 0.26, blue: 0.04)
    }
}

struct WhatsNewButton: View {
    @ObservedObject var notes: ReleaseNotesStore
    let locale: Locale
    @State private var isPresented = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 8) {
            Button(L10n.t("release_notes.title", locale: locale)) { isPresented = true }
            if notes.hasUnreadChanges {
                Text(L10n.t("release_notes.updated", locale: locale))
                    .font(.caption).fontWeight(.medium).foregroundStyle(ReleaseNotesStyle.accent(colorScheme))
                    .accessibilityLabel(L10n.t("release_notes.updated", locale: locale))
            }
        }
        .sheet(isPresented: $isPresented) {
            ReleaseNotesView(store: notes, locale: locale)
                .onAppear { notes.markRead() }
        }
    }
}

struct ReleaseNotesView: View {
    @ObservedObject var store: ReleaseNotesStore
    let locale: Locale
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    private var content: ReleaseNotes.Content? { store.notes?.content(locale: locale) }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    header
                    if let content {
                        Text(content.summary).font(.body).foregroundStyle(.secondary)
                        ForEach(content.visibleSections) { section in
                            VStack(alignment: .leading, spacing: 16) {
                                HStack(spacing: 8) {
                                    Text(L10n.t("release_notes.\(section.kind.rawValue)", locale: locale))
                                        .font(.headline).foregroundStyle(sectionColor(section.kind))
                                    Text("\(section.items.count)")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                ForEach(Array(section.items.enumerated()), id: \.offset) { _, item in
                                    HStack(alignment: .top, spacing: 12) {
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(sectionColor(section.kind)).frame(width: 4, height: 16).padding(.top, 3)
                                            .accessibilityHidden(true)
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text(item.title).font(.body).fixedSize(horizontal: false, vertical: true)
                                            if let detail = item.detail {
                                                Text(detail).font(.callout).foregroundStyle(.secondary)
                                                    .fixedSize(horizontal: false, vertical: true)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        Text(L10n.t("release_notes.unavailable", locale: locale)).foregroundStyle(.secondary)
                    }
                }
                .textSelection(.enabled)
                .padding(28)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            Divider()
            HStack {
                Link(destination: changelogURL) {
                    Label(L10n.t("release_notes.full_changelog", locale: locale), systemImage: "arrow.up.right")
                }
                .font(.callout)
                Spacer()
                Button(L10n.t("release_notes.done", locale: locale)) { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 28).padding(.vertical, 18)
        }
        .frame(minWidth: 460, idealWidth: 540, maxWidth: 640, minHeight: 360, idealHeight: 560, maxHeight: 640)
        .background(Color(nsColor: .windowBackgroundColor))
        .onExitCommand { dismiss() }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable().frame(width: 56, height: 56).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.t("release_notes.heading", locale: locale)).font(.title2).fontWeight(.semibold)
                HStack(spacing: 8) {
                    Text("v\(store.version)")
                    if let date = formattedDate {
                        Text("·").accessibilityHidden(true)
                        Text(date)
                    }
                }
                .font(.callout).foregroundStyle(.secondary)
            }
        }
    }

    private var formattedDate: String? {
        guard let raw = store.notes?.date else { return nil }
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.timeZone = TimeZone(secondsFromGMT: 0)
        parser.dateFormat = "yyyy-MM-dd"
        guard let date = parser.date(from: raw) else { return nil }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }

    private var changelogURL: URL {
        store.notes?.changelogURL ?? URL(string: "https://github.com/kestgalax/carrottype/releases")!
    }

    private func sectionColor(_ kind: ReleaseNotes.Section.Kind) -> Color {
        switch kind {
        case .new: return ReleaseNotesStyle.accent(colorScheme)
        case .improved: return .primary
        case .fixed: return .primary
        }
    }
}
