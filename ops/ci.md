# CI Governance

This project uses AIDOS governance checks through the cloned AIDOS tooling repository.

## Prerequisites

- `AIDOS_ROOT` points to the cloned AIDOS repository, or `aidos.config.json` sets `toolingRoot`.
- Node.js is available in the CI environment.

## Minimum Pipeline

1. `npm run aidos:validate`
2. `npm run aidos:trace`
3. `npm run aidos:review`

## macOS build (optional / later)

When a CI macOS runner with full Xcode is available:

```bash
cd macos
xcodegen generate
xcodebuild -project CarrotType.xcodeproj -scheme CarrotType -configuration Debug build
```

Until then, governance markdown checks are the required gate; native build is verified locally by developers with Xcode.

## Local Pre-Commit Option

Run the same AIDOS commands before opening a pull request.

### Dictation reliability regression checks (macOS)

```bash
bash scripts/verify-dictation-reliability.sh
```

Compiles production clipboard snapshot, selection fallback, helper transport and protocol code into a temporary harness. Uses named pasteboards (never the general clipboard) and disposable fake helper children. Covers empty/rich/multi-item restore, newer external copy, no-selection/cancel cleanup, concurrent stdout/stderr, output limits, early helper exit/SIGPIPE, timeout escalation, cancellation/reaping, and malformed/versioned responses. No model download or microphone permission is needed.

Every release candidate must also have a successful Debug build delivered to the maintainer for manual testing and explicit confirmation before publishing. Automated checks do not replace that gate.

## Platform Examples

See `docs/ci-governance.md` in the AIDOS tooling repository for GitHub Actions, GitLab CI, and generic shell examples.
