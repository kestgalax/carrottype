# Research spikes (post-v1 DMG)

Not scheduled for implementation in the unsigned `v0.1.0` release. Tracked from the Turbo/DMG plan recommendations.

## Cleanup

| Candidate | Fit | Notes |
|-----------|-----|-------|
| Sotto LFM2.5-350M MLX 5-bit | EN dictation cleanup; trained to avoid aggressive rewrite / ITN | Spike A/B vs Light + Qwen3 |
| Qwen3 1.7B (already Smart+) | Better RU than tiny Qwen; keep strict no-paraphrase prompt | Prefer over 0.6B when rewrite is a complaint |

## STT

| Candidate | Fit | Notes |
|-----------|-----|-------|
| Qwen3-ASR 0.6B MLX | Quality tier vs Parakeet; ~52 languages | New runtime (MLX ASR), not ggml |
| Whisper Turbo q5 | **Shipped** as optional catalog package | Same WhisperMetalKit path |
| Apple SpeechAnalyzer | System STT | Needs macOS 26+; out of current floor |

## Gate

1. Keep `v0.1.0` on the **private** Release (invite-only) until notarization / public ship is intentional.
2. Fill `docs/stt-ru-en-quality-note.md` and only then flip `recommended` if needed.
3. **Then** spend eng time on Sotto / Qwen3-ASR adapters.

Do not start new STT/cleanup runtimes while the quality note (and notarization path) are still open.
