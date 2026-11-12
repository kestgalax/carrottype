# AIDOS pilot migration hygiene

## Metadata

- Feature ID: F-005
- Title: AIDOS pilot migration hygiene
- Status: Pilot delivered for review; not merged, not released

## Traceability

- Product Intent Link: docs/product-intent.md
- Roadmap Item: AIDOS pilot migration (separate branch)
- Related ADRs: docs/decisions/ADR-001-initial-project-structure.md
- Task: docs/specs/tasks/aidos-pilot-migration-hygiene.md
- Evidence: docs/debug-review-aidos-pilot-migration.md

## Problem

CarrotType is a living AIDOS consumer whose governance artifacts predate the current AIDOS
template and report contract. Its feature/review templates have no `Behavior Delta` or `Schema: 2`,
there is no domain/spike template, and consumer guidance is not present in the repository. At the
same time, its custom `.ai` rules encode real privacy, trust and release gates that a blunt
`init --update --confirm-overwrite` would destroy. The hygiene gap is templates and guidance, not
product behavior.

## Scope

Docs/governance only, on a separate pilot branch:

- refresh future-artifact templates and add missing AIDOS consumer guidance;
- keep `.ai/memory.md`, `.ai/constraints.md`, `.ai/workflow.md`, role files, `aidos.config.json`
  and the launcher project-owned;
- document the tooling override and residual findings instead of hiding them;
- create one docs-only schema 2 flow so closure can be evaluated for that flow.

Out of scope: application behavior, engines/models, Keychain/login items, version/build, DMG or
update feed, publication, `contractVersion: 2`, domain specs wave 2 and a permanent tooling pin.

## Behavior Delta

Domain spec: none — this feature changes repository governance artifacts only.

**No behavior change.** The application, its settings, dictation/transform loops, updater,
distribution trust and release gates are unchanged.

## Acceptance Criteria

- Future feature/task/review templates carry the current AIDOS shape: `Behavior Delta`, allowed
  `ADR Impact` outcomes, `Schema: 2` and `## Verification Review`; historical artifacts are not rewritten.
- `.ai/memory.md` and every custom `.ai` rule survive the pilot; memory receives only an additive note.
- `aidos.config.json` stays without `schema`; the launcher and `toolingRoot` are untouched, and the
  pilot documents `AIDOS_ROOT` tip `74a4d8b` plus the stale sibling caveat.
- `aidos validate`, `trace`, `review` and one-flow `closure` are executed and recorded with exit
  codes, including the single historical missing link that is not silenced.
- The branch contains no Swift/app-source, version, DMG or release change and is not merged to `main`.

## Verification Plan

- Run `AIDOS_ROOT=… node "$AIDOS_ROOT/bin/aidos.js" validate` and record the exit code.
- Run `trace` and `review`; compare with the Phase 0 baseline and record every residual finding.
- Run `closure aidos-pilot-migration-hygiene`; record closable/not closable and reasons.
- Run `git diff --check`, `git diff --stat` and confirm `git diff --name-only main...HEAD -- macos`
  is empty.
- Compare `.ai/memory.md`, `.ai/constraints.md`, `.ai/workflow.md`, role files, `aidos.config.json`
  and `scripts/run-aidos.mjs` against `main` to prove custom ownership.
- Spot-check that the applied templates match the `init --diff` preview and that no historical
  ADR/feature/review file was rewritten.

## Documentation Impact

- `docs/debug-review-aidos-pilot-migration.md` — dry-run classification, apply log, verification and limits.
- `docs/roadmap.md` — one compact `Current Status` block above retained history.
- `.ai/memory.md` — short durable pilot note.
- `docs/consumer-contract-guidance.md`, `ops/evidence-manifest.md`, `ops/verification-profiles.md`,
  `ops/agent-release-lifecycle.md` — additive AIDOS guidance copies.
- `docs/specs/{feature,task,review,domain-spec,spike}-template.md` — future-artifact templates only.

## ADR Impact

No ADR impact. Follows accepted ADR-001 (AIDOS repository artifacts as durable governance) and keeps
ADR-002/ADR-011 runtime and distribution decisions unchanged; no new engine, dependency, network
sink or trust model is introduced.
