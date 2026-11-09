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
- Debug was delivered and the maintainer explicitly authorized publication. Clean Release packaging and draft/public asset checks passed. Individual UI/TCC results were not enumerated and are not inferred from automated checks; future releases retain their own Debug/manual gate.

## Verification

- Check: `scripts/verify-app-updates.sh`, real Sparkle `scripts/verify-update-staging.py`, Debug build, reliability/Ultra regressions and AIDOS checks passed. Evidence and remaining independent manual UI/TCC limits: `docs/debug-review-v0.5.0.md`.
- Check: `verify-update-release.py` passed on the draft and published 0.5.0 assets; anonymous stable feed/archive bytes match the verified assets. Native Sparkle accepted the live feed and returned no-update for the current build.

## Documentation Updates

- Update: ADR-017, architecture, product intent, closed sinks, supply chain, security checklist, Setup UX, README, ops/deploy, roadmap, workflow/memory and Debug review.

## ADR Impact

Follows accepted ADR-017. Existing local inference/runtime and manual data-deletion policies remain unchanged.
