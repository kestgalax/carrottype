# Agent And Release Lifecycle

A portable coordination protocol for agents and releases. It is markdown guidance only; it does not require a runtime, orchestrator, or hosted service. Any runtime integration needs an ADR before implementation.

## Agent States

| State | Meaning | Evidence |
| --- | --- | --- |
| `opened` | A workspace or terminal exists | workspace or session ID |
| `input accepted` | The task was delivered and accepted with repository, base, and scope | handoff with acknowledgement |
| `turn observed` | A meaningful action or artifact exists | diff, command, or message |
| `completed` | The result and evidence are ready | report, checks, review |
| `released` | Own sessions and processes are closed; user kept-open sessions are untouched | cleanup note |

`blocked` is an orthogonal state, not a stage on this list.

Rules:

- An open terminal does not mean `working` and does not prove that work started.
- Do not report `working` only because a window or session opened.
- A handoff records: repository, worktree, branch and base, agent and model, task ID, owner, authorized actions, stop conditions, and evidence that the input was accepted.
- A new launcher or model first passes a small capability smoke check: delivery, reply, report, and completion. Child workspace support and supervised process ownership are separate checks.
- On an external service blocker: make one status/result request, report the blocker clearly, continue independent work, and retry a bounded number of times. Do not use endless sleep or watch loops, and do not present queued work as started.
- Completion checks only the agent's own remaining sessions and setup shells. Keep user kept-open sessions and worktrees.
- Tool-specific commands (for example an IDE orchestration CLI) are optional examples. They do not belong in the project's core workflow.

## Release Stages

1. Implementation approved.
2. Debug or diagnostic build delivered.
3. Maintainer accepted.
4. Publication authorized.
5. Draft verified.
6. Published.
7. Public verified.

Rules:

- Maintainer authorization is tied to a specific version and action. It does not carry over to the next release.
- Record the application source, version metadata, tag, and final verified head.
- Use one evidence manifest for draft and public checks. A later report correction does not restart the full check cycle unless the relevant source changed.
- If CI is docs-only or not required for the change, document that policy so required checks do not stay pending forever.
- An external CI outage is recorded as `blocked`. Independent preparation may continue. Do not claim that local checks are equivalent to the full CI suite.
- Bypassing a release gate is an explicit maintainer decision with written reasons, never an automatic fallback.
- Distinguish "build succeeded" from "release verified". Publication is not complete until the public asset and feed are checked.

After the first MVP or release, continue with `docs/post-mvp-consumer-playbook.md` in the AIDOS clone: quality and feedback gate, experimental-to-recommended flips, optional signing/notarization guidance, and the spike backlog.

Use `ops/verification-profiles.md` for the checks and `ops/evidence-manifest.md` for the record.
