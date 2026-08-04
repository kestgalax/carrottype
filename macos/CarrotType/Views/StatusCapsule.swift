import AppKit
import Combine
import SwiftUI

/// Compact dictation process indicator near the camera notch (or under the menu bar).
/// `transformResult` shows selection-transform output with Copy / Close (ADR-012).
enum StatusCapsulePhase: Equatable {
    case listening
    case understanding
    case writing
    case inserted
    case transformResult
}

@MainActor
final class StatusCapsuleController {
    private var panel: NSPanel?
    private var hosting: NSHostingView<StatusCapsuleView>?
    private weak var appState: AppState?
    private var cancellables = Set<AnyCancellable>()
    private var screenObserver: NSObjectProtocol?

    func attach(appState: AppState) {
        self.appState = appState
        cancellables.removeAll()

        Publishers.CombineLatest4(
            appState.$capsulePhase,
            appState.$transformResultText,
            appState.$transformResultDirection,
            appState.$appLanguage
        )
        .combineLatest(appState.$transformResultCopiedFeedback)
        .receive(on: RunLoop.main)
        .sink { [weak self] phaseLang, copied in
            guard let self else { return }
            let (phase, resultText, direction, _) = phaseLang
            if let phase {
                self.show(
                    phase: phase,
                    resultText: resultText,
                    direction: direction,
                    copiedFeedback: copied
                )
            } else {
                self.hide()
            }
        }
        .store(in: &cancellables)

        if screenObserver == nil {
            screenObserver = NotificationCenter.default.addObserver(
                forName: NSApplication.didChangeScreenParametersNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.positionPanel() }
            }
        }
    }

    func sync(phase: StatusCapsulePhase?) {
        if let phase {
            show(
                phase: phase,
                resultText: appState?.transformResultText,
                direction: appState?.transformResultDirection,
                copiedFeedback: appState?.transformResultCopiedFeedback ?? false
            )
        } else {
            hide()
        }
    }

    private func show(
        phase: StatusCapsulePhase,
        resultText: String?,
        direction: String?,
        copiedFeedback: Bool
    ) {
        let geometry = StatusCapsuleGeometry.preferred()
        let locale = appState?.effectiveLocale ?? Locale.current
        let size = geometry.panelSize(for: phase)
        let root = StatusCapsuleView(
            phase: phase,
            resultText: resultText ?? "",
            direction: direction,
            copiedFeedback: copiedFeedback,
            topInset: geometry.contentTopInset,
            locale: locale,
            onCopy: { [weak self] in self?.appState?.copyTransformResult() },
            onClose: { [weak self] in self?.appState?.dismissTransformResult() }
        )

        if let hosting {
            hosting.rootView = root
            hosting.frame = NSRect(origin: .zero, size: size)
            applyPanelInteraction(for: phase)
            positionPanel()
            panel?.orderFrontRegardless()
            return
        }

        let hostingView = NSHostingView(rootView: root)
        hostingView.frame = NSRect(origin: .zero, size: size)

        let panel = NSPanel(
            contentRect: hostingView.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.statusWindow)) + 2)
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.contentView = hostingView

        self.panel = panel
        self.hosting = hostingView
        applyPanelInteraction(for: phase)
        positionPanel()
        panel.orderFrontRegardless()
    }

    private func applyPanelInteraction(for phase: StatusCapsulePhase) {
        // Status phases stay click-through; result must accept Copy / Close clicks.
        panel?.ignoresMouseEvents = (phase != .transformResult)
    }

    private func hide() {
        // Tear down hosting so SwiftUI pulse animations cannot spin in the background.
        panel?.orderOut(nil)
        panel?.contentView = nil
        panel?.close()
        panel = nil
        hosting = nil
    }

    private func positionPanel() {
        guard let panel, let appState, let phase = appState.capsulePhase else { return }
        let geometry = StatusCapsuleGeometry.preferred()
        let size = geometry.panelSize(for: phase)
        panel.setContentSize(size)
        hosting?.frame = NSRect(origin: .zero, size: size)
        panel.setFrame(NSRect(origin: geometry.origin(for: phase), size: size), display: true)
        if let hosting {
            hosting.rootView = StatusCapsuleView(
                phase: phase,
                resultText: appState.transformResultText ?? "",
                direction: appState.transformResultDirection,
                copiedFeedback: appState.transformResultCopiedFeedback,
                topInset: geometry.contentTopInset,
                locale: appState.effectiveLocale,
                onCopy: { [weak self] in self?.appState?.copyTransformResult() },
                onClose: { [weak self] in self?.appState?.dismissTransformResult() }
            )
        }
    }
}

/// Camera-notch geometry for a compact status capsule panel.
///
/// Hardware camera covers the top `notchHeight` of the panel; content lives in the
/// drop below (`visibleDrop`) so the brow never clips the label row.
struct StatusCapsuleGeometry {
    let screen: NSScreen
    let hasNotch: Bool
    /// Physical notch width (between auxiliary menu-bar wings).
    let notchWidth: CGFloat
    /// Physical notch / camera housing height (`safeAreaInsets.top`).
    let notchHeight: CGFloat
    /// Extra height hanging below the brow — where content is drawn.
    let visibleDrop: CGFloat
    let centerX: CGFloat
    let screenTopY: CGFloat

