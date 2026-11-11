import SwiftUI

/// Shared recording glow used by the real minimal indicator and the Settings preview.
struct RecordingGlowBar: View {
    var width: CGFloat = MinimalIslandMetrics.nonNotchBarWidth
    var height: CGFloat = MinimalIslandMetrics.barHeight

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast
    @State private var pulse = false

    var body: some View {
        Capsule(style: .continuous)
            .fill(Color.red)
            .frame(width: width, height: height)
            .shadow(color: .red.opacity(0.9), radius: pulse && !reduceMotion ? 6 : 2)
            .scaleEffect(x: pulse && !reduceMotion ? 1.05 : 1, y: 1)
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(
                        Color.primary.opacity(contrast == .increased ? 0.55 : 0),
                        lineWidth: 0.5
                    )
            }
            .onAppear { updatePulse() }
            .onChange(of: reduceMotion) { _, _ in updatePulse() }
            .accessibilityHidden(true)
    }

    private func updatePulse() {
        // Reset a previous repeating animation when Reduce Motion changes live.
        var reset = Transaction(animation: nil)
        reset.disablesAnimations = true
        withTransaction(reset) { pulse = false }
        guard !reduceMotion else { return }
        withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
            pulse = true
        }
    }
}

/// Shared compact processing dots (minimal indicator, full capsule and Settings preview).
struct ProcessingDots: View {
    var diameter: CGFloat = MinimalIslandMetrics.dotDiameter
    var spacing: CGFloat = MinimalIslandMetrics.dotSpacing
    var ink: Color = .orange

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        Group {
            if reduceMotion {
                dots(tick: -1)
            } else {
                TimelineView(.animation(minimumInterval: 0.4, paused: false)) { context in
                    let tick = Int(context.date.timeIntervalSinceReferenceDate / 0.4) % 3
                    dots(tick: tick)
                }
            }
        }
        .accessibilityHidden(true)
    }

    private func dots(tick: Int) -> some View {
        HStack(spacing: spacing) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(ink.opacity(index == tick ? 1.0 : 0.28))
                    .frame(width: diameter, height: diameter)
                    .overlay {
                        Circle().strokeBorder(
                            ink.opacity(contrast == .increased ? 0.55 : 0),
                            lineWidth: 0.5
                        )
                    }
            }
        }
    }
}

/// Transparent minimal island: a recording bar or three processing dots under the notch/menu bar.
struct MinimalStatusIndicatorView: View {
    let phase: StatusCapsulePhase
    let topInset: CGFloat
    let barWidth: CGFloat
    let locale: Locale

    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: max(0, topInset))

            Group {
                if phase == .understanding {
                    ProcessingDots(
                        diameter: MinimalIslandMetrics.dotDiameter,
                        spacing: MinimalIslandMetrics.dotSpacing,
                        ink: .orange
                    )
                } else {
                    RecordingGlowBar(width: barWidth)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityLabel))
    }

    private var accessibilityLabel: String {
        phase == .understanding
            ? L10n.t("a11y.processing", locale: locale)
            : L10n.t("a11y.recording", locale: locale)
    }
}
