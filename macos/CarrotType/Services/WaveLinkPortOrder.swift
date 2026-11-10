import Foundation

enum WaveLinkPortOrder {
    /// Prefer the last working port, then the remaining candidates in catalog order (no duplicates).
    static func prioritized(cached: UInt16?, candidates: [UInt16]) -> [UInt16] {
        guard let cached, candidates.contains(cached) else { return candidates }
        return [cached] + candidates.filter { $0 != cached }
    }
}
