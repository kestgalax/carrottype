import AppKit
import Combine
import SwiftUI

/// Compact dictation process indicator near the camera notch (or under the menu bar).
/// `transformResult`, `liveDraftResult` and `dictationRecovery` show Copy / Close result chrome (ADR-012).
///
/// Presenting is centralized through `DynamicIslandPolicy`: a logical phase can be hidden or
/// rendered as the minimal indicator without clearing domain state.
@MainActor
final class StatusCapsuleController {
    private var panel: NSPanel?
    private var hosting: NSHostingView<DynamicIslandRootView>?
    private weak var appState: AppState?
    private var cancellables = Set<AnyCancellable>()
    private var screenObserver: NSObjectProtocol?

    /// Native fixtures use this to assert that a suppressed mode never resurrects the panel.
    var isVisibleForTesting: Bool { panel != nil }

    func attach(appState: AppState) {
        self.appState = appState
        cancellables.removeAll()

        let refreshTriggers: [AnyPublisher<Void, Never>] = [
            appState.$capsulePhase.map { _ in () }.eraseToAnyPublisher(),
            appState.$transformResultText.map { _ in () }.eraseToAnyPublisher(),
            appState.$transformResultDirection.map { _ in () }.eraseToAnyPublisher(),
            appState.$transformResultCopiedFeedback.map { _ in () }.eraseToAnyPublisher(),
            appState.$liveDraftConfirmed.map { _ in () }.eraseToAnyPublisher(),
            appState.$liveDraftVolatile.map { _ in () }.eraseToAnyPublisher(),
            appState.$appLanguage.map { _ in () }.eraseToAnyPublisher(),
            appState.$appTheme.map { _ in () }.eraseToAnyPublisher(),
            appState.$capsuleOperation.map { _ in () }.eraseToAnyPublisher(),
            appState.$activeDictationMode.map { _ in () }.eraseToAnyPublisher()
        ]
        Publishers.MergeMany(refreshTriggers)
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.refresh() }
            .store(in: &cancellables)

