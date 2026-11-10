import SwiftUI

/// Small native style vocabulary; recording/error colors remain semantic system colors.
enum AppStyle {
    static let controlAccent = Color(red: 0.64, green: 0.28, blue: 0.12)
    static let sidebarWidth: CGFloat = 200

    static func accent(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 1, green: 0.71, blue: 0.54)
            : controlAccent
    }
}

struct SettingsPaneHeading: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.title2.weight(.semibold)).accessibilityAddTraits(.isHeader)
            Text(subtitle).font(.callout).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 22)
        .padding(.bottom, 8)
    }
}

/// One native Form row per setting, keeping its explanation visibly attached.
struct SettingsToggleRow: View {
    let title: String
    let hint: String
    @Binding var isOn: Bool
    var isEnabled = true

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Toggle(title, isOn: $isOn).disabled(!isEnabled)
            Text(hint).font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 2)
    }
}
