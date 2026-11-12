# AIDOS pilot migration hygiene

## Metadata

- Task ID: aidos-pilot-migration-hygiene
- Title: AIDOS pilot migration hygiene
- Status: Delivery for review; not merged, not released

## Traceability

- Product Intent Link: docs/product-intent.md
- Roadmap Item: AIDOS pilot migration (separate branch)
- Feature Spec: docs/specs/features/aidos-pilot-migration-hygiene.md
- Related ADRs: docs/decisions/ADR-001-initial-project-structure.md
- Evidence: docs/debug-review-aidos-pilot-migration.md

## Acceptance Criteria

- Applied files are limited to future-artifact templates and additive AIDOS guidance; `.ai` governance, config, launcher, ADRs, roadmap history and product intent are unchanged except documented additive pointers.
- `.ai/memory.md` keeps all existing content and gains only one short pilot note; `.ai/constraints.md`, `.ai/workflow.md` and role files are byte-identical to `main`.
- `aidos.config.json` remains `{"toolingRoot": "../AIDOS"}` without `schema` or `contractVersion`, and `scripts/run-aidos.mjs` is unchanged.
- `aidos validate` exits 0; `trace`/`review` findings are recorded with their real exit codes and reasons; `closure aidos-pilot-migration-hygiene` records a structural result for this flow only.
- `git diff --check` passes and `git diff --name-only main...HEAD -- macos` is empty; no version, DMG, update feed or release artifact changes.

## Verification

- `AIDOS_ROOT=/Users/kestgalax/orca/workspaces/AIDOS/aidos-adr008-evidence-guidance node "$AIDOS_ROOT/bin/aidos.js" validate` — expect exit 0.
- `… aidos.js trace` — expect exit 1 with only the documented historical `update-locale-and-quit-install -> Feature Spec` link and advisory notes.
- `… aidos.js review` — expect `Approve` after the docs-only `ADR Impact` wording correction.
- `… aidos.js closure aidos-pilot-migration-hygiene` — expect this flow closable; other flows are out of scope.
- `git diff --check`; `git diff --stat main...HEAD`; `git diff --name-only main...HEAD -- macos` (empty).
- Compare `.ai/constraints.md`, `.ai/workflow.md`, `.ai/planner.md`, `.ai/developer.md`, `.ai/reviewer.md`, `.ai/constitution.md`, `aidos.config.json`, `scripts/run-aidos.mjs` against `origin/main` (empty diffs).

## Documentation Updates

- `docs/debug-review-aidos-pilot-migration.md` — baseline, classification, apply log and verification outcomes.
- `docs/roadmap.md` — additive `Current Status` block; historical sections retained.
- `.ai/memory.md` — additive pilot note only.
- `docs/specs/tasks/2026-11-12-aidos-pilot-migration.md` — operational pilot record and result.
- `docs/specs/features/aidos-pilot-migration-hygiene.md` and this task — the one pilot flow.

## ADR Impact

No ADR impact. Follows accepted ADR-001 and introduces no new engine, dependency, network sink, distribution channel or trust model. A permanent tooling pin, `contractVersion: 2` adoption or domain specs would be separate decisions.
