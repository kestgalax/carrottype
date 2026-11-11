# Dynamic Island settings — implementation review evidence

Date: 2026-11-11. Status: **Codex review passed; ready for maintainer Debug evaluation**; no version
assignment, publication, tag, feed, DMG or installed-app replacement.

## Scope and branch

- Orca worktree: `/Users/kestgalax/orca/workspaces/carrottype/dynamic-island-implementation`
- Branch: `kestgalax/dynamic-island-implementation`, created from main `d0a4058`
- Authoritative spec: cherry-picked `0b3e27c` (`docs/specs/tasks/dynamic-island-settings.md`)
- Implementation commit: `8134189`; review fixes R1–R3 in `0908750`; evidence follow-ups `7d369fd`, `cef8469` and later docs commits. Application code is at `0908750`.
- The prior OpenCode planning branch and competing proposal were not used.

## Implemented behavior

- New Settings pane **Dynamic Island** immediately after General; full capsule is the
  default and absent/invalid `carrottype.dynamicIslandMode` values resolve to it.
- Moved **Show text while you speak** into the pane with the exact
  `carrottype.liveDraftEnabled` key/value. It remains visible but disabled outside Full;
  returning to Full restores the saved choice.
- Mode and effective preview (`full && saved switch && captured streaming support`) are
  captured at dictation start. Minimal and menu-bar-only sessions invoke **zero** preview
  starts and offer no Escape draft Copy; normal stop still uses the session WAV → STT →
  formatting → paste path.
- One `DynamicIslandPolicy` governs attach/sync/show/position, screen changes, theme/locale
  updates and delayed sequences. Logical phases are preserved when the panel is hidden.
- Minimal indicator: thin recording glow below the notch (compact top-center indicator
  without a notch) and three processing dots. Shapes and color distinguish states, Reduce
  Motion disables pulsing, Increase Contrast keeps borders, and the panel stays
  nonactivating/click-through.
- Transform processing/results and paste-failure recovery keep full Copy/Close chrome in
  every mode. `.understanding` carries its owning operation.
- When the status panel is suppressed, the menu shows a short Light-fallback warning based
  on the existing RAM last-result outcome/captured last-session mode; Details keeps the
  detailed outcome.
- The Settings preview follows the selected mode and uses the real shared visual components:
  full capsule for Full (with synthetic live-draft text when the saved switch and streaming
  support allow it), the shared minimal indicator for Minimal, and shared menu-bar status
  glyphs for Menu-only. It does not capture audio, start models, write WAVs, touch the
  clipboard/statistics or open the real overlay.
- The pane title and sidebar name are **Dynamic Island** in both RU and EN. Mode choices are
  a vertical localized radio-style list that fits the real detail column at the 720×520
  minimum window size.
- No engine/runtime/dependency/network/catalog/model/history change; no version bump.

## Key files

- `macos/CarrotType/Models/DynamicIslandMode.swift` — mode, policy, metrics, moved phase.
- `macos/CarrotType/AppState.swift` — preference capture, operation owner, presentation,
  fallback warning, test seams.
- `macos/CarrotType/Views/StatusCapsule.swift` — single presentation controller/root.
- `macos/CarrotType/Views/DynamicIslandIndicators.swift` — shared glow/dots/minimal view.
- `macos/CarrotType/Views/Settings/DynamicIslandSettingsPane.swift` — pane and preview.
- `macos/CarrotType/Views/Settings/SettingsPane.swift`, `CarrotTypeSettingsView.swift`.
- `macos/CarrotType/Views/Settings/GeneralSettingsPane.swift` — live-draft switch removed.
- `macos/CarrotType/Views/MenuBarViews.swift` — shared menu-bar status appearance and
  suppressed-panel fallback warning.
- `CarrotTypeSettingsView(initialPane:)` — fixture-only initial pane; runtime default is nil.
- `docs/decisions/ADR-014-live-dictation-streaming.md` — amendment.
- `docs/architecture.md`, `docs/specs/ux-setup-status.md`,
  `docs/specs/features/live-dictation-streaming.md`, `docs/product-intent.md`, `README.md`,
  `docs/roadmap.md`, `.ai/memory.md`.

## Verification run

All commands were run locally on 2026-11-11. Nonzero results are not claimed as success.

| Check | Command | Result |
|---|---|---|
| Pure policy/preference | `bash scripts/verify-dynamic-island.sh` | PASS: defaults, effective preview, mode matrix, result exception, fallback, metrics |
| Actual AppState/coordinator with fake adapters | `python3 scripts/verify-dynamic-island-app.py --build-log /tmp/ct-build-final-r1r3.log` | PASS: mode capture, zero preview starts, Escape empty/nonempty draft, transform/recovery, stale sequence, screen changes, fallback; whole-shell 720×520 layouts and bottom-scroll certificate |
| Lifecycle | `bash scripts/verify-session-lifecycle.sh` | PASS: coordinator/gate/preview races, cancellation, stale callbacks, cleanup |
| Setup/formatting | `bash scripts/verify-setup-formatting.sh` | PASS: readiness/trial/bindings/hotkeys/clipboard/selection/helper |
| Reliability | `bash scripts/verify-dictation-reliability.sh` | PASS: clipboard restore, selection fallback, helper transport |
| Catalog | `python3 scripts/verify-model-catalog-streaming.py` | PASS: catalog v12, Ultra streaming flag |
| Ultra migration/storage | `bash scripts/verify-ultra-models.sh` | PASS |
| Launch at login | `bash scripts/verify-launch-at-login.sh` | PASS |
| Release notes | `bash scripts/verify-release-notes.sh` | PASS |
| Governance validate/trace/review | `AIDOS_ROOT=/Users/kestgalax/Projects/2026/AIDOS npm run aidos:validate` / `:trace` / `:review` | PASS / no missing links / Approve |
| Debug build | `xcodebuild … -configuration Debug -destination 'platform=macOS,arch=arm64' … clean build` | **BUILD SUCCEEDED**, arm64 |
| `git diff --check` | `git diff --check` | PASS |

