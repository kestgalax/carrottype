# GitHub application updates — 0.5.0

## Metadata

- Task ID: CT-UPDATES-001
- Title: Signed opt-in native application updates, U1–U3

## Traceability

- Product Intent Link: `docs/product-intent.md`
- Roadmap Item: `docs/roadmap.md` — GitHub app updates, 0.5.0
- Feature Spec: `docs/specs/ux-setup-status.md`
- Related ADRs: ADR-017, ADR-011, ADR-016
- Execution plan: `docs/superpowers/plans/2026-11-09-product-improvements.md`, U1–U3

## Acceptance Criteria

- Sparkle checks/downloads default off; native menu/details/settings UI shares actual updater state.
- Required signed feed/archive, persistent Keychain key, no profiling/upload; exact dependency pin and documented GitHub sink.
- Operation reservations and final termination gate prevent an install interrupting active work; no functions removed.
- Repeatable local signing/release gates and isolated A → B native installer smoke; first install manual, existing external data preserved.
- Debug/manual UI/TCC and Release packaging acceptance remain required before publication. Automated checks do not mark those pending human gates complete.

## Verification

- Check: `scripts/verify-app-updates.sh`, real Sparkle `scripts/verify-update-staging.py`, Debug build, reliability/Ultra regressions and AIDOS checks passed. Evidence and pending manual checklist: `docs/debug-review-v0.5.0.md`.
- Check: `verify-update-release.py` is a read-only draft/public asset gate, to run during actual release preparation; no 0.5.0 remote assets exist yet.

## Documentation Updates

- Update: ADR-017, architecture, product intent, closed sinks, supply chain, security checklist, Setup UX, README, ops/deploy, roadmap, workflow/memory and Debug review.

## ADR Impact

Follows accepted ADR-017. Existing local inference/runtime and manual data-deletion policies remain unchanged.