        if screenObserver == nil {
            screenObserver = NotificationCenter.default.addObserver(
                forName: NSApplication.didChangeScreenParametersNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.refresh() }
            }
        }
    }

    func sync() {
        refresh()
    }

    /// Single presentation path shared by pub/sub, explicit sync and screen changes.
    private func refresh() {
        guard let appState, let phase = appState.capsulePhase else {
            hide()
            return
        }
        show(phase: phase, presentation: appState.islandPresentation, appState: appState)
    }

    private func show(
        phase: StatusCapsulePhase,
        presentation: DynamicIslandPresentation,
        appState: AppState
    ) {
        guard presentation != .hidden else {
            hide()
            return
        }
        let geometry = StatusCapsuleGeometry.preferred()
        let size = geometry.panelSize(
            for: phase,
            presentation: presentation,
            hasLiveDraft: hasLiveDraft(phase: phase, appState: appState),
            liveDraftText: liveDraftText(appState: appState)
        )
        let root = makeRoot(
            phase: phase,
            presentation: presentation,
            geometry: geometry,
            appState: appState
        )

        if let hosting {
            hosting.rootView = root
            hosting.frame = NSRect(origin: .zero, size: size)
            applyPanelInteraction(for: phase, presentation: presentation)
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
        applyPanelInteraction(for: phase, presentation: presentation)
        positionPanel()
        panel.orderFrontRegardless()
    }

    private func makeRoot(
        phase: StatusCapsulePhase,
        presentation: DynamicIslandPresentation,
        geometry: StatusCapsuleGeometry,
        appState: AppState
    ) -> DynamicIslandRootView {
        DynamicIslandRootView(
            presentation: presentation,
            phase: phase,
            resultText: appState.transformResultText ?? "",
            direction: appState.transformResultDirection,
            copiedFeedback: appState.transformResultCopiedFeedback,
            liveConfirmed: appState.liveDraftConfirmed,
            liveVolatile: appState.liveDraftVolatile,
            topInset: geometry.contentTopInset,
            maxLiveDraftBodyHeight: StatusCapsuleGeometry.maxLiveDraftBodyHeight,
            minimalBarWidth: geometry.minimalBarWidth,
            locale: appState.effectiveLocale,
            onCopy: { [weak self] in self?.appState?.copyTransformResult() },
            onClose: { [weak self] in self?.appState?.dismissAnyResultCapsule() }
        )
    }

    private func applyPanelInteraction(
        for phase: StatusCapsulePhase,
        presentation: DynamicIslandPresentation
    ) {
        // Status/minimal phases stay click-through; full result chrome accepts Copy / Close.
        panel?.ignoresMouseEvents = !(presentation == .full && phase.isResult)
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
        let presentation = appState.islandPresentation
        guard presentation != .hidden else { return }
        let geometry = StatusCapsuleGeometry.preferred()
        let size = geometry.panelSize(
            for: phase,
            presentation: presentation,
            hasLiveDraft: hasLiveDraft(phase: phase, appState: appState),
            liveDraftText: liveDraftText(appState: appState)
        )
        panel.setContentSize(size)
        hosting?.frame = NSRect(origin: .zero, size: size)
        panel.setFrame(
            NSRect(
                origin: geometry.origin(
                    for: phase,
                    presentation: presentation,
                    hasLiveDraft: hasLiveDraft(phase: phase, appState: appState),
                    liveDraftText: liveDraftText(appState: appState)
                ),
                size: size
            ),
            display: true
        )
    }

    private func liveDraftText(appState: AppState) -> String {
        [appState.liveDraftConfirmed, appState.liveDraftVolatile]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private func hasLiveDraft(phase: StatusCapsulePhase, appState: AppState) -> Bool {
        phase == .listening && !liveDraftText(appState: appState).isEmpty
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

    /// Minimal indicator bar width; prototype judgment within the approved spec.
    var minimalBarWidth: CGFloat {
        hasNotch ? max(48, min(notchWidth * 0.55, 140)) : MinimalIslandMetrics.nonNotchBarWidth
    }

    /// Max height of the live-draft body (below the camera inset), before scrolling.
    static let maxLiveDraftBodyHeight: CGFloat = 280
    private static let liveDraftMinBodyHeight: CGFloat = 72
    private static let liveDraftHorizontalPadding: CGFloat = 28
    private static let liveDraftChromeHeight: CGFloat = 40 // listening row + spacing + bottom pad

    func panelSize(
        for phase: StatusCapsulePhase,
        presentation: DynamicIslandPresentation = .full,
        hasLiveDraft: Bool = false,
        liveDraftText: String = ""
    ) -> NSSize {
        if presentation == .minimal {
            if hasNotch {
                return NSSize(
                    width: max(notchWidth, 48),
                    height: notchHeight + MinimalIslandMetrics.notchProtrusion
                )
            }
            return MinimalIslandMetrics.nonNotchPanelSize
        }
        if phase == .formattingFallback {
            return NSSize(width: max(notchWidth + 24, 320), height: contentTopInset + visibleDrop)
        }
        if phase.isResult {
            let width: CGFloat = hasNotch ? max(notchWidth + 24, 360) : 360
            let height = contentTopInset + 200
            return NSSize(width: width, height: height)
        }
        if phase == .listening, hasLiveDraft {
            let width: CGFloat = hasNotch ? max(notchWidth + 24, 360) : 360
            let textWidth = width - Self.liveDraftHorizontalPadding
            let textHeight = Self.boundingHeight(of: liveDraftText, width: textWidth)
            let uncappedBody = Self.liveDraftChromeHeight + textHeight
            let body = min(max(uncappedBody, Self.liveDraftMinBodyHeight), Self.maxLiveDraftBodyHeight)
            return NSSize(width: width, height: contentTopInset + body)
        }
        if hasNotch {
            let width = max(notchWidth + 24, 148)
            return NSSize(width: width, height: notchHeight + visibleDrop)
        }
        return NSSize(width: 148, height: visibleDrop)
    }

    /// Top-left of the panel in Cocoa screen coords (origin bottom-left).
    func origin(
        for phase: StatusCapsulePhase,
        presentation: DynamicIslandPresentation = .full,
        hasLiveDraft: Bool = false,
        liveDraftText: String = ""
    ) -> NSPoint {
        let size = panelSize(
            for: phase,
            presentation: presentation,
            hasLiveDraft: hasLiveDraft,
            liveDraftText: liveDraftText
        )
        let x = centerX - size.width / 2
        if hasNotch {
            return NSPoint(x: x, y: screenTopY - size.height)
        }
        let menuBottom = screen.visibleFrame.maxY
        return NSPoint(x: x, y: menuBottom - size.height - 2)
    }

    private static func boundingHeight(of text: String, width: CGFloat) -> CGFloat {
        guard !text.isEmpty, width > 0 else { return 16 }
        let font = NSFont.systemFont(ofSize: 12, weight: .regular)
        let rect = (text as NSString).boundingRect(
            with: NSSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font]
        )
        return ceil(rect.height)
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

/// Hosts either the existing full capsule or the compact minimal indicator.
struct DynamicIslandRootView: View {
    let presentation: DynamicIslandPresentation
    let phase: StatusCapsulePhase
    var resultText: String
    var direction: String?
    var copiedFeedback: Bool
    var liveConfirmed: String = ""
    var liveVolatile: String = ""
    var topInset: CGFloat
    var maxLiveDraftBodyHeight: CGFloat = StatusCapsuleGeometry.maxLiveDraftBodyHeight
    var minimalBarWidth: CGFloat = MinimalIslandMetrics.nonNotchBarWidth
    var locale: Locale
    var onCopy: () -> Void
    var onClose: () -> Void

    @ViewBuilder
    var body: some View {
        switch presentation {
        case .full:
            StatusCapsuleView(
                phase: phase,
                resultText: resultText,
                direction: direction,
                copiedFeedback: copiedFeedback,
                liveConfirmed: liveConfirmed,
                liveVolatile: liveVolatile,
                topInset: topInset,
                maxLiveDraftBodyHeight: maxLiveDraftBodyHeight,
                locale: locale,
                onCopy: onCopy,
                onClose: onClose
            )
        case .minimal:
            MinimalStatusIndicatorView(
                phase: phase,
                topInset: topInset,
                barWidth: minimalBarWidth,
                locale: locale
            )
        case .hidden:
            EmptyView()
        }
    }
}

struct StatusCapsuleView: View {
    let phase: StatusCapsulePhase
    var resultText: String
    var direction: String?
    var copiedFeedback: Bool
    var liveConfirmed: String = ""
    var liveVolatile: String = ""
    /// Matches physical notch height so content sits below the camera brow.
    var topInset: CGFloat
    /// Cap for the scrollable live-draft body (matches `StatusCapsuleGeometry.maxLiveDraftBodyHeight`).
    var maxLiveDraftBodyHeight: CGFloat = StatusCapsuleGeometry.maxLiveDraftBodyHeight
    var locale: Locale
    var onCopy: () -> Void
    var onClose: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    private var ink: Color { colorScheme == .dark ? .white : .black }
    private var paper: Color { colorScheme == .dark ? .black : Color(nsColor: .windowBackgroundColor) }
    @Environment(\.colorSchemeContrast) private var colorContrast
    @State private var pulse = false

    private var liveDraftCombined: String {
        [liveConfirmed, liveVolatile].filter { !$0.isEmpty }.joined(separator: " ")
    }

    private var hasLiveDraft: Bool {
        phase == .listening && !liveDraftCombined.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: max(0, topInset))

            Group {
                if phase.isResult {
                    resultContent
                } else if hasLiveDraft {
                    liveDraftContent
                } else {
                    contentRow
                        .frame(minWidth: 96, maxWidth: 148)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .background {
            RoundedRectangle(cornerRadius: islandCornerRadius, style: .continuous)
                .fill(paper)
        }
        .onAppear { updatePulse() }
        .onChange(of: reduceMotion) { _, _ in updatePulse() }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: phase)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.12), value: liveConfirmed)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.12), value: liveVolatile)
    }

    private func updatePulse() {
        // Reset the old repeating animation when the system setting changes live.
        var reset = Transaction(animation: nil)
        reset.disablesAnimations = true
        withTransaction(reset) { pulse = false }
        if !reduceMotion {
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) { pulse = true }
        }
    }

    private var islandCornerRadius: CGFloat {
        topInset > 0 ? 18 : 16
    }

    private var liveDraftContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 7, height: 7)
                    .shadow(color: .red.opacity(0.85), radius: pulse ? 5 : 1)
                    .scaleEffect(pulse ? 1.12 : 0.96)
                label(L10n.t("capsule.listening", locale: locale))
                Spacer(minLength: 0)
            }

            ScrollView(.vertical, showsIndicators: liveDraftCombined.count > 180) {
                liveDraftText
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var liveDraftText: some View {
        // Body normal; last ~2 words muted (OpenBot-style interim chrome — not ASR tiers).
        let spacer = liveConfirmed.isEmpty || liveVolatile.isEmpty ? "" : " "
        return (
            Text(liveConfirmed).foregroundStyle(ink.opacity(0.95))
                + Text(spacer + liveVolatile).foregroundStyle(ink.opacity(colorContrast == .increased ? 0.85 : 0.65))
        )
        .font(.system(size: 12, weight: .regular, design: .rounded))
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var resultContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let direction, !direction.isEmpty {
                Text(direction)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(ink.opacity(0.55))
            }

            ScrollView {
                Text(resultText)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(ink.opacity(0.95))
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
                    .foregroundStyle(paper)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(ink.opacity(copiedFeedback ? 0.85 : 1.0))
                    )
                }
                .buttonStyle(.plain)

                Button {
                    onClose()
                } label: {
                    Text(L10n.t("capsule.transform_close", locale: locale))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(ink.opacity(0.95))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule(style: .continuous)
                                .strokeBorder(ink.opacity(0.35), lineWidth: 1)
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
                ProcessingDots(
                    diameter: 4,
                    spacing: 3,
                    ink: ink
                )
                .frame(width: 18)
                label(L10n.t("capsule.understanding", locale: locale))
            case .writing:
                Text("✍")
                    .font(.system(size: 12))
                    .foregroundStyle(ink.opacity(0.95))
                label(L10n.t("capsule.writing", locale: locale))
            case .inserted:
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(ink.opacity(0.95))
                label(L10n.t("capsule.inserted", locale: locale))
            case .formattingFallback:
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .semibold))
                label(L10n.t("format.fallback_applied", locale: locale))
            case .transformResult, .liveDraftResult, .dictationRecovery:
                EmptyView()
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, topInset > 0 ? 6 : 0)
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(ink.opacity(0.95))
            .lineLimit(1)
    }
}
