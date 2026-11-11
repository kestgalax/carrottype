import Foundation

@main
struct DynamicIslandChecks {
    static func main() {
        let suiteName = "carrottype.dynamic-island.checks." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        // Missing and invalid values mean full capsule; every saved raw value round-trips.
        precondition(DynamicIslandMode.load(defaults: defaults) == .full)
        defaults.set("unknown-mode", forKey: DynamicIslandMode.defaultsKey)
        precondition(DynamicIslandMode.load(defaults: defaults) == .full)
        for mode in DynamicIslandMode.allCases {
            mode.save(defaults: defaults)
            precondition(defaults.string(forKey: DynamicIslandMode.defaultsKey) == mode.rawValue)
            precondition(DynamicIslandMode.load(defaults: defaults) == mode)
        }
        print("PASS island preference: absent/invalid → full, saved full/minimal/menuOnly round-trip")

        // Captured effective preview: only full + saved switch + streaming support.
        for mode in DynamicIslandMode.allCases {
            for saved in [false, true] {
                for streaming in [false, true] {
                    let expected = mode == .full && saved && streaming
                    precondition(DynamicIslandPolicy.effectivePreview(
                        mode: mode,
                        savedLiveDraft: saved,
                        supportsStreaming: streaming
                    ) == expected)
                }
            }
        }
        print("PASS effective preview: compact/menu never request a preview even when saved on")

        // Full keeps the existing phase chrome. Minimal only draws recording/processing.
        let statusPhases: [StatusCapsulePhase] = [.listening, .understanding, .writing, .inserted, .formattingFallback]
        for phase in statusPhases {
            precondition(DynamicIslandPolicy.presentation(phase: phase, operation: .dictation, mode: .full) == .full)
        }
        precondition(DynamicIslandPolicy.presentation(phase: .listening, operation: .dictation, mode: .minimal) == .minimal)
        precondition(DynamicIslandPolicy.presentation(phase: .understanding, operation: .dictation, mode: .minimal) == .minimal)
        for phase in [StatusCapsulePhase.writing, .inserted, .formattingFallback] {
            precondition(DynamicIslandPolicy.presentation(phase: phase, operation: .dictation, mode: .minimal) == .hidden)
        }
        for phase in statusPhases {
            precondition(DynamicIslandPolicy.presentation(phase: phase, operation: .dictation, mode: .menuOnly) == .hidden)
        }
        precondition(DynamicIslandPolicy.presentation(phase: nil, operation: .dictation, mode: .full) == .hidden)
        print("PASS dictation matrix: full status stays, minimal only listening/processing, menu-only hides status")

        // Result/recovery/transform panels stay available in every mode.
        let resultPhases: [StatusCapsulePhase] = [.transformResult, .liveDraftResult, .dictationRecovery]
        for mode in DynamicIslandMode.allCases {
            for phase in resultPhases {
                precondition(DynamicIslandPolicy.presentation(phase: phase, operation: .dictation, mode: mode) == .full)
                precondition(DynamicIslandPolicy.presentation(phase: phase, operation: .transform, mode: mode) == .full)
            }
            // `.understanding` is shared; transform owns the full status in every mode.
            precondition(DynamicIslandPolicy.presentation(phase: .understanding, operation: .transform, mode: mode) == .full)
        }
        print("PASS result exception: transform/recovery/live-draft results remain full in all modes")

        // Fallback warning is only needed when the normal capsule cannot announce it.
        precondition(!DynamicIslandPolicy.showsFallbackWarning(mode: .full, usedFallback: true))
        precondition(!DynamicIslandPolicy.showsFallbackWarning(mode: .minimal, usedFallback: false))
        precondition(DynamicIslandPolicy.showsFallbackWarning(mode: .minimal, usedFallback: true))
        precondition(DynamicIslandPolicy.showsFallbackWarning(mode: .menuOnly, usedFallback: true))
        print("PASS fallback visibility: menu warning only for a suppressed panel with a real fallback")

        // Prototype geometry stays a thin indicator, not a text body.
        precondition(MinimalIslandMetrics.barHeight >= 2 && MinimalIslandMetrics.barHeight <= 6)
        precondition(MinimalIslandMetrics.notchProtrusion >= 4 && MinimalIslandMetrics.notchProtrusion <= 6)
        precondition(MinimalIslandMetrics.nonNotchPanelSize.width >= 40)
        precondition(MinimalIslandMetrics.nonNotchPanelSize.height >= 8)
        precondition(MinimalIslandMetrics.nonNotchBarWidth < MinimalIslandMetrics.nonNotchPanelSize.width)
        print("PASS minimal metrics: 3 pt bar, 4–6 pt notch protrusion, compact non-notch panel")
    }
}
