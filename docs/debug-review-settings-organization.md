# Debug review — Settings organization (General / Dictation / Text actions)

2026-11-12. Implementation-only review for Codex. No version bump, DMG, merge, push or
publication is authorized or performed by this delivery. Version/build remains **0.10.0 (34)**.

## Scope and source

- Approved design: `docs/specs/tasks/settings-organization.md`, copied from the authoritative
  `design/settings-organization` commits `5443d07`, `93b76cd`, `d4583d4` with approval and
  alternatives retained.
- Dependency satisfied: typing-speed test integrated and 0.10.0 published from `origin/main`
  `22536e7` (PR #31 merge `bd387d8`).
- Fresh main-based branch/worktree: `kestgalax/settings-organization`.
- Roles: Codex design/review; OpenCode 2 implementation under the maintainer’s latest instruction
  «давай тогда через opencode продолжим». Direct ZCode readiness failed and is not claimed.
- This is view extraction/navigation only. It is not release or publication authorization.

## Navigation mapping

| # | Pane | Content after the change |
|---|------|--------------------------|
| 1 | **General / Основные** | App updates, theme, language, launch at macOS sign-in as the final section |
| 2 | **Dictation / Диктовка** | Existing dictation hotkey/PTT/clipboard; then the existing Ready-only formatting selector, exact rules, model preferences/My Rules and text trial |
| 3 | **Text actions / Преобразования** | Existing Translate/Custom bindings (max 5, disclosure, add/delete, language/model/instruction, conflicts, saved empty array) |
| 4 | **Dynamic Island** | Existing modes, live-draft switch and preview; name remains untranslated in RU/EN |
| 5 | **Setup / Настройка** | Existing readiness, permissions, microphone/meter, Wave Link and introductory trial |
| 6 | **Models / Модели** | Existing packages, downloads and Ready-only formatting selection |
| 7 | **Storage / Хранилище** | Existing installed packages, legacy models and download cache |
| 8 | **Statistics / Статистика** | Existing statistics/WPM and the unchanged 0.10.0 **Measure…** typing test |

The 200 pt sidebar, 720×520 window minimum and General-if-ready/Setup-if-not-ready default are
unchanged. First-run still continues to Setup; no new pane is auto-selected. Only the destination
list may scroll; Details, version and What’s New stay pinned.

## Before/after control inventory

| Existing control/value | Before | After | Preserved behavior |
|---|---|---|---|
| Dictation hotkey capture/reset/conflict | General | Dictation | Same `HotkeyService`, `isRecording`/`captureTarget`, registration restore |
| Walkie-talkie PTT | General | Dictation | Same key/value and hold semantics |
| Keep result in clipboard | General | Dictation | Same key/value and paste/restore semantics |
| Formatting mode picker | General | Dictation | Same `ModelManager.selectCleanup`/`selectableCleanupModes`, Ready-only |
| Open Models link | General | Dictation and Text actions | Navigation only; no download |
| Exact rules (words, lowercase, first letter, final period) | General | Dictation | Same `DictationRules`, normalized/persisted values, Off/Light/model/fallback path |
| Model preferences (fillers, repetitions, self-corrections, paragraphs) | General | Dictation | Same saved fields and prompt purpose |
| My Rules editor/examples/limit/summary/reset | General | Dictation | Same fields, 1000-character limit and reset |
| Experimental business tone | General | Dictation | Still labelled, off by default; no quality claim added |
| Formatting text trial (input/Run/Cancel/result/actual mode/fallback) | General | Dictation | Same task, RAM-only, install gate and awaited teardown |
| Transform bindings list | General | Text actions | Same array/key, max 5, disclosure, add/delete, conflict behavior |
| Binding kind/model/language/instruction editor | General | Text actions | Same independent resolution and validation |
| Saved empty binding array | General | Text actions | Still empty after relaunch; defaults not resurrected |
| App updates/version/What’s New | General | General | Same `AppUpdateService` and Sparkle KVO bindings |
| Theme and language | General | General | Same keys; no Settings remount |
| Launch at login | General (last) | General (last) | Same native `SMAppService` toggle/status |
| Dynamic Island controls | Dynamic Island | Dynamic Island | Unchanged |
| Setup microphone/Wave Link/permissions | Setup | Setup | Unchanged; not duplicated on Dictation |
| Models/Storage/Statistics and typing test | Existing panes | Existing panes | Unchanged; typing test remains Statistics-only |

## Implementation notes

- Added `DictationSettingsPane.swift` and `TextActionsSettingsPane.swift`; General now contains only
  application preferences. The formatting selector is a private extraction that still uses the
  common `ModelManager`. Transform binding editing moved without a second preference copy.
- `CarrotTypeSettingsView` renders the eight destinations and scrolls only the navigation list.
  Sidebar rows keep their focus ring, selected trait and accessibility identifiers.
- Leaving Dictation/Text actions cancels chord capture and restores registration. This tests
  `HotkeyService.isRecording` capture, not an active dictation session.
- Leaving Dictation cancels an in-flight text trial through the existing task/gate teardown.
  Theme/language updates do not remount the shell and do not cancel a finished trial.
- No runtime, engine, model, prompt, helper protocol, dictation/transform, statistics, updater,
  trust, network, dependency, defaults, history or release-asset change.

## Verification

Commands run locally with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`:

| Check | Result |
|---|---|
| `bash scripts/verify-setup-formatting.sh` | PASS |
| `bash scripts/verify-formatting-rules.sh` | PASS |
| `bash scripts/verify-launch-at-login.sh` | PASS |
| `bash scripts/verify-typing-speed-test.sh` | PASS |
| `python3 scripts/verify-settings-organization-app.py --build-log /tmp/settings-org-final-debug.log --products macos/.derivedData-settings-organization-final/Build/Products/Debug` | PASS |
| `python3 scripts/verify-typing-speed-app.py --build-log /tmp/settings-org-final-debug.log --products macos/.derivedData-settings-organization-final/Build/Products/Debug` | PASS, including the real mounted Start/focus regression |
| `python3 scripts/verify-formatting-app.py --build-log /tmp/settings-org-final-debug.log` | PASS |
| `python3 scripts/verify-dynamic-island-app.py --build-log /tmp/settings-org-final-debug.log` | PASS |
| `bash scripts/verify-session-lifecycle.sh`, `verify-dictation-reliability.sh`, `verify-ultra-models.sh`, `verify-app-updates.sh`, `verify-release-notes.sh` | PASS |
| `python3 scripts/verify-model-catalog-streaming.py`, `scripts/verify-brand.py` | PASS |
| Local AIDOS validate / trace / review | PASS (review Outcome: Approve) |
| Clean arm64 Debug build | BUILD SUCCEEDED |

The new app check covers the actual `AppState`, pane unmount, real `HotkeyService`, real
`UpdateInstallationGate`/trial teardown and a unique defaults domain. It proves: eight ordered
destinations and RU/EN copy; all saved values survive navigating every pane; max-five/empty
bindings; dictation and transform capture cancel on pane departure; theme/language do not cancel
a finished trial; leaving Dictation cancels a running trial and releases the gate; and every pane
renders at 720×520.

Typing-test scope check: `TypingSpeedTestSheet` and `typingtest.measure` are referenced only by
`StatisticsSettingsPane.swift` (plus the sheet definition). The real mounted Start/focus regression
in `verify-typing-speed-app.py` passes on the final build.

## Native visual evidence

Offscreen native snapshots of the actual shared `CarrotTypeSettingsView` at **720×520**:

`dist/.builds.noindex/Settings-Organization-Native-Review/native`

They cover all eight panes × RU/EN × light/dark (32 states), plus a scrolled Dictation bottom
(`settings-dictation-ru-light-bottom.png`). Sidebar/footer content is present in every state; the
sidebar itself fits without scrolling at this minimum, and Dictation content scrolls while the
footer stays pinned. Additional real-view evidence from the existing suites remains under
`.../dynamic-island/native` and `.../typing-speed/native`.

## Signed Debug app

- Path:
  `/Users/kestgalax/orca/workspaces/carrottype/settings-organization/dist/.builds.noindex/Settings-Organization-Debug-2026-11-12/CarrotType.app`
- Bundle: `app.carrottype.macos`; version **0.10.0 (34)**; arm64 Debug.
- Identity: `CarrotType Development` (self-signed development identity; not notarized).
- `codesign --verify --deep --strict`: valid on disk, satisfies its Designated Requirement.
- CDHash: `988c0d961845b2359bf0a4060cc2d78799e3d3ce`
- Executable SHA-256:
  `bdbcfe75af6ed9f333af3a639378d9b670f17f2e0554afc3a233ff1c0f72e5df`
- `CarrotType.debug.dylib` SHA-256:
  `cfd79d091e62bc2323f18b14cdc5237f7f1b07aec8b4d2cbbc7324ddee722d3f`
- Cleanup helper: arm64, deep-strict signature verified.
- App size on disk: 122 MB. No DMG/ZIP/appcast/release was produced.
- Prior Debug builds, the installed/user app, preferences, models, login items and published
  release assets were not replaced. The app was not launched, so no new TCC prompt was triggered.

## Commits

- Approval/spec history: `5443d07`, `93b76cd`, `d4583d4` (preserved, not rewritten).
- Base: `origin/main` `22536e7`.
- Application/source implementation commit: `IMPLEMENTATION_COMMIT_PLACEHOLDER`.
- Final evidence/docs commit: this document’s commit (see `git log -1`).

## Honest limitations / manual checks remaining

- The native images are offscreen renderings of real views, not a live interactive window,
  physical display/notch or device screenshot.
- Keyboard focus traversal and VoiceOver announcements were checked at source/accessibility-
  semantics level (focus state, selected trait, labels/identifiers); they were not exercised with
  a real VoiceOver session. TCC prompts, real microphone/Wave Link/device behavior and actual
  cross-app dictation/transform were not run.
- The pane-departure trial check used the existing Light/no-model path to exercise the real task and
  gate; an actual MLX helper teardown was covered by the existing formatting-app fakes and
  cancellation checks, not a newly downloaded model run.
- No performance improvement is claimed or measured; this is a UI extraction/reorganization.
- Self-signed Debug still requires the project’s normal Debug handling; this is not a notarized or
  public release. Codex review and a separate manual/publication gate remain.
