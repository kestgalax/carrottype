// Compiled with production WaveLinkPortOrder by verify-session-lifecycle.sh
import Foundation

let candidates: [UInt16] = Array(1884...1893) + [1824]

func expect(_ condition: Bool, _ message: String) {
    if !condition {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

expect(
    WaveLinkPortOrder.prioritized(cached: nil, candidates: candidates) == candidates,
    "nil cache keeps catalog order"
)
expect(
    WaveLinkPortOrder.prioritized(cached: 1890, candidates: candidates).first == 1890,
    "cached port is first"
)
expect(
    WaveLinkPortOrder.prioritized(cached: 1890, candidates: candidates).filter { $0 == 1890 }.count == 1,
    "cached port appears once"
)
expect(
    WaveLinkPortOrder.prioritized(cached: 1890, candidates: candidates).count == candidates.count,
    "same length as candidates"
)
expect(
    WaveLinkPortOrder.prioritized(cached: 9999, candidates: candidates) == candidates,
    "unknown cache ignored"
)

print("OK wave-link port order")
