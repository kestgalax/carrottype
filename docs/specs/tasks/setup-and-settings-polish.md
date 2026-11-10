# Setup and settings — 0.6.0

## Metadata

- Task ID: CT-SETUP-001
- Title: Guided setup/local trial, compact bindings and truthful formatting (X1–X3)

## Traceability

- Product Intent Link: `docs/product-intent.md`
- Roadmap Item: `docs/roadmap.md` — 0.6.0 Setup/settings
- Feature Spec: `docs/specs/ux-setup-status.md`
- Related ADRs: ADR-005, ADR-009, ADR-010, ADR-012, ADR-014, ADR-016, ADR-017
- Plan: `docs/superpowers/plans/2026-11-09-product-improvements.md`, X1–X3

## Acceptance Criteria

- Ordered microphone/Accessibility/Ultra/trial guidance is available after Welcome and relaunch, using actual readiness and existing download controls. No automatic recording or download.
- Explicit trial uses the existing recorder/mute/STT/formatting pipeline, with output in Settings only. No automatic clipboard, external caret insertion, Last Dictation replacement or usage counting. Cancellation/closing Setup discards output and holds updater reservation through teardown.
- 0–5 transform rows retain all editors, Ready model choices, missing-model/fallback explanation and Models navigation. Empty saved list survives relaunch; capture conflicts preserve existing assignments and capture does not launch a dictation.
- Pipeline returns requested/actual formatting and safe fallback status. Missing/failing MLX cleanup preserves STT via Light, with Capsule notice and Details outcome. Normal paste/recovery/stats remain single-delivery.
- Build Debug for manual confirmation before publication. Existing useful functionality remains; no engine, dependency, network or distribution change.

## Verification

- Check: `scripts/verify-setup-formatting.sh` compiles actual production progress, formatting, delivery, binding store/resolver and hotkey service with isolated defaults/no global registration.
- Check: Debug arm64 build and existing reliability, Ultra, updater-gate and catalog checks.
- Check: isolated UI-review app launches its first-run window without touching the installed copy; native UI observation is blocked by Orca provider `permission_denied` despite permission inventory reporting granted. Detailed visual/microphone/hotkey/manual checks remain in `docs/debug-review-v0.6.0.md`.

## Documentation Updates

- Update: Setup UX contract before implementation, product intent, architecture, roadmap, workflow/memory, Debug checklist and draft release notes.

## ADR Impact

Follows accepted ADR-012 and existing ADR-005/009/010/014/016/017. No new runtime, model policy, dependency, network sink or distribution trust decision. Full lifecycle coordinator remains 0.6.1.

## Completion

Shipped as v0.6.0 (26) after user Debug acceptance on 2026-11-10. Clean Release, DMG, signed local/draft/public assets and native update-discovery checks passed; evidence/remaining limits are in `docs/debug-review-v0.6.0.md`. Next stage: 0.6.1 lifecycle/tests.
