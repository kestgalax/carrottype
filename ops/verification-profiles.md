# Verification Profiles

Verification is chosen by the character of the change. A profile is guidance for the task and review; it does not replace review, maintainer acceptance, or release authorization.

## Selecting A Profile

- Choose the profile before implementation and record it in the task.
- Choose the highest-risk profile that applies. Profiles stack; a UI change that also changes trust rules needs both sets of checks.
- A manual label never turns a risky change into `docs-only`. If production behavior, UI, lifecycle, trust, or distribution changed, use the matching profile.
- Record every skipped check and its reason. "Not run" without a reason is not evidence.
- Re-run a check only for a concrete reason: the relevant source tree changed or a new risk appeared. A docs-only commit does not invalidate application evidence.

## Profiles

| Profile | Minimum checks | Evidence to record |
| --- | --- | --- |
| `docs-only` | `git diff --check`, markdown links, affected documentation checks | diff summary and documentation check result; state that app evidence is unchanged |
| `pure-logic` | unit tests for the changed logic | command, exit code, source commit or relevant tree hash |
| `native-ui` | at least one real user path on the actual component: open, start, real first responder, first input | scenario, build/source, screenshot or log, known limits |
| `lifecycle-concurrency` | teardown, cancel, quit, update gate, session ownership | scenario and observed result, including a negative case |
| `model-trust-security` | signed build, model or update trust, network sinks, secrets handling | hashes or signatures, feed/archive checks, sink list |
| `release-distribution` | build, packaging, signing, draft and public assets, feed | one evidence manifest per version |

## Profile Rules

- A model-only or mocked test (for example fake focus) is valid logic evidence. It is not proof that a real UI path works.
- A successful build and a manual acceptance are different evidence. One does not replace the other.
- A blocked external check stays blocked. Queued or skipped CI is not green, and local checks are not equivalent to full CI.
- One evidence manifest covers draft and public checks for a version. A late report edit does not create a new commit-and-CI loop unless the relevant source changed.
- A bypass of a release gate is an explicit maintainer decision with written reasons, never an automatic fallback.

## Stack Examples

The minimum checks are stack-agnostic. Replace command examples with the product's own toolchain.

- AIDOS governance runs on Node.js (`aidos validate`, `trace`, `review`), but Node.js is not the product runtime.
- `npm test` in a governance project is not native build or product acceptance evidence.
- For a Swift/Xcode or another non-Node consumer, see `ops/native-verification-examples.md` for optional Debug build, `swift test`, `codesign --verify`, artifact hash, smoke-script, and local-versus-CI examples.
- A native build job is not an AIDOS gate. If it is unavailable, record `blocked`; local checks are not equivalent to full CI.

Use the fields in `ops/evidence-manifest.md` for recorded checks.
