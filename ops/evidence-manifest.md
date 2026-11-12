# Evidence Manifest

One manifest records the checks for a change set or release version. It is evidence, not approval: a passing manifest does not authorize merge, publication, or closure by itself.

## Fields

| Field | Meaning |
| --- | --- |
| Check ID | Stable short identifier, for example `build-macos`, `unit-core`, `ui-first-input` |
| Profile | `docs-only`, `pure-logic`, `native-ui`, `lifecycle-concurrency`, `model-trust-security`, or `release-distribution` |
| Procedure | Exact command, or a short manual scenario with steps |
| Source | Source commit or relevant tree hash; scope it to the area the check covers |
| Environment | OS, runtime, device, and build variant |
| Result | `pass`, `fail`, `blocked`, or `skipped` with a reason |
| Artifact | Path or link to the log, screenshot, report, or hash |
| Scenario | Behavior or requirement covered |
| Limits | What the check does not prove and which checks were skipped |

## Manifest Template

```markdown
# Evidence Manifest — <version or change>

- Version or change:
- Source commit:
- Relevant tree hash:
- Date and timezone:
- Environment:
- Owner:

| Check ID | Profile | Procedure | Source | Environment | Result | Artifact | Scenario | Limits |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
|  |  |  |  |  |  |  |  |  |
```

## Rules

- Use one manifest for draft and public release checks. Link it from the canonical `Current Status` block in `docs/roadmap.md`.
- Scope the source hash to the area the check covers. A docs-only commit does not invalidate application checks; a change to a production input view invalidates the related UI check.
- Build success, automated tests, and manual acceptance are separate evidence. Do not substitute one for another.
- Record `blocked` for an unavailable external check. Queued is not green. Continue independent work and state the blocker.
- Do not create a loop where a new report commit triggers new CI, whose number is then added to the report. Update the report only when the relevant source changes.
- Keep the manifest portable markdown. It does not require a hosted service, database, or orchestration runtime.
