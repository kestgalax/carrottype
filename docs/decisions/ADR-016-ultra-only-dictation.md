# ADR-016: Parakeet Ultra as the only offered dictation model

## Status

Accepted — explicit maintainer choice, 2026-11-09; shipped in 0.4.0 after its own Debug manual acceptance and explicit publication authorization on 2026-11-10.

## Context

The maintainer evaluated the usefulness of the model choices and explicitly requested that only Parakeet Ultra remain for dictation. A choice of six STT packages adds setup friction and multiple adapters/dependencies. The primary product remains local hotkey → dictation → paste. Existing useful capabilities must be preserved outside the agreed STT reduction.

## Decision

1. Offer/download/run only `stt.parakeet-ultra` using the existing FluidAudio CoreML adapter. Make it the default and recommended STT. Keep RU/EN auto language, live draft, file-based final transcription and per-session unload. No new runtime or dependency.
2. Remove Whisper/Apple speech adapters and the direct WhisperMetalKit dependency. Retain historical ADRs; this decision supersedes their multi-STT offering policy (ADR-003/004/006/008), not their history.
3. Keep Off/Light/Smart/Smart+/Gemma formatting, selection Translate/Custom bindings, microphone/meter, Wave Link, clipboard/recovery, localization and opt-in statistics. Cleanup package choices are outside this decision.
4. Model UI shows Ultra state and download/cancel/retry/delete, with no STT picker. Model download remains an explicit user action. If Ultra is already installed, reuse it without a new download.
5. Map legacy or unknown saved STT ids to Ultra. Without installed Ultra, show an actionable migration/download requirement; do not silently download, keep running a hidden retired engine, or claim offline readiness. Existing cleanup/settings/statistics data remain.
6. Do not automatically remove legacy weights. Storage inventories only known retired catalog paths (Whisper package dirs, Parakeet v3 marker/cache/legacy sibling, Apple local preparation marker); offer explicit confirmed deletion. Do not remove shared Apple system assets or unknown experimental models. Preserve visibility/explicit clearing of the retired Parakeet Hub cache alongside current catalog-scoped caches.
7. Legacy cleanup uses fixed allowlisted child paths under the application models root and must reject symlink escapes. It must not touch Ultra, cleanup weights, unknown packages, or external directories. Inventory/deletion tests use temporary roots, never installed user models.

## Alternatives

- Keep the full STT catalog: rejected by the maintainer as unnecessary choice and maintenance burden.
- Hide old choices but retain their runtime/download adapters: rejected; keep only a narrow legacy-file inventory for explicit cleanup.
- Automatically delete retired weights: rejected; preserve rollback and human control over local data removal.
- Remove Qwen/Gemma together with STT alternatives: out of scope; formatting and selection transform still require these packages.

## Consequences

- [Quality-note Result](../stt-ru-en-quality-note.md) records the maintainer's choice without inventing comparative scores. Synthetic/local fixture checks are supplementary; the 0.4.0 Debug manual gate must include RU/EN, live draft and migration behavior before release.
- A user with only retired STT installed needs an explicit Ultra download before dictating in 0.4.0. Old weights remain until the user chooses cleanup; returning to 0.3.10 remains possible before cleanup.
- No model weights in the application bundle, no new network sink, no change to the unsigned distribution posture. Existing FluidAudio downloader residuals in ADR-006 remain; this is a product simplification, not a security fix.
