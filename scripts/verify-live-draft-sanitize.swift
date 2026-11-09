#!/usr/bin/env swift
import Foundation

/// Mirrors ParakeetStreamingEngine helpers — keep in sync.
func sanitizePreviewText(_ text: String) -> String {
    var out = text
    for token in ["<unk>", "<UNK>", "<pad>", "<PAD>", "<s>", "</s>"] {
        out = out.replacingOccurrences(of: token, with: " ")
    }
    let words = out.split { $0.isWhitespace || $0.isNewline }.map(String.init)
    let cleaned = words.filter { word in
        !word.allSatisfy { $0.isPunctuation || $0.isMathSymbol }
    }
    return cleaned.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
}

func trimLeadingSilence(_ samples: [Float], peakThreshold: Float) -> [Float] {
    guard !samples.isEmpty else { return samples }
    let pad = 1_600
    guard let firstVoice = samples.firstIndex(where: { abs($0) >= peakThreshold }) else {
        return []
    }
    let start = max(0, firstVoice - pad)
    return Array(samples[start...])
}

func expect(_ condition: Bool, _ message: String) {
    if !condition {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

expect(sanitizePreviewText("hello <unk> world") == "hello world", "strip unk")
expect(sanitizePreviewText("Moze 5, C - -Sketch , mi 2, , , , , 2 ally .").contains(", ,") == false, "drop comma spam")
expect(sanitizePreviewText("  <pad>  ") == "", "only junk → empty")

var silence = [Float](repeating: 0.0001, count: 8_000)
silence.append(contentsOf: [Float](repeating: 0.05, count: 4_000))
let trimmed = trimLeadingSilence(silence, peakThreshold: 0.004)
expect(!trimmed.isEmpty, "voice kept")
expect(trimmed.count < silence.count, "silence dropped")
expect(trimLeadingSilence([Float](repeating: 0, count: 1000), peakThreshold: 0.004).isEmpty, "all silence")

print("OK live-draft sanitize/trim")
