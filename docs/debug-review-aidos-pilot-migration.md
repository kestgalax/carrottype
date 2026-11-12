# Debug review — AIDOS pilot migration

- Date: 2026-11-12
- Branch: `kestgalax/aidos-pilot-migration` from `origin/main` `c26fc7f` (no merge to `main`)
- Scope: AIDOS governance/templates only; no Swift, model, Keychain, login-item, version, DMG, update-feed or publication change
- AIDOS tooling: `AIDOS_ROOT=/Users/kestgalax/orca/workspaces/AIDOS/aidos-adr008-evidence-guidance`, tip `74a4d8b`
- Task record: [2026-11-12-aidos-pilot-migration](specs/tasks/2026-11-12-aidos-pilot-migration.md)
- Evidence: declared and file-based; AIDOS commands below were executed locally, but AIDOS itself does not re-execute declared commands

> This document is the pre-apply dry-run report and the verification record. It was committed before
> any template refresh was applied. Structure/closure results describe markdown artifacts only; they
> are not code approval, release authorization or a merge decision.

## 1. Why `AIDOS_ROOT` and not the sibling checkout

`aidos.config.json` keeps `toolingRoot: "../AIDOS"` and `scripts/run-aidos.mjs` keeps its current
resolution order. The sibling `../AIDOS` is absent in this worktree, and the older
`Projects/2026/AIDOS` checkout is stale for this task (no `init --update --dry-run`/`--diff`).
For the pilot every command was invoked explicitly with:

```sh
export AIDOS_ROOT=/Users/kestgalax/orca/workspaces/AIDOS/aidos-adr008-evidence-guidance
node "$AIDOS_ROOT/bin/aidos.js" <command>
```

A permanent tooling pin is **deferred**: replacing the launcher/config in this slice could break
existing local scripts and GitHub Actions, and it needs its own review. The pilot does not pretend
that `toolingRoot` alone works without the sibling checkout.

## 2. Baseline (before any change)

| Command | Exit | Result |
| --- | --- | --- |
| `aidos validate` | 0 | `AIDOS validation passed` |
| `aidos trace` | 1 | 4 features / 15 tasks / 5 reviews / 19 ADRs; one missing link: `docs/specs/tasks/update-locale-and-quit-install.md -> Feature Spec`; no stale ADR links; advisory: ADR-001 is not referenced by `docs/architecture.md` |
| `aidos review` | 1 | `Outcome: Block`; blocking: `update-locale-and-quit-install` `ADR Impact` is missing or does not use an allowed outcome; 7 advisory notes (ADR-001 architecture link, 4 legacy features without `Behavior Delta`, 2 legacy reviews not gated on Schema 2) |

Additional baseline facts:

- `macos/CarrotType/Resources/ReleaseNotes.json` → `version 0.11.1`, `build 36`; published behavior `f0cff02`.
- `aidos.config.json` → `{"toolingRoot": "../AIDOS"}`; no `schema`, no `contractVersion`.
- `docs/specs/` has 4 legacy features, 15 tasks, 5 legacy reviews, no `domains/`, no domain/spike templates.
- `docs/specs/review-template.md` is legacy (no `Schema`, no `## Verification Review`).

Baseline noise is recorded as-is. Product code is not changed to silence governance findings.

## 3. Preview only — `init --update --dry-run` and `--diff`

Commands (run from the repository root, no writes):

```sh
node "$AIDOS_ROOT/bin/aidos.js" init . --update --dry-run   # exit 0
node "$AIDOS_ROOT/bin/aidos.js" init . --update --diff      # exit 0
```

Preview result: **7 created, 11 updated (would be refreshed only with `--confirm-overwrite`),
12 kept, 1 skipped**. `--diff` produced 616 lines; every update below was inspected.

### 3.1 Classification and decision

