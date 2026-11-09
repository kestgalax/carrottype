# Dictation reliability — release review

## Metadata

- Review ID: R-002
- Outcome: Approve

## Traceability Check

- Product Intent Link: docs/product-intent.md
- Roadmap Item: 0.3.10 — Reliability
- Feature Spec: docs/specs/features/hotkey-carrottype-caret-paste.md
- Task: docs/specs/tasks/dictation-reliability.md
- Related ADRs: docs/decisions/ADR-009-out-of-process-smart-cleanup.md, docs/decisions/ADR-013-local-usage-stats.md, docs/decisions/ADR-015-hub-revision-and-helper-path-jail.md

## Governance Checklist

- Product intent respected: hotkey → local STT → optional cleanup → paste remains; last-result RAM recovery prevents loss without adding transcript files.
- Architecture respected: no new engines, dependencies, network sinks or model defaults; helper remains process-per-request.
- Existing functions preserved: model catalog unchanged; bindings, live draft, Wave Link, input/meter, clipboard option, RU/EN and statistics remain available.
- Verification evidence present: Debug build and production-code harness passed; user confirmed all manual checklist items in docs/debug-review-v0.3.10.md. Release packaging and signature/hash verification are recorded in release notes when complete.

## ADR Impact

Existing ADR must be superseded or amended: ADR-009/013/015 clarified for concurrent bounded IPC, dispatch-based statistics and ownership-aware clipboard restore. No new trust posture or runtime.

## Verification Evidence

- Debug xcodebuild: BUILD SUCCEEDED, arm64, version 0.3.10 build 23; accepted by the user before publication preparation. No subsequent app-source changes.
- `bash scripts/verify-dictation-reliability.sh`: passed; tests compile production clipboard, selection fallback, transport and protocol code.
- Existing streaming catalog, live-draft sanitize and Wave Link port checks: passed.
- Deep signature and embedded-helper model-path jail smoke on Debug candidate: passed.
- Human manual acceptance: user response «по всем — ок» to the five-part checklist covering dictation, recovery, clipboard, errors and existing features.

## Open Risks

- No universal paste acknowledgement; Copy Last Dictation is the recovery path.
- Selection-copy fallback cannot identify a concurrent external clipboard writer; documented residual.
- Full offline network audit and independent GUI automation not performed; manual acceptance is the maintainer's evidence.
- Distribution remains without Apple Developer ID notarization; retain Gatekeeper install instructions.
