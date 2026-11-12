# Consumer Contract Guidance

This page explains what AIDOS CONTROL reports mean in a consumer project and how to adopt stricter checks without changing every existing workflow.

## Three Different Questions

| Question | Command | Scope |
| --- | --- | --- |
| Is repository structure and its markdown links intact? | `aidos validate` | `repository_structure` |
| Is the artifact structure acceptable? | `aidos review` and `aidos trace` | `artifact_structure` |
| May this one flow be closed? | `aidos closure <review-slug>` | `flow_closure` |
| May a domain spec be updated from this review? | `aidos archive <feature-slug>` | separate gate, unchanged |

A structural `Approve` is not code approval, release authorization, or flow closure. `aidos closure` answers only the flow question, and `aidos archive` keeps its own `Schema: 2` + `Outcome: Approve` + concrete evidence gate.

## Evidence Is Declared

Reports say `Evidence: Declared (not re-executed)`. AIDOS never runs `Command` lines, calls git, recomputes hashes, or verifies application behavior. Truthfulness of `Command`, `Source`, `Covers`, and `Limits` stays a human and reviewer judgment.

A minimal free-text review is valid:

```markdown
## Verification Review

- Evidence: npm test passed; manual smoke test recorded in ops/evidence-manifest.md.
```

Optional structured evidence under opt-in `contractVersion: 2`:

```markdown
- Check: npm test
  Result: pass
  Command: npm test
  Source: tests/example.test.ts
  Covers: behavior covered by this check
  Limits: local fixtures only
```

`Result` is one of `pass`, `fail`, `skip`, or `risk`. `Command`, `Source`, `Covers`, and `Limits` are optional but must be non-empty when present. Malformed shape and failing results are advisory in `aidos review`; a failing `Result` makes the flow not closable in `aidos closure`.

## Adopting `contractVersion: 2` Safely

`contractVersion` lives in `aidos.config.json` and is opt-in per project. Absent or `1` keeps legacy behavior and exit codes. `2` enables strict checks.

1. Keep the project at `1` until `aidos review` and `aidos trace` are already clean.
2. Add `"contractVersion": 2` in a reviewable change.
3. Run `aidos review` and `aidos trace` before and after; new blocking findings are expected only from the strict contract.
4. Roll back by removing the key. No artifact migration is required.
5. New projects stay at `1`; never flip a default for other consumers.

## Optional CI Use

Run `aidos closure <review-slug>` for the one flow in the pull request, not for every repository flow. Its `1` exit code means that flow is not closable, not that unrelated flows or the whole repository failed. A common pipeline stays `aidos validate`, `aidos trace`, `aidos review`, plus an optional per-flow closure step.

## Migrating A Living Consumer

Treat migration as a reviewed flow, not a drive-by edit:

1. Inventory the project's review artifacts and current `aidos.config.json`.
2. Preview the template refresh with `aidos init --update --dry-run` and `--diff`.
3. Apply only after review, and keep `.ai/memory.md` and project-owned files.
4. Stay at `contractVersion: 1` until the existing findings are understood.
5. Opt into `2` separately, then consider using `aidos closure` in CI for new flows.
6. Record the maintainer decision and the skipped checks.

No consumer is migrated by AIDOS itself.

## Related

- AIDOS `docs/multi-flow-discipline.md` — same flow, amendment, or new flow.
- AIDOS `docs/post-mvp-consumer-playbook.md` — quality gate, recommendation flips, distribution trust.
- `ops/verification-profiles.md` and `ops/evidence-manifest.md` in this project.
