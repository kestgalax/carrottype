# Dictation reliability — 0.3.10

## Metadata

- Task ID: T-002
- Status: Done — all Debug manual checks accepted; verified Release DMG published as v0.3.10.
- Title: Clipboard ownership, in-memory recovery, persistent errors and bounded helper IPC

## Traceability

- Product Intent Link: docs/product-intent.md
- Roadmap Item: 0.3.10 — Reliability
- Feature Spec: docs/specs/features/hotkey-carrottype-caret-paste.md
- Related ADRs: docs/decisions/ADR-009-out-of-process-smart-cleanup.md, docs/decisions/ADR-013-local-usage-stats.md, docs/decisions/ADR-015-hub-revision-and-helper-path-jail.md
- Plan: docs/superpowers/plans/2026-11-09-product-improvements.md (R1–R4)

## Scope

Preserve existing dictation, transform, microphone, model, localization and statistics features. Do not change model defaults in this version. Prepare a Debug candidate for user approval, not a published release.

## Acceptance Criteria

- Clipboard restore preserves empty and multi-item/rich snapshots and skips a later external write.
- Selection fallback does not return stale clipboard text when no copy occurs; cancellation finishes its bounded copy observation window before propagating.
- Only the last completed non-empty dictation is retained in RAM until replaced, explicitly cleared, or app exit. It remains available after a cancelled/failed subsequent session. No transcript files/logs are added.
- Known insertion errors show Copy/Close recovery; otherwise the menu offers Copy Last Dictation. Dispatched paste is labelled Done, not verified insertion.
- Ready does not hide last errors or the Details/Check for Updates surface. Errors survive readiness refresh and clear on success or explicit dismissal.
- Helper stdout/stderr drain concurrently with execution; output retention is bounded; timeout and cancellation terminate/reap the helper. Existing Light fallback remains.
- A verified Debug build and manual checklist are delivered before publishing; await explicit user confirmation.

## Verification

- Compile production clipboard/transport code with `scripts/tests/DictationReliabilityChecks.swift`; use isolated named pasteboards and fake helper subprocesses.
- Existing streaming-catalog, preview sanitation and Wave Link port checks.
- Debug xcodebuild, embedded helper/resources and code-signature checks.
- Manual user checks: hotkey → paste, clipboard retention/recovery, Escape, hold-to-talk, live draft, Smart/transform, RU/EN, error details at Ready.
- Offline dictation still expected after model installation; no network/dependency changes. Full offline network audit is not claimed.

## Documentation Updates

- Setup UX, product intent, architecture, ADR-009/013/015, roadmap, CI/test instructions and Debug candidate checklist.

## ADR Impact

Existing ADR must be superseded or amended: ADR-009/013/015 are amended with transport, acknowledgement and clipboard clarifications. No new runtime, dependency or network sink. ADR-013 corrects the acknowledgement claim without changing stored aggregates.