| Path | Preview action | Decision | Reason |
| --- | --- | --- | --- |
| `docs/specs/domain-spec-template.md` | create | **apply** | Needed for future schema 2 domain specs; additive |
| `docs/specs/spike-template.md` | create | **apply** | Separates research from features; additive |
| `docs/consumer-contract-guidance.md` | create | **apply** | Explains validate/trace/review/closure/archive scopes; additive |
| `ops/evidence-manifest.md` | create | **apply** | Portable evidence shape; complements existing `ops/*` |
| `ops/verification-profiles.md` | create | **apply** | Verification profiles; guidance only |
| `ops/agent-release-lifecycle.md` | create | **apply** | Agent/release lifecycle; guidance only |
| `ops/native-verification-examples.md` | create | **skip** | Duplicates `verification-profiles` and existing release docs; keep the pilot surface small |
| `docs/specs/feature-template.md` | update | **apply** | Future-artifact template: adds `## Behavior Delta` |
| `docs/specs/task-template.md` | update | **apply** | Future-artifact template: evidence/closure note and allowed ADR outcomes |
| `docs/specs/review-template.md` | update | **apply** | Future-artifact template: `Schema: 2`, `## Verification Review`, evidence rules |
| `aidos.config.json` | update (merge-additive, sets `schema: 2`) | **keep** | Pilot stays `contractVersion`/legacy-compatible; schema 2 is deferred |
| `scripts/run-aidos.mjs` | update | **keep** | Would switch to `aidos` on PATH; a pin decision is deferred |
| `.ai/constitution.md` | update | **keep** | Custom governance; refresh would delete project-specific DoD/rules |
| `.ai/constraints.md` | update | **keep** | Custom privacy/data-flow/network-sink/trust gates must not be replaced |
| `.ai/workflow.md` | update | **keep** | Custom Debug/manual/publication gates and history must be preserved |
| `.ai/planner.md` | update | **keep** | Custom role with project planning rules |
| `.ai/developer.md` | update | **keep** | Custom role with Swift/settings/release rules |
| `.ai/reviewer.md` | update | **keep** | Custom review priorities and outcomes |
| `.ai/memory.md` | keep | **keep** | Never replaced; only an additive note is added manually |
| `AGENTS.md` | keep | **keep** | Project-owned entry point with required reading and branch rule |
| `docs/product-intent.md` | keep | **keep** | Project-owned intent |
| `docs/roadmap.md` | keep | **keep** (manual additive `Current Status` only) | Project-owned history; no rewrite |
| `docs/architecture.md` | keep | **keep** | Project-owned architecture |
| `docs/decisions/ADR-*.md` | keep | **do not touch** | Append-only decision memory |
| `ops/ci.md`, `ops/deploy.md`, `ops/environments.md`, `ops/troubleshooting.md` | keep | **keep** | Custom operations/release procedure |
| `README.md` | keep | **keep** | Product-facing |
| `package.json` | skip | **keep** | Exists; scripts unchanged |
| `docs/specs/features/*`, `docs/specs/tasks/*`, `docs/specs/reviews/*` | not in plan | **do not touch** | Historical artifacts stay as-is (one docs-only ADR Impact wording fix excepted, see 3.3) |

### 3.2 Safety-critical paths

The preview would delete or weaken `.ai/constraints.md` (73 → 5 lines), `.ai/workflow.md`
(145 → 42 lines) and the role files if `--confirm-overwrite` were run in the repository. The tool
does classify `.ai/memory.md` as `keep`, but it would still rewrite the rest of the custom `.ai`
governance. Therefore the pilot did **not** run `--confirm-overwrite` in the repository. It ran it
in a disposable copy and copied only the approved paths (section 4).

No preview path touches ADRs, product intent, architecture, roadmap, `AGENTS.md`, `ops/deploy.md`,
`ops/ci.md`, Swift sources, `macos/` or `.github/`.

### 3.3 One artifact-shape correction (docs only)

`docs/specs/tasks/update-locale-and-quit-install.md` said `No new ADR. Follows ADR-017: …`.
AIDOS requires an allowed outcome phrase; `No new ADR` does not match. The fix changes only the
first sentence to `No ADR impact.` and keeps the ADR-017 explanation and every other line intact.
This removes the only blocking review finding without changing product or historical evidence.

The remaining baseline `trace` finding (the same task has no `Feature Spec` link) is left as
documented noise: the 0.11.1 update-language fix is a bugfix inside the existing product loop, and
inventing a feature link just to silence the field check would be less truthful.

## 4. Apply log (Phase 2)

