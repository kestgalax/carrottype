# Review Template

## Metadata

- Review ID:
- Schema: 2
- Outcome:

`Outcome` is `Approve`, `Request Changes`, or `Block` for this change. A structural `aidos review` pass is not code approval, release authorization, or flow closure.

## Traceability Check

- Product Intent Link:
- Roadmap Item:
- Feature Spec:
- Task:
- Related ADRs:

## Governance Checklist

- Product intent respected:
- Architecture respected:
- Verification evidence present:

## ADR Impact

No ADR impact

## Verification Review

- Evidence:

Optional structured evidence (replace the free-text `Evidence:` line when useful):

```markdown
- Check: npm test
  Result: pass
  Command: npm test
  Source: tests/example.test.ts
  Covers: behavior covered by this check
  Limits: local fixtures only
```

`Result` is one of `pass`, `fail`, `skip`, or `risk`. `Command`, `Source`, `Covers`, and `Limits` are optional but must be non-empty when present. Evidence is declared, not re-executed: AIDOS never runs these commands. A failing `Result` makes this flow not closable; malformed structured blocks are advisory in `aidos review`.

Use structural `aidos review` for repository-wide artifact checks and `aidos closure <review-slug>` for one flow. `contractVersion: 2` is an explicit per-project opt-in, never a new-project default. See `docs/consumer-contract-guidance.md`.
