import SwiftUI

/// Compact horizontal mic level meter (0…1).
struct MicrophoneLevelMeter: View {
    var level: Float
    var isActive: Bool

    var body: some View {
        GeometryReader { geo in
            let width = max(0, geo.size.width * CGFloat(min(1, max(0, level))))
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.secondary.opacity(0.18))
                Capsule()
                    .fill(meterColor)
                    .frame(width: width)
            }
        }
        .frame(height: 6)
        .opacity(isActive ? 1 : 0.45)
        .accessibilityLabel(L10n.t("a11y.mic_level"))
        .accessibilityValue(Text(String(format: L10n.t("a11y.mic_level_value"), Int(level * 100))))
    }

    private var meterColor: Color {
        if level > 0.75 { return .orange }
        if level > 0.08 { return .green }
        return .secondary
    }
}
