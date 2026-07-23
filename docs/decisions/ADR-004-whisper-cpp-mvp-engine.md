# ADR-004: Runnable STT Engine for MVP (whisper.cpp)

## Status

Accepted

## Context

ADR-002 selected on-device STT without locking a concrete engine. ADR-003 catalogued Parakeet TDT 0.6B v3 as the preferred RU-friendly default and Qwen3 for Smart cleanup.

To ship the first vertical slice (download → hotkey → record → STT → caret paste), the app needs a **runnable** engine and downloadable weights **now**. Parakeet/Qwen3 MLX-CoreML packaging is not yet integrated; simulating downloads blocked end-to-end verification.

## Decision

For MVP inference and downloads:

1. **STT runtime:** [WhisperMetalKit](https://github.com/carloshpdoc/WhisperMetalKit) (whisper.cpp GGML + Metal) via SPM.
2. **Default downloadable STT:** `stt.whisper-base-ggml` (`ggml-base.bin` from `ggerganov/whisper.cpp` on Hugging Face). Optional: `stt.whisper-small-ggml`, `stt.whisper-large-v3-turbo-q5` (`ggml-large-v3-turbo-q5_0.bin`). ggml packages include catalog `sha256` and are verified after download.
3. **Catalog entries** for Parakeet and Qwen3 remain visible but marked `downloadable: false` until their runtimes land.
4. **Cleanup:** `off` and `light` (heuristics) work now; `smart` / `smartPlus` fall back to `light` until Qwen3 MLX is wired.
5. Weights live under `~/Library/Application Support/carrottype/models/<package-id>/`.

## Consequences

- Ready path works without accounts: HTTPS download of ggml + local Metal inference + Accessibility paste.
- Product messaging: recommended package is Whisper Base until Parakeet runtime is ready; ADR-003 preference is retained as the target, not the current runnable default.
- Follow-up work: Parakeet CoreML/MLX adapter; Qwen3 Smart cleanup; optional checksum verification on download.

## Alternatives considered

- **WhisperKit (CoreML):** excellent on many Macs, but WhisperMetalKit was chosen for a single GGML path aligned with anonymous ggml downloads and fewer CoreML packaging steps for MVP.
- **Ship simulated `.ready` markers:** rejected — does not unlock dictation.
- **Bundle weights in `.app`:** rejected for first GitHub Release size (ADR-003).
