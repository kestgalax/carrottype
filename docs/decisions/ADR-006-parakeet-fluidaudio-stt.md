# ADR-006: Parakeet STT Runtime via FluidAudio (CoreML)

## Status

Accepted

> Current policy for the 0.4.0 candidate: [ADR-016](ADR-016-ultra-only-dictation.md) supersedes the STT offerings/default below. Only Parakeet Ultra is offered; historical decisions and cleanup policies remain recorded here.

## Context

ADR-003 preferred Parakeet TDT 0.6B v3 for RU-friendly STT. ADR-004 shipped Whisper ggml as the first runnable engine. The catalog entry `stt.parakeet-tdt-0.6b-v3` stayed non-downloadable until a reproducible Apple Silicon package existed.

Raw NVIDIA NeMo checkpoints are not suitable for in-app conversion. We need a pre-converted CoreML (or equivalent) artifact with a stable download URL.

## Decision

1. **Runtime:** [FluidAudio](https://github.com/FluidInference/FluidAudio) (`AsrModels` / `AsrManager`) targeting **Parakeet TDT 0.6B v3** CoreML packages from Hugging Face (`FluidInference/parakeet-tdt-0.6b-v3-coreml`).
2. **Download:** `AsrModels.download(to:)` into Application Support under CarrotType `models/`. FluidAudio stores CoreML bundles in a **sibling folder** `parakeet-tdt-0.6b-v3` (repo `folderName`); the catalog package id dir holds only the `.ready` marker. Delete must remove both.
3. **Adapter:** `ParakeetSTTEngine` behind `STTEngine`; Whisper remains the recommended default and fallback.
4. **Resources:** only the active STT engine stays loaded; unload after idle timeout; switching STT packages reloads on next session.
5. **Catalog:** `downloadable: true`, `runtimeHint: parakeet-fluidaudio`. Recommendation stayed on Whisper Base until the quality gate; **2026-07-24:** catalog `recommended` flipped to Parakeet (`docs/stt-ru-en-quality-note.md`), matching ADR-003.
6. **Selection UX:** active STT / Smart cleanup may be chosen only when the package is Ready on disk (no auto-download on picker change).
7. **2026-10-20 — Parakeet Ultra beside v3.** SPM pin moves from FluidAudio 0.15.5 to **0.17.7** (`from: 0.17.7`). Optional catalog id `stt.parakeet-ultra` uses the same `ParakeetSTTEngine` / `AsrManager` with `AsrModelVersion.ultra` and its own cache folder (`Repo.parakeetUltra.folderName`, `parakeet-ultra`). The catalog default (`recommended`) stays on v3. Deleting one package removes only that variant’s cache; the v3 delete still also removes the legacy `parakeet-tdt-0.6b-v3-coreml` sibling.

## Consequences

- Users can download and run Parakeet without converting NeMo weights locally.
- FluidAudio is an additional SPM dependency (macOS 14+, Apple Silicon for Parakeet models).
- Whisper Base/Small continue to work unchanged for machines or users that prefer ggml.
- **Downloader residual (checked on FluidAudio 0.17.7):** `ModelHub` still builds each local path by appending the registry tree-listing path onto the cache directory, and repo downloads still replace a file that blocks a path component. A listing entry with parent-directory segments can write outside `models/`. CarrotType cannot confine that write from outside `AsrModels.download`. The 0.17.7 bump does not close it, and this change does not fork FluidAudio.

## Alternatives considered

- **In-app NeMo → CoreML conversion:** rejected — too heavy and fragile for a menu-bar app.
- **MLX Parakeet port:** deferred; FluidAudio already ships a maintained CoreML TDT v3 path used by other macOS dictation apps.
- **Make Parakeet recommended immediately:** deferred until side-by-side RU quality check vs Whisper Base.