Build log: `/tmp/ct-build-final-r1r3.log` (31 SwiftDriver compile invocations, `BUILD SUCCEEDED`).

The actual AppState check uses the real coordinator with fake capture/mute/preview/process/
unload dependencies in a disposable staging bundle. It asserts the absence of preview calls,
not merely empty preview text, and exercises mid-session mode/switch changes, delayed old
success UI vs a newer session, screen-change suppression, transform/recovery visibility and
captured last-session fallback. It does not touch the real pasteboard, Last Dictation or
statistics; no microphone/model/WAV path is used.

## Native visual evidence

Offscreen native SwiftUI renders are under:

`dist/.builds.noindex/Dynamic-Island-Native-Review-R1R3/native/`

The primary evidence is the **actual whole Settings shell** at the documented 720×520 minimum
window size, with **Dynamic Island selected**. The 200 pt sidebar leaves about 519 pt for the
real detail pane. Rendering covers RU/EN × Light/Dark × Full/Minimal/Menu-only:

- `settings-ru-light-full.png`, `settings-ru-dark-full.png`, `settings-en-light-full.png`,
  `settings-en-dark-full.png`.
- `settings-ru-light-minimal.png`, `settings-ru-dark-minimal.png`,
  `settings-en-light-minimal.png`, `settings-en-dark-minimal.png`.
- `settings-ru-light-menuOnly.png`, `settings-ru-dark-menuOnly.png`,
  `settings-en-light-menuOnly.png`, `settings-en-dark-menuOnly.png`.
- `settings-ru-light-full-bottom.png` — the same minimum-size shell scrolled to the bottom;
  this proves the longer content remains reachable by scrolling without enlarging the window.

The pane contains a vertical mode selector (no horizontal radio-group truncation), and the
preview changes with the selected mode: shared full capsule, shared minimal indicator, or
shared menu-bar glyphs. Captured vertical overflows at minimum size were 11.5–100.5 pt
depending on mode/language; the bottom-scroll render asserts the Form scroll offset moved.
The mode name is **Dynamic Island** in RU and EN.

Additional real-component geometry renders:

- `minimal-recording-native-geometry.png` — actual notched geometry (185×32 pt notch,
  101.75 pt bar) on a synthetic background.
- `minimal-processing-non-notch.png` — 48×10 pt compact processing indicator.

Captured geometry printed by the check: `notched=true notch=185.0x32.0 bar=101.75`.

These are offscreen renders, not screenshots of a live device, external display, fullscreen
space or VoiceOver session.

## Signed Debug artifact

- Path: `/Users/kestgalax/orca/workspaces/carrottype/dynamic-island-implementation/dist/.builds.noindex/Dynamic-Island-Debug-R1R3-2026-11-11/CarrotType.app`
- Bundle: `app.carrottype.macos`, version `0.8.2` build `32` (unchanged; no version bump)
- Architecture: arm64, thin
- Signature: `CarrotType Development`; `codesign --verify --deep --strict` passes,
  designated requirement satisfied
- Main executable SHA-256: `5118fb744c9004f10fb6be982effae373302471902e7358cda399bb08646079e`
- No bundled model weights were found in the app.

The app was not launched with the real production identity/preferences, not installed over an
existing copy and not used to start microphone capture. The prior `Dynamic-Island-Debug-2026-11-11`
copy and other older Debug copies were not replaced.

## Limitations and open risks

- Offscreen RU/EN light/dark/minimum layouts are not interactive acceptance. Real notch,
  external display, fullscreen spaces, VoiceOver, actual AppKit panel behavior on all display
  configurations and a menu bar that auto-hides remain manual checks.
- Minimal-indicator dimensions (3 pt bar, 4–6 pt notch protrusion, 48×10 pt non-notch panel)
  are prototype judgments within the approved spec and should be visually assessed on a
  signed Debug build.
- Menu-bar-only discoverability is intentionally limited when the system auto-hides menu bar;
  the pane explains this.
- The fallback warning is a short menu line from RAM and is not a new notification/history.
- No manual Debug acceptance or publication authorization is claimed. [Codex review](specs/reviews/dynamic-island-settings.md) passed after R1–R3; maintainer Debug evaluation is next.
- R2 layout evidence is an offscreen 720×520 whole-shell render with a programmatic
  scroll-to-bottom check; it is not an interactive window-resizing test.
