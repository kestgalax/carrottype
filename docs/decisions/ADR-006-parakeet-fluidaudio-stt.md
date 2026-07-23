# ADR-006: Parakeet STT Runtime via FluidAudio (CoreML)

## Status

Accepted

## Context

ADR-003 preferred Parakeet TDT 0.6B v3 for RU-friendly STT. ADR-004 shipped Whisper ggml as the first runnable engine. The catalog entry `stt.parakeet-tdt-0.6b-v3` stayed non-downloadable until a reproducible Apple Silicon package existed.

Raw NVIDIA NeMo checkpoints are not suitable for in-app conversion. We need a pre-converted CoreML (or equivalent) artifact with a stable download URL.

## Decision

1. **Runtime:** [FluidAudio](https://github.com/FluidInference/FluidAudio) (`AsrModels` / `AsrManager`) targeting **Parakeet TDT 0.6B v3** CoreML packages from Hugging Face (`FluidInference/parakeet-tdt-0.6b-v3-coreml`).
2. **Download:** `AsrModels.download(to:)` into Application Support under CarrotType `models/`. FluidAudio stores CoreML bundles in a **sibling folder** `parakeet-tdt-0.6b-v3` (repo `folderName`); the catalog package id dir holds only the `.ready` marker. Delete must remove both.
3. **Adapter:** `ParakeetSTTEngine` behind `STTEngine`; Whisper remains the recommended default and fallback.
4. **Resources:** only the active STT engine stays loaded; unload after idle timeout; switching STT packages reloads on next session.
5. **Catalog:** `downloadable: true`, `runtimeHint: parakeet-fluidaudio`. Recommendation stays on Whisper Base until Parakeet proves better on internal RU samples (can flip `recommended` later without a new ADR).
6. **Selection UX:** active STT / Smart cleanup may be chosen only when the package is Ready on disk (no auto-download on picker change).

## Consequences

- Users can download and run Parakeet without converting NeMo weights locally.
- FluidAudio is an additional SPM dependency (macOS 14+, Apple Silicon for Parakeet models).
- Whisper Base/Small continue to work unchanged for machines or users that prefer ggml.

## Alternatives considered

- **In-app NeMo → CoreML conversion:** rejected — too heavy and fragile for a menu-bar app.
- **MLX Parakeet port:** deferred; FluidAudio already ships a maintained CoreML TDT v3 path used by other macOS dictation apps.
- **Make Parakeet recommended immediately:** deferred until side-by-side RU quality check vs Whisper Base.
