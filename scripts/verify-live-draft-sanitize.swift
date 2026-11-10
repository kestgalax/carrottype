// Compiled with production LiveDraftText by verify-session-lifecycle.sh
import Foundation

func expect(_ condition: Bool, _ message: String) {
    if !condition {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

expect(LiveDraftText.sanitizePreviewText("hello <unk> world") == "hello world", "strip unk")
expect(LiveDraftText.sanitizePreviewText("Moze 5, C - -Sketch , mi 2, , , , , 2 ally .").contains(", ,") == false, "drop comma spam")
expect(LiveDraftText.sanitizePreviewText("  <pad>  ") == "", "only junk → empty")

var silence = [Float](repeating: 0.0001, count: 8_000)
silence.append(contentsOf: [Float](repeating: 0.05, count: 4_000))
let trimmed = LiveDraftText.trimLeadingSilence(silence, peakThreshold: 0.004)
expect(!trimmed.isEmpty, "voice kept")
expect(trimmed.count < silence.count, "silence dropped")
expect(LiveDraftText.trimLeadingSilence([Float](repeating: 0, count: 1000), peakThreshold: 0.004).isEmpty, "all silence")

print("OK live-draft sanitize/trim")
