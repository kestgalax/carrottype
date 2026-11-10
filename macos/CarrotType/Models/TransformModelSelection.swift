import Foundation

/// One resolution policy for Settings explanations and actual transform execution.
enum TransformModelSelection {
    static func resolve(requested: CleanupMode, available: [CleanupMode]) -> CleanupMode? {
        let ready = available.filter(\.usesMLXHelper)
        return ready.contains(requested) ? requested : ready.first
    }
}