    /// Padding pushed into the SwiftUI view so content clears the camera.
    var contentTopInset: CGFloat {
        hasNotch ? notchHeight : 0
    }

    func panelSize(for phase: StatusCapsulePhase) -> NSSize {
        if phase == .transformResult {
            let width: CGFloat = hasNotch ? max(notchWidth + 24, 360) : 360
            let height = contentTopInset + 200
            return NSSize(width: width, height: height)
        }
        if hasNotch {
            let width = max(notchWidth + 24, 148)
            return NSSize(width: width, height: notchHeight + visibleDrop)
        }
        return NSSize(width: 148, height: visibleDrop)
    }

    /// Top-left of the panel in Cocoa screen coords (origin bottom-left).
    func origin(for phase: StatusCapsulePhase) -> NSPoint {
        let size = panelSize(for: phase)
        let x = centerX - size.width / 2
        if hasNotch {
            return NSPoint(x: x, y: screenTopY - size.height)
        }
        let menuBottom = screen.visibleFrame.maxY
        return NSPoint(x: x, y: menuBottom - size.height - 2)
    }

    static func preferred() -> StatusCapsuleGeometry {
        let notched = NSScreen.screens.first { screen in
            screen.safeAreaInsets.top > 0
                && screen.auxiliaryTopLeftArea != nil
                && screen.auxiliaryTopRightArea != nil
        }
        let screen = notched
            ?? NSScreen.screens.first(where: { $0 == NSScreen.main })
            ?? NSScreen.screens.first
            ?? NSScreen.main!
        return StatusCapsuleGeometry(screen: screen)
    }

    init(screen: NSScreen) {
        self.screen = screen
        screenTopY = screen.frame.maxY

        if let left = screen.auxiliaryTopLeftArea,
           let right = screen.auxiliaryTopRightArea,
           right.minX > left.maxX,
           screen.safeAreaInsets.top > 0 {
            hasNotch = true
            notchWidth = right.minX - left.maxX
            notchHeight = screen.safeAreaInsets.top
            centerX = (left.maxX + right.minX) / 2
            visibleDrop = 36
        } else {
            hasNotch = false
            notchWidth = 0
            notchHeight = 0
            visibleDrop = 36
            centerX = screen.frame.midX
        }
    }
}

struct StatusCapsuleView: View {
    let phase: StatusCapsulePhase
    var resultText: String
    var direction: String?
    var copiedFeedback: Bool
    /// Matches physical notch height so content sits below the camera brow.
    var topInset: CGFloat
    var locale: Locale
    var onCopy: () -> Void
    var onClose: () -> Void

    @State private var pulse = false

    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: max(0, topInset))

            Group {
                if phase == .transformResult {
                    resultContent
                } else {
                    contentRow
                        .frame(minWidth: 96, maxWidth: 148)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .background {
            RoundedRectangle(cornerRadius: islandCornerRadius, style: .continuous)
                .fill(Color.black)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
        .animation(.easeInOut(duration: 0.18), value: phase)
    }

    private var islandCornerRadius: CGFloat {
        topInset > 0 ? 18 : 16
    }

    private var resultContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let direction, !direction.isEmpty {
                Text(direction)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
            }

            ScrollView {
                Text(resultText)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.95))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(maxHeight: 140)

            HStack(spacing: 8) {
                Button {
                    onCopy()
                } label: {
                    Text(
                        copiedFeedback
                            ? L10n.t("capsule.transform_copied", locale: locale)
                            : L10n.t("capsule.transform_copy", locale: locale)
                    )
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(copiedFeedback ? 0.85 : 1.0))
                    )
                }
                .buttonStyle(.plain)

                Button {
                    onClose()
                } label: {
                    Text(L10n.t("capsule.transform_close", locale: locale))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.95))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule(style: .continuous)
                                .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private var contentRow: some View {
        HStack(spacing: 8) {
            switch phase {
            case .listening:
                Circle()
                    .fill(Color.red)
                    .frame(width: 7, height: 7)
                    .shadow(color: .red.opacity(0.85), radius: pulse ? 5 : 1)
                    .scaleEffect(pulse ? 1.12 : 0.96)
                label(L10n.t("capsule.listening", locale: locale))
            case .understanding:
                TimelineView(.animation(minimumInterval: 0.4, paused: false)) { context in
                    let tick = Int(context.date.timeIntervalSinceReferenceDate / 0.4) % 3
                    HStack(spacing: 3) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(Color.white.opacity(index == tick ? 1.0 : 0.28))
                                .frame(width: 4, height: 4)
                        }
                    }
                    .frame(width: 18)
                }
                label(L10n.t("capsule.understanding", locale: locale))
            case .writing:
                Text("✍")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.95))
                label(L10n.t("capsule.writing", locale: locale))
            case .inserted:
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.95))
                label(L10n.t("capsule.inserted", locale: locale))
            case .transformResult:
                EmptyView()
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, topInset > 0 ? 6 : 0)
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(.white.opacity(0.95))
            .lineLimit(1)
    }
}
