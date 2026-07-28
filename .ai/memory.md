# Memory

Project memory lives in repository artifacts — not in chat transcripts.

## Canonical sources

- Product: `docs/product-intent.md`
- Status / next steps: `docs/roadmap.md`
- Architecture: `docs/architecture.md`
- Decisions: `docs/decisions/` (ADR-001 … ADR-011)
- Setup UX: `docs/specs/ux-setup-status.md`
- Release notes: `docs/github-release-notes-v0.1.9.md` (prior: `v0.1.8` … `v0.1.0`)
- License / public posture: `LICENSE`, ADR-011, `ops/deploy.md`
- Ops: `ops/deploy.md`, `ops/environments.md`

## Rules

- Prefer updating these files over relying on conversation context.
- Do not delete ADRs, specs, reviews, or roadmap history unless a human maintainer explicitly instructs it.
- When correcting outdated status (e.g. public vs private distribution), update roadmap and deploy notes in the same change.
