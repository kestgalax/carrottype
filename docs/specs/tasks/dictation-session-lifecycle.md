# Dictation session lifecycle and production checks

## Metadata

- Task ID: dictation-session-lifecycle
- Title: Extract recording ownership, pin engine settings and serialize teardown
- Target: 0.6.2 (28), branch `refactor/dictation-session-lifecycle` from main after 0.6.1
- Status: implementation and verification in progress; not published

## Traceability

- Product Intent Link: `docs/product-intent.md` — reliable local hotkey → STT → caret paste
- Roadmap Item: `docs/roadmap.md` — 0.6.2 maintainability
- Feature Spec: `docs/specs/ux-setup-status.md`
- Related ADRs: ADR-007, ADR-009, ADR-012, ADR-014, ADR-016, ADR-017
- Plan: `docs/superpowers/plans/2026-11-09-product-improvements.md`, C1–C2

## Scope

C1: Foundation/main-actor `DictationSessionCoordinator` owns queued start, capture, unmute/preview tasks, finish/cancel, result discard, temp WAV and awaited final engine unload under a single `UpdateInstallationGate` reservation. AppState keeps settings and UI/caret/trial/stats delivery. Snapshot model/path/formatting, input and active shortcut mode before scheduling. Keep clipboard and statistics opt-ins live, preserving existing delivery behavior. Idle unload/deletion reserve synchronously; refuse while pipeline is busy. Transform teardown awaits unload before releasing its lease. Ordinary Quit closes new starts and drains cancellation/cleanup; existing Sparkle termination/install policy runs first.

C2: extract existing preview sanitation/silence trimming and Wave Link port ordering into production helpers; checks compile those exact files. Add controlled-delay lifecycle tests and targeted mutation evidence, integrate existing regression checks into GitHub Actions and compile Debug on a compatible Xcode runner. No runtime/dependency/engine or UI redesign.

## Acceptance Criteria

- Exactly one owner/teardown across starting/recording/transcribing/cleaning/finishing/cancelling/idle; queued PTT release, repeated stop/Escape and cancelled trial never cause duplicate delivery or cleanup.
- Restore waits for in-flight unmute; preview detaches on stop/cancel, late callbacks/peaks cannot alter a later session. WAV cleanup and engine unload finish before next start/install; failure/cancellation paths retain the lease.
- Model/formatting changes apply next session. All UI package deletion paths use reserved maintenance and cannot unload/delete under active capture/STT/formatting/transform. Busy deletion is reported with retry guidance; no useful function removed.
- Normal caret, trial isolation, live-draft Copy, recovery, hold/toggle, microphone/meter/Wave Link, RU/EN, Storage/stats and signed updater behavior remain. Ordinary Quit cancels and drains active work before AppKit termination; abnormal process kill retains existing best-effort limits.
- Tests exercise actual coordinator/gate and production helpers, including non-cooperative fake model load and process results, failures, stale callbacks, temp cleanup, delete/unload/termination handoff. Tests must fail when production logic is deliberately broken in temporary copies, never the checkout.
- CI preserves governance checks and adds no-microphone/no-model regressions plus unsigned Debug compilation. External CI tooling/actions pinned; no private keys, user data or release publishing in the workflow.
- Deliver Debug/checklist and wait for this version’s explicit acceptance before publication.

## Verification

- Check: `bash scripts/verify-session-lifecycle.sh`, plus existing reliability/setup/Ultra/update/release-notes/catalog checks.
- Check: temporary-copy mutation tests for coordinator cleanup, preview sanitation and cached-port priority; restore no broken code because tracked files are never mutated.
- Check: local Debug arm64 and GitHub workflow validation/run when available. Native microphone/TCC/hotkeys/quit/mute and real model cold starts remain explicit manual checks.
- Check: governance validate/trace/review, documentation links and diff checks.

## Documentation Updates

- Update: architecture/resource ownership, Setup/session contract, ops/CI, roadmap, workflow/memory, Debug checklist and generated release notes.

## ADR Impact

No ADR impact. Follows accepted ADR-007/009/014/017 and the approved C1–C2 plan. No new runtime/resource retention model: still capture-first preview, file-final STT, helper per request and unload after operations. New teardown coordination enforces the existing policies; installation trust/network sinks are unchanged.

## Streaming boundary finding

Review found that the streaming actor read its mutable `onUpdate` after an awaited transcription and AudioRecorder reused a mutable fanout/peak callback. A late old pass/tap could therefore invoke the next epoch's callback even with UI token checks. The implementation captures callback/epoch, joins the preview loop, uses epoch-bound PCM attachment and per-capture fanout/peak routing. `StreamingEpochChecks.swift` compiles the actual actor/fanout with a separate test-only FluidAudio module to control inference/cancellation; no production conditional SDK stub or mirrored algorithm is added. This does not claim real CoreML/microphone coverage.
