import Foundation

/// Shared by the actual preview engine and executable regression checks.
enum LiveDraftText {
    /// Strip decoder junk tokens that sometimes leak into Capsule draft.
    static func sanitizePreviewText(_ text: String) -> String {
        var out = text
        for token in ["<unk>", "<UNK>", "<pad>", "<PAD>", "<s>", "</s>"] {
            out = out.replacingOccurrences(of: token, with: " ")
        }
        let words = out.split { $0.isWhitespace || $0.isNewline }.map(String.init)
        // Drop punctuation-only spam tokens (",", "--", "...") from hallucinated passes.
        let cleaned = words.filter { word in
            !word.allSatisfy { $0.isPunctuation || $0.isMathSymbol }
        }
        return cleaned.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Keep samples from the first frame above `peakThreshold` (with a tiny pad).
    static func trimLeadingSilence(_ samples: [Float], peakThreshold: Float) -> [Float] {
        guard !samples.isEmpty else { return samples }
        let pad = 1_600 // 100 ms @ 16 kHz
        guard let firstVoice = samples.firstIndex(where: { abs($0) >= peakThreshold }) else {
            return []
        }
        let start = max(0, firstVoice - pad)
        return Array(samples[start...])
    }

}
