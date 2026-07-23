# Constitution

## Definition Of Done

- The requested outcome is implemented within the assigned scope.
- Verification has been run when available (at least a Debug build for app changes; DMG rebuild only when the task is a release ship).
- Skipped checks are explained with residual risk.
- `docs/roadmap.md` reflects completed work and the next focus.
- Documentation is updated when behavior, workflow, architecture, or decisions change.
- ADRs are added or updated for durable decisions (stack, engines, catalog policy, distribution).

## Governance Rules

- Product intent constrains implementation (`docs/product-intent.md`).
- Architecture and engine changes require ADR coverage (`docs/decisions/`).
- Humans retain control over critical decisions (shipping, notarization, flipping `recommended` STT).
- Prefer small, reviewable increments over speculative redesign.
