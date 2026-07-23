# ADR-003: Model Catalog and Cleanup

## Status

Accepted

## Context

`carrottype` needs on-device speech-to-text and optional post-transcription cleanup. Constraints from product intent:

- local-first privacy;
- free / publicly downloadable weights;
- no account or API key required to install models;
- user-visible choice of what to download;
- RU-friendly default (Parakeet TDT v3 includes Russian among 25 European languages);
- distribution via GitHub Releases without bundling large weights in the first `.dmg`.

Cleanup should improve punctuation, capitalization, filler removal, and light formatting without rewriting meaning. The user requested a **Qwen 3** based Smart cleanup path.

## Decision

### Pipeline

```text
microphone → STT model → Cleanup mode → caret paste
```

- STT is mandatory for Ready state.
- Cleanup is optional and selectable per session / in settings.

### Model Manager

- Maintain an app-shipped catalog (JSON) of downloadable packages: `id`, `role` (`stt` | `cleanup`), display name, approximate size, language notes, license, download URLs, checksum, and runtime hint.
- Download anonymously via HTTPS (Hugging Face public URLs and/or project mirrors). **No Hugging Face login, no API keys.**
- Store under `~/Library/Application Support/carrottype/models/<id>/`.
- Support progress, cancel, and failure with a clear retry path.
- Exactly one active STT package; cleanup mode is `off` | `light` | `smart` | `smart_plus`.

### STT catalog (initial)

| ID | Package | Approx. size | Role |
|----|---------|--------------|------|
| `stt.parakeet-tdt-0.6b-v3` | Parakeet TDT 0.6B v3 (CoreML and/or MLX INT8 path) | ~0.5–0.8 GB | **Default / recommended** (RU+EN+multilingual auto-detect, CC-BY-4.0) |
| `stt.whisper-small` | Whisper Small (MLX) | ~500 MB | Optional multi fallback |
| `stt.whisper-turbo` | Whisper large-v3-turbo (MLX) | ~1.5 GB | Optional quality |
| `stt.parakeet-ctc-110m` | Parakeet CTC ~110M | ~150–200 MB | Optional fast/light tier |

First-run wizard offers download of **`stt.parakeet-tdt-0.6b-v3`**. Other STT packages remain user-selectable.

Exact binary/runtime binding (CoreML vs MLX sidecar vs in-process) may be refined in implementation spikes; catalog IDs above are stable product contracts.

### Cleanup modes

| Mode | Implementation | Default |
|------|----------------|---------|
| `off` | Raw STT text | Available |
| `light` | Built-in heuristics (fillers, whitespace); no LLM download | Default until Smart is downloaded |
| `smart` | **Qwen3-0.6B 4-bit MLX** (~335 MB), e.g. `mlx-community/Qwen3-0.6B-4bit` | Recommended Smart |
| `smart_plus` | **Qwen3-1.7B 4-bit MLX** (~1 GB) | Opt-in quality |

Smart prompt policy:

- Fix punctuation, capitalization, light formatting; remove fillers.
- Do **not** paraphrase or change meaning.
- For Qwen3: disable / avoid extended “thinking” output so latency stays dictation-friendly.

### Onboarding language posture

- Product copy and first-run defaults are **RU-friendly**.
- Default STT is multilingual Parakeet v3 (includes `ru`), not an English-only checkpoint.

## Alternatives

- **Whisper-only STT catalog** — rejected as sole default; Parakeet v3 is stronger for the target carrottype latency/quality on Apple Silicon and includes RU.
- **Qwen2.5 for cleanup** — rejected; product choice is Qwen 3.
- **Cloud cleanup / cloud STT** — rejected for default path (privacy).
- **Bundle all models in the GitHub `.dmg`** — rejected; hurts install size; use on-demand download.

## Consequences

- Setup UI must show download/ready state per catalog entry and permissions (see `docs/specs/ux-setup-status.md`).
- `docs/architecture.md` includes Model Manager + cleanup stages.
- Licensing (CC-BY-4.0 for Parakeet, Apache-2.0 for Qwen 3, Whisper license) must be surfaced in UI / about.
- Implementation may use a local MLX/CoreML runtime or sidecar; that engineering choice must preserve “no auth to download” and catalog IDs.
- Ready-to-carrottype requires: Microphone + Accessibility + at least one Ready STT model.
