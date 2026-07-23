import AppKit
import Combine
import SwiftUI

/// Floating island / pill for dictation status near the MacBook camera notch.
@MainActor
final class NotchRecordingOverlayController {
    private var panel: NSPanel?
    private var hosting: NSHostingView<NotchRecordingIndicatorView>?
    private weak var appState: AppState?
    private var cancellables = Set<AnyCancellable>()
    private var screenObserver: NSObjectProtocol?

    func attach(appState: AppState) {
        self.appState = appState
        cancellables.removeAll()

        Publishers.CombineLatest(appState.$menuBarMode, appState.$recorderLiveLevel)
            .receive(on: RunLoop.main)
            .sink { [weak self] mode, level in
                guard let self else { return }
                switch mode {
                case .recording, .processing, .cleanup:
                    self.show(mode: mode, level: level)
                default:
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

    func sync(mode: MenuBarMode) {
        guard let appState else { return }
        switch mode {
        case .recording, .processing, .cleanup:
            show(mode: mode, level: appState.recorderLiveLevel)
        default:
            hide()
        }
    }

    private func show(mode: MenuBarMode, level: Float) {
        let geometry = NotchGeometry.preferred()
        let root = NotchRecordingIndicatorView(
            mode: mode,
            level: level,
            topInset: geometry.contentTopInset
        )
        if let hosting {
            hosting.rootView = root
            positionPanel()
            panel?.orderFrontRegardless()
            return
        }

        let size = geometry.panelSize
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
        panel.ignoresMouseEvents = true
        panel.contentView = hostingView

        self.panel = panel
        self.hosting = hostingView
        positionPanel()
        panel.orderFrontRegardless()
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
        guard let panel else { return }
        let geometry = NotchGeometry.preferred()
        let size = geometry.panelSize
        panel.setContentSize(size)
        hosting?.frame = NSRect(origin: .zero, size: size)
        panel.setFrame(NSRect(origin: geometry.origin, size: size), display: true)
        if let hosting {
            hosting.rootView = NotchRecordingIndicatorView(
                mode: hosting.rootView.mode,
                level: hosting.rootView.level,
                topInset: geometry.contentTopInset
            )
        }
    }
}

/// Camera-notch geometry for an expanded-island panel.
///
/// Hardware camera covers the top `notchHeight` of the panel; interactive content
/// lives in the drop below (`visibleDrop`) so the brow never clips REC / waveform.
struct NotchGeometry {
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

    var panelSize: NSSize {
        if hasNotch {
            // Slightly wider than the housing so the black capsule reads as one island.
            let width = max(notchWidth + 24, 200)
            return NSSize(width: width, height: notchHeight + visibleDrop)
        }
        return NSSize(width: 196, height: 34)
    }

    /// Top-left of the panel in Cocoa screen coords (origin bottom-left).
    var origin: NSPoint {
        let size = panelSize
        let x = centerX - size.width / 2
        if hasNotch {
            // Flush with the top of the screen: upper band merges with the camera housing.
            return NSPoint(x: x, y: screenTopY - size.height)
        }
        // No notch: hang just under the menu bar.
        let menuBottom = screen.visibleFrame.maxY
        return NSPoint(x: x, y: menuBottom - size.height - 2)
    }

    static func preferred() -> NotchGeometry {
        let notched = NSScreen.screens.first { screen in
            screen.safeAreaInsets.top > 0
                && screen.auxiliaryTopLeftArea != nil
                && screen.auxiliaryTopRightArea != nil
        }
        let screen = notched
            ?? NSScreen.screens.first(where: { $0 == NSScreen.main })
            ?? NSScreen.screens.first
            ?? NSScreen.main!
        return NotchGeometry(screen: screen)
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
            // Enough room for waveform + label below the brow.
            visibleDrop = 32
        } else {
            hasNotch = false
            notchWidth = 0
            notchHeight = 0
            visibleDrop = 34
            centerX = screen.frame.midX
        }
    }
}

struct NotchRecordingIndicatorView: View {
    let mode: MenuBarMode
    var level: Float
    /// Matches physical notch height so content sits below the camera brow.
    var topInset: CGFloat

    @State private var pulse = false

    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: max(0, topInset))

            contentRow
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    }

    private var islandCornerRadius: CGFloat {
        // Sharp top when merging with the camera housing; round the visible drop.
        topInset > 0 ? 18 : 16
    }

    @ViewBuilder
    private var contentRow: some View {
        HStack(spacing: 8) {
            if mode == .recording {
                Circle()
                    .fill(Color.red)
                    .frame(width: 7, height: 7)
                    .shadow(color: .red.opacity(0.9), radius: pulse ? 5 : 1)
                    .scaleEffect(pulse ? 1.2 : 0.95)

                LiveWaveformBars(level: level)
                    .frame(width: 84, height: 14)

                Text("REC")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.95))
                    .tracking(1.0)
            } else {
                ProgressView()
                    .controlSize(.mini)
                    .tint(.white)

                Text(mode == .cleanup ? "TXT" : "STT")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .tracking(0.8)
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 6)
    }
}

struct LiveWaveformBars: View {
    var level: Float

    private let barCount = 7

    var body: some View {
        HStack(alignment: .center, spacing: 2.5) {
            ForEach(0..<barCount, id: \.self) { index in
                Capsule()
                    .fill(Color.red.opacity(0.9))
                    .frame(width: 2.5, height: barHeight(for: index))
            }
        }
        .animation(.easeOut(duration: 0.08), value: level)
    }

    private func barHeight(for index: Int) -> CGFloat {
        let center = CGFloat(barCount - 1) / 2
        let distance = abs(CGFloat(index) - center)
        let shape = 1.0 - (distance / center) * 0.45
        let boosted = CGFloat(min(1, max(0.05, level))) * shape
        return 3 + boosted * 11
    }
}
