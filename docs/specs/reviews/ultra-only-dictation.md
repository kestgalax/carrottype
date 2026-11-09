# Ultra-only dictation — release review

## Metadata

- Review ID: R-003
- Outcome: Approve

## Traceability Check

- Product Intent Link: docs/product-intent.md
- Roadmap Item: 0.4.0 — Ultra-only dictation
- Feature Spec: docs/specs/features/hotkey-carrottype-caret-paste.md
- Task: docs/specs/tasks/ultra-only-dictation.md
- Related ADRs: docs/decisions/ADR-016-ultra-only-dictation.md, docs/decisions/ADR-006-parakeet-fluidaudio-stt.md, docs/decisions/ADR-014-live-dictation-streaming.md

## Governance Checklist

- Product intent respected: one local dictation model reduces setup choice while preserving hotkey → record → local STT → cleanup → paste.
- Architecture respected: ADR-016 covers the intentional retirement of STT alternatives/WhisperMetalKit. Remaining SPM pins are unchanged; no new runtime or network sink.
- Existing useful functions preserved outside the explicitly agreed STT scope: Qwen/Gemma formatting, Translate/Custom, live draft, PTT, Wave Link, microphone/meter, clipboard/recovery, RU/EN and statistics remain.
- Data migration is explicit: only the STT preference changes automatically; model downloads and legacy-file deletion require user actions. Legacy deletion is allowlisted/path-boundary safe and excludes shared Apple assets and unknown experiments.
- Verification evidence present: accepted Debug candidate and production-code regression checks; final Release artifact checks/hash recorded in release notes before publication.

## ADR Impact

Follows accepted ADR-016. ADR-003/004/006/008 retain history with supersession notes. ADR-014 preview/file-final behavior is preserved.

## Verification Evidence

- Debug arm64 build 0.4.0 (24): BUILD SUCCEEDED; no functional changes after the accepted candidate; only a trailing blank line in STTEngineError.swift was normalized during release preparation.
- `verify-ultra-models.sh`: passed — catalog/fallback, isolated defaults, known legacy layouts, grouped optional deletion, symlink/path boundaries and preserved Ultra/cleanup/unknown files.
- `verify-model-catalog-streaming.py`, `verify-dictation-reliability.sh`, existing sanitation and Wave Link checks: passed.
- Debug bundle signature, helper model-path jail, embedded shaders, resource catalog and absence of Whisper framework: verified.
- Maintainer manual acceptance: «все ок, можешь публиковать» on 2026-11-10, in response to the 0.4.0 Debug checklist.
- Local synthetic RU/EN comparison is documented in the quality note; it is not represented as a benchmark.

## Open Risks

- Users with only a retired STT need an explicit Ultra download; release notes disclose this before installation.
- Clean-profile real download/cancel, long/noisy audio and independent offline network audit are not claimed as tested.
- Existing FluidAudio downloader, paste acknowledgement and clipboard-fallback limitations remain. Distribution is not Developer ID notarized.