1. Created a disposable copy of the repository (excluding `.git`) under the session temp directory.
2. Ran in the copy:
   `node "$AIDOS_ROOT/bin/aidos.js" init <scratch> --update --confirm-overwrite` → exit 0.
3. Copied **only** these rendered files back, byte-for-byte:
   `docs/specs/feature-template.md`, `task-template.md`, `review-template.md`,
   `domain-spec-template.md`, `spike-template.md`, `docs/consumer-contract-guidance.md`,
   `ops/evidence-manifest.md`, `ops/verification-profiles.md`, `ops/agent-release-lifecycle.md`.
4. Verified that these files match the `--diff` preview and that every `.ai/*` file,
   `aidos.config.json`, `scripts/run-aidos.mjs`, ADRs, roadmap history and `AGENTS.md` are unchanged
   by the apply.
5. Added a compact `Current Status` block at the top of `docs/roadmap.md`; history below is retained.
6. Added a short durable note in `.ai/memory.md`; no memory content was removed.

## 5. Phase 3 — one docs/governance flow

`aidos new flow "AIDOS pilot migration hygiene"` creates schema 2 feature/task/review artifacts
without touching product behavior. The flow describes the migration boundary, evidence, residual
risks and the deferred items (schema 2 config, domains, tooling pin). `aidos closure` is run on that
review slug only.

## 6. Verification (Phase 4)

All commands were run from the repository root with the same `AIDOS_ROOT` tip `74a4d8b`.

| Check | Command | Exit / result |
| --- | --- | --- |
| Repository structure | `node "$AIDOS_ROOT/bin/aidos.js" validate` | **0** — `AIDOS validation passed` |
| Traceability | `node "$AIDOS_ROOT/bin/aidos.js" trace` | **1** — 5 features / 17 tasks / 6 reviews / 19 ADRs; only missing link is the documented historical `update-locale-and-quit-install -> Feature Spec`; no stale ADR links; ADR-001 architecture-link advisory unchanged |
| Artifact review | `node "$AIDOS_ROOT/bin/aidos.js" review` | **0** — `Outcome: Approve`; blocking findings none; advisory notes are the pre-existing ADR-001 architecture link, 4 legacy features without `Behavior Delta`, 2 legacy reviews without Schema 2 |
| One-flow closure | `node "$AIDOS_ROOT/bin/aidos.js" closure aidos-pilot-migration-hygiene` | **0** — `Closure: closable`; all 10 checks pass; the other 5 flows are listed as out of scope, not failed |
| Whitespace / conflict markers | `git diff --check` | **0** — clean |
| App source untouched | `git diff --name-only origin/main -- macos` | **empty** |
| Protected files | `git diff --quiet origin/main --` `.ai/{constraints,workflow,planner,developer,reviewer,constitution}.md` `aidos.config.json` `scripts/run-aidos.mjs` | **unchanged** for every path |
| Applied templates | `cmp` against the `--confirm-overwrite` render in the disposable copy | **match** for all 9 applied files |
| Memory | `git diff origin/main -- .ai/memory.md` | one additive note only; all existing content retained |
| Scope | `git diff --stat` | 6 modified tracked files (+70/−3) and 9 added pilot docs; no `macos/`, `.github/`, `declarations`, `dist/` or release assets |

The only baseline blocking finding is resolved by a docs-only `ADR Impact` wording correction, so
`review` moved from `Block` to `Approve`. The `trace` exit remains 1 for a current-task missing
`Feature Spec` link; this is recorded as a residual risk rather than patched with an invented link.
`closure` covers only the new pilot flow; it does not claim anything about historical flows,
application code or release readiness.

Pre-existing repository noise: an untracked root `package-lock.json` was present before the pilot
and is left untouched; it is not part of this change.

## 7. Residual risks and intentionally not done

- `contractVersion` stays 1; schema 2 config adoption and domain specs are deferred.
- Tooling is not pinned; `AIDOS_ROOT` remains a documented development override.
- `aidos trace` keeps one historical missing `Feature Spec` link (documented above).
- Legacy features/reviews remain legacy; no retro-conversion was attempted.
- No merge, push requirement, version bump, DMG, release, publication or app-source change.
