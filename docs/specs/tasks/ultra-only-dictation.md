# Ultra-only dictation — 0.4.0

## Metadata

- Task ID: T-003
- Title: One dictation model with explicit migration and optional legacy cleanup
- Status: Debug accepted by the user on all checklist items (2026-11-10); publication authorized, Release packaging in progress.

## Traceability

- Product Intent Link: docs/product-intent.md
- Roadmap Item: 0.4.0 — Ultra-only dictation
- Feature Spec: docs/specs/features/hotkey-carrottype-caret-paste.md
- Related ADRs: docs/decisions/ADR-016-ultra-only-dictation.md, docs/decisions/ADR-006-parakeet-fluidaudio-stt.md, docs/decisions/ADR-014-live-dictation-streaming.md
- Plan: docs/superpowers/plans/2026-11-09-product-improvements.md (M1–M3)

## Acceptance Criteria

- Only Ultra is offered in catalog and fallback; no STT picker. Download/cancel/retry/delete remains, without automatic model downloads.
- Old/unknown saved STT ids map to Ultra; installed Ultra is reused; without Ultra, setup explicitly requires download and does not claim offline readiness.
- No automatic deletion of old weights. Known retired paths remain visible in Storage with confirmed per-group removal; never touch Ultra/cleanup, unknown experiments, shared Apple system assets or symlink escapes.
- Whisper/Apple adapters and WhisperMetalKit dependency removed with ADR-016 coverage; all remaining dependency pins unchanged.
- Formatting, Translate/Custom, live draft, file final pass, hold-to-talk, Wave Link, clipboard/recovery, input/meter, RU/EN and statistics remain.
- Debug candidate delivered with migration/RU/EN/live-draft checklist; no publication before separate user confirmation.

## Verification

- `bash scripts/verify-ultra-models.sh`: production catalog, preference migration and legacy-storage fixtures; uses no installed model deletion or real user defaults.
- Streaming catalog and 0.3.10 regression suite.
- macOS arm64 Debug build; deep signature/helper/resource checks; confirm no embedded Whisper framework.
- Manual Debug gate: Ultra installed/unavailable, RU/EN/mixed/number phrases, toggle/PTT/Escape/live draft, cleanup/transform, optional old-model removal and preservation of other features.
- Offline dictation expected with installed Ultra; no new network sink. Full independent network audit remains deferred.

## Documentation Updates

- ADR-016 + historical ADR supersession notes, quality-note Result (explicit user choice, no fabricated scores), product intent/architecture, README/macOS README, UX, security/supply-chain, ops, roadmap and manual checklist.

## ADR Impact

Follows accepted ADR-016. Existing ADR-003/004/006/008 are amended to identify their superseded STT-offerings policy; ADR-014 behavior is preserved. No new runtime or dependency; removal of WhisperMetalKit is intentional.
