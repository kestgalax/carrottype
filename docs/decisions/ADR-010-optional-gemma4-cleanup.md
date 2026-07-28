# ADR-010: Optional Gemma 4 E2B Cleanup Package

## Status

Accepted

## Context

ADR-003 / ADR-005 define post-dictation formatting modes Off / Light / Smart / Smart+ with Qwen3 MLX packages. Users may want to try an alternate on-device LLM for cleanup without replacing the default Smart path. Gemma 4 E2B is available as an Apache-2.0 MLX 4-bit package and is supported by the pinned `mlx-swift-lm` (3.31.4) used by `CarrotTypeCleanupHelper` (ADR-009).

## Decision

1. **Add one optional cleanup package** beside Qwen, not a replacement:
   - Catalog id: `cleanup.gemma4-e2b-4bit`
   - Hub: `mlx-community/gemma-4-e2b-it-4bit` (PTQ 4-bit; not QAT)
   - New mode: `CleanupMode.gemma` (UI: Gemma 4 E2B)
2. **Runtime:** same out-of-process MLX helper as Smart/Smart+ (ADR-009). Host downloads via existing Hub snapshot path (`runtimeHint: mlx-lm`).
3. **Prompt policy:** same literal + robust cleanup instructions as Qwen (anti-instruction, no paraphrase, self-corrections, output-only; see ADR-003). Gemma path does **not** pass Qwen3 `enable_thinking`; Qwen path keeps thinking disabled + `<think>` strip.
4. **Defaults:** package is `recommended: false`; Light remains the default formatting mode until the user activates a Ready MLX package.
5. **Platform:** Apple Silicon only (same as Smart). Intel keeps Off/Light.
6. **Out of scope:** Gemma E4B / 26B / 31B, QAT checkpoints, multimodal image input, replacing Qwen as Smart/Smart+.

## Consequences

- Models pane gains a third downloadable formatting row; picker includes Gemma when Ready.
- Download and peak helper RAM are larger than Qwen3 0.6B (~3.5 GB weights; cold start may be slower on low-RAM Macs). Helper wall-clock timeout stays 120s for v1; raise only for `gemma` if field evidence requires it.
- Failure still falls back to Light heuristics so STT text is never discarded.

## Alternatives considered

- **Replace Qwen Smart with Gemma:** rejected; keeps product default and smaller download for most users.
- **E4B as a second Gemma tier:** deferred; one optional package is enough to validate quality vs size.
- **New cleanup runtime (llama.cpp / Ollama):** rejected; reuse MLX helper already shipping.
