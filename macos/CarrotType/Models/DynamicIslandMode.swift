import CoreGraphics
import Foundation

/// Dictation status presentation preference (`carrottype.dynamicIslandMode`).
/// Missing or unknown saved values mean the full capsule.
enum DynamicIslandMode: String, CaseIterable, Identifiable, Hashable {
    case full
    case minimal
    case menuOnly

    static let defaultsKey = "carrottype.dynamicIslandMode"

    var id: String { rawValue }

    static func load(defaults: UserDefaults) -> DynamicIslandMode {
        guard let raw = defaults.string(forKey: defaultsKey),
              let mode = DynamicIslandMode(rawValue: raw) else { return .full }
        return mode
    }

    func save(defaults: UserDefaults) {
        defaults.set(rawValue, forKey: Self.defaultsKey)
    }

    func title(locale: Locale) -> String {
        L10n.t("island.mode.\(rawValue)", locale: locale)
    }

    func detail(locale: Locale) -> String {
        L10n.t("island.mode.\(rawValue)_detail", locale: locale)
    }
}

/// Session chrome phase. Kept as logical session state even when a mode suppresses the panel.
enum StatusCapsulePhase: Equatable {
    case listening
    case understanding
    case writing
    case inserted
    case formattingFallback
    case transformResult
    case liveDraftResult
    case dictationRecovery

    var isResult: Bool {
        self == .transformResult || self == .liveDraftResult || self == .dictationRecovery
    }
}

/// `.understanding` is shared by dictation and selection transform, so presentation needs an owner.
enum DynamicIslandOperation: Equatable {
    case dictation
    case transform
}

/// What the island should draw for the current logical phase.
enum DynamicIslandPresentation: Equatable {
    case hidden
    case full
    case minimal
}

/// One policy for capsule attach/sync/show/position and settings copy.
enum DynamicIslandPolicy {
    /// Live draft runs only when the captured session mode is full, the saved switch is on,
    /// and the captured STT package can stream. Mode changes affect the next session only.
    static func effectivePreview(
        mode: DynamicIslandMode,
        savedLiveDraft: Bool,
        supportsStreaming: Bool
    ) -> Bool {
        mode == .full && savedLiveDraft && supportsStreaming
    }

    static func presentation(
        phase: StatusCapsulePhase?,
        operation: DynamicIslandOperation,
        mode: DynamicIslandMode
    ) -> DynamicIslandPresentation {
        guard let phase else { return .hidden }
        // Transform status/results keep the existing capsule presentation in every mode.
        if operation == .transform { return .full }
        // Result and paste-recovery panels are required in every mode.
        if phase.isResult { return .full }
        switch mode {
        case .full:
            return .full
        case .minimal:
            return phase == .listening || phase == .understanding ? .minimal : .hidden
        case .menuOnly:
            return .hidden
        }
    }

    /// The status panel normally announces Light fallback; without it the menu must be honest.
    static func showsFallbackWarning(mode: DynamicIslandMode, usedFallback: Bool) -> Bool {
        mode != .full && usedFallback
    }
}

/// Minimal-indicator prototype dimensions (judgment within the approved spec).
enum MinimalIslandMetrics {
    /// Thin recording bar thickness.
    static let barHeight: CGFloat = 3
    /// Panel below the menu bar on displays without a notch.
    static let nonNotchPanelSize = CGSize(width: 48, height: 10)
    static let nonNotchBarWidth: CGFloat = 28
    /// Visible strip below the notch lower edge.
    static let notchProtrusion: CGFloat = 6
    static let dotDiameter: CGFloat = 4
    static let dotSpacing: CGFloat = 4
}
