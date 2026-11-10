# CI Governance

This project uses AIDOS governance checks through the cloned AIDOS tooling repository.

## Prerequisites

- `AIDOS_ROOT` points to the cloned AIDOS repository, or `aidos.config.json` sets `toolingRoot`.
- Node.js is available in the CI environment.

## Minimum Pipeline

1. `npm run aidos:validate`
2. `npm run aidos:trace`
3. `npm run aidos:review`

## macOS build

When a CI macOS runner with full Xcode is available:

```bash
cd macos
xcodegen generate
xcodebuild -project CarrotType.xcodeproj -scheme CarrotType -configuration Debug build
```

Native builds are now verified locally and by the workflow below. Governance markdown checks remain required locally; hosted private-tooling availability is described below.

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

### Ultra catalog and legacy storage checks (macOS)

```bash
bash scripts/verify-ultra-models.sh
python3 scripts/verify-model-catalog-streaming.py
```

Compiles production catalog/default-selection/legacy-storage code with temporary UserDefaults suites and model directory fixtures. Covers catalog/fallback consistency, retired/default/unknown preference migration, preserved cleanup choices, legacy inventory, grouped optional deletion and path/symlink safety. Never deletes installed user models.

## 0.6.2 production lifecycle checks and Actions

`.github/workflows/macos.yml` now runs governance, actual production lifecycle/preview/port-order and existing reliability/setup/Ultra/update/notes/catalog regressions, followed by unsigned arm64 Debug compilation. No microphone permission, models, distribution identity, Keychain export or publication is used. `actions/checkout` and AIDOS are pinned to commits; permissions are contents-read and credentials are not persisted. GitHub's [official runner matrix](https://github.com/actions/runner-images#available-images), checked 2026-11-10, lists `xcode-27`; this is selected because the resolved MLX manifest requires Swift 6.3 with experimentalCGen. Runner-selected `DEVELOPER_DIR` is passed to scripts. The Metal component is downloaded only on the disposable CI runner if absent. Local Debug still requires full Xcode/Metal.

```bash
bash scripts/verify-session-lifecycle.sh
```

Compiles the actual coordinator and installation gate with controlled delayed adapters (no real audio/models). Covers queued PTT cancel, unmute/preview ordering, snapshot, duplicate stop/cancel, cancelled successful results, start/stop/process errors, stale callbacks, temp WAV deletion, maintenance/deletion/install/quit barriers and awaited final unload. It also compiles the existing sanitation/port-order checks against `LiveDraftText.swift`/`WaveLinkPortOrder.swift`; the `.swift` test files are no longer standalone mirrored implementations. Run through the shell harness above.

Full real-device capture/permission continuity, model inference and Wave Link mute/quit smoke remain manual Debug acceptance. Hosted CI success does not authorize release; local signed Debug delivery/manual approval remains mandatory for each version.

The same lifecycle harness additionally compiles **the actual** `ParakeetStreamingEngine` and recorder fanout against a disposable test-only FluidAudio module. It pauses a real actor preview pass at the SDK boundary, observes its cancellation, verifies join-before-cleanup/no late result and checks that a retained old audio handler cannot feed a new epoch. No model files or microphone are used; real CoreML performance and hardware behavior remain manual checks.

### Private AIDOS access

AIDOS is private (verified 2026-11-10); the first hosted run failed at its checkout before tests. The app regression/build steps now run independently. Hosted governance runs only when the maintainer provisions a narrowly scoped `AIDOS_READ_TOKEN` Actions secret with read access to that repository; credentials are not persisted. Without it the workflow emits an explicit warning and skips only AIDOS checkout/governance, so a green app build does not imply hosted governance passed. Local validate/trace/review evidence remains required. Never put a personal broad-scope token in workflow code or publish/copy private tooling to make CI pass. The first 0.6.2 tag preserves the original workflow; the PR contains this CI-only correction without changing the accepted/built app source.

Hosted app verification passed on commit `0e69d52`: [run 42815581126](https://github.com/kestgalax/carrottype/actions/runs/42815581126), production regression suite and unsigned Debug arm64 build. AIDOS checkout/governance were explicitly skipped because no private-tooling secret was configured; local validate/trace/review passed. Release closeout edits after that run change documentation only and do not change the tested app or workflow.

`python3 scripts/verify-brand.py` validates actual PNG slot sizes, editable icon/menu geometry consistency and template metadata. Native compilation checks the asset catalog. It does not measure logo usability or replace light/dark/small-size visual review.
