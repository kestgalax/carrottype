# AIDOS pilot migration — 2026-11-12

## Metadata

- Task ID: 2026-11-12-aidos-pilot-migration
- Title: Безопасный AIDOS-пилот для CarrotType на отдельной ветке
- Status: In progress — docs/governance only, no application or release change
- Created: 2026-11-12
- Consumer base: `origin/main` `c26fc7f` — published **0.11.1 (36)**, accepted behavior `f0cff02`
- Branch: `kestgalax/aidos-pilot-migration` (separate; no merge to `main`, no push required)
- Tooling: `AIDOS_ROOT=/Users/kestgalax/orca/workspaces/AIDOS/aidos-adr008-evidence-guidance` (stacked tip `74a4d8b`, includes `init --update --dry-run/--diff`, freshness, closure and evidence guidance)

## Traceability

- Product Intent Link: docs/product-intent.md
- Roadmap Item: AIDOS pilot migration (separate branch)
- Feature Spec: docs/specs/features/aidos-pilot-migration-hygiene.md
- Related ADRs: docs/decisions/ADR-001-initial-project-structure.md
- Evidence: docs/debug-review-aidos-pilot-migration.md
- Migration intent (read-only): `aidos-context-migration-plan/docs/specs/tasks/context-and-consumer-migration-plan.md` and `context-migration-dry-run-inventory.md`
- AIDOS exit criteria: `aidos-adr008-evidence-guidance/docs/reviews/milestone-8-exit-review.md`, `docs/consumer-contract-guidance.md`

## Authorization and hard limits

Maintainer approved this pilot on a separate branch until an explicit proper merge. The pilot therefore:

- does not merge to `main`, does not bump version/build, does not build a DMG, does not publish and does not create a release;
- does not change Swift application sources, model catalog/runtime, Keychain, login items, user profile or release assets;
- keeps `.ai/memory.md`, custom privacy/trust/release gates and the audit trail; template refreshes are limited to future-artifact templates;
- stays at `contractVersion: 1` and does not add `aidos.config.json` `"schema": 2`;
- does not rewrite historical features/reviews/ADRs and does not force the `aidos archive` gate.

## Phase 0 — Baseline (2026-11-12)

| Item | Recorded state |
| --- | --- |
| CarrotType HEAD / branch | `c26fc7f` = `origin/main`; branch `kestgalax/aidos-pilot-migration` |
| Version identity | `macos/CarrotType/Resources/ReleaseNotes.json` → `version: 0.11.1`, `build: 36`; published 2026-11-12T00:10:38Z from `v0.11.1` / `5bc877b` |
| `aidos.config.json` | `{"toolingRoot": "../AIDOS"}` — no `schema`, no `contractVersion` |
| Launcher | `scripts/run-aidos.mjs` resolves `AIDOS_ROOT` first, then `toolingRoot` (`../AIDOS`) |
| Tooling for the pilot | `node "$AIDOS_ROOT/bin/aidos.js"` with `AIDOS_ROOT` at the stacked tip `74a4d8b` |
| Sibling `Projects/2026/AIDOS` | Not used for the pilot; documented as stale for this work |

Baseline governance results (full output and limits in the evidence doc):

| Command | Exit | Short summary |
| --- | --- | --- |
| `aidos validate` | 0 | Repository structure passes |
| `aidos trace` | 1 | One missing link: `docs/specs/tasks/update-locale-and-quit-install.md -> Feature Spec`; freshness/stale ADR links none; ADR-001 architecture-link advisory |
| `aidos review` | 1 | Outcome `Block`: `update-locale-and-quit-install` `ADR Impact` wording is not an allowed outcome; all other findings advisory |

The noisy baseline is recorded, not hidden. No product code is changed to silence it. One docs-only artifact-shape correction (`ADR Impact` wording in the 0.11.1 bugfix task, meaning preserved) is applied to remove the only blocking review finding.

## Plan / classification

The full per-path create/update/keep/skip classification from `init --update --dry-run/--diff` is in [the evidence doc](../../debug-review-aidos-pilot-migration.md). The agreed scope of this pilot:

- **apply**: `docs/specs/{feature,task,review}-template.md` for future artifacts; create `docs/specs/domain-spec-template.md`, `docs/specs/spike-template.md`, `docs/consumer-contract-guidance.md`, `ops/evidence-manifest.md`, `ops/verification-profiles.md`, `ops/agent-release-lifecycle.md`;
- **keep**: all `.ai/*` role/workflow/constitution/constraints/memory files, `aidos.config.json`, `scripts/run-aidos.mjs`, `AGENTS.md`, product intent, roadmap history, architecture, ADRs, existing `ops/*`, README, historical specs/reviews;
- **defer**: schema 2 / domain specs / tooling pin / updater or dictation domain wave 2.

## Acceptance Criteria

- All pilot changes exist only on `kestgalax/aidos-pilot-migration`; `main`, tags, version/build, DMG/update feed and published assets are untouched.
- `.ai/memory.md` and custom `.ai` gates remain intact; only an additive current-status note is added to memory and roadmap.
- Template-owned refreshes and new AIDOS guidance files are the only AIDOS-applied changes; no Swift/application source diff exists.
- `aidos validate`, `trace`, `review` run against `AIDOS_ROOT` tip `74a4d8b`; outcomes and residual findings are recorded in the evidence doc.
- One docs/governance pilot flow (schema 2 artifacts) is created and `aidos closure <review-slug>` is recorded as closable or not closable with reasons.
- `git diff --check` passes; no secrets, DerivedData, `dist/` apps or generated artifacts are committed.

## Verification

- `AIDOS_ROOT=… node "$AIDOS_ROOT/bin/aidos.js" validate` — repository structure.
- `AIDOS_ROOT=… node "$AIDOS_ROOT/bin/aidos.js" trace` — field presence and freshness.
- `AIDOS_ROOT=… node "$AIDOS_ROOT/bin/aidos.js" review` — repository artifact structure.
- `AIDOS_ROOT=… node "$AIDOS_ROOT/bin/aidos.js" closure aidos-pilot-migration-hygiene` — one-flow closure only.
- `git diff --check` and `git diff --stat` — whitespace, scope and absence of app files.
- `git diff --name-only main...HEAD -- macos` — must be empty; no version, DMG or release change.

## Documentation Updates

- `docs/debug-review-aidos-pilot-migration.md` — dry-run classification, apply log, verification outcomes and residual risks.
- `docs/roadmap.md` — compact `Current Status` block above retained history.
- `.ai/memory.md` — short durable note about the pilot branch, explicitly not a release claim.
- `docs/specs/tasks/2026-11-12-aidos-pilot-migration.md` — this record (baseline + result).
- New AIDOS guidance copies and templates listed in the plan.

## ADR Impact

No ADR impact. This is a docs/governance migration; ADR-001 (AIDOS repository artifacts) is respected, ADR-002 runtime and ADR-011 distribution remain unchanged, and no new engine, network sink, dependency or trust model is introduced. A permanent tooling pin or schema 2 adoption would be a separate reviewable decision.
