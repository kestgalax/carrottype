---
name: carrottype-release-motion
description: >-
  Produces CarrotType silent release companion MP4s with private Motion OS and
  attaches them as GitHub Release assets. Use when preparing a GitHub Release,
  publication package, draft release assets, github-release-notes, or when the
  maintainer asks for a demo/film for a version with visible UI changes.
---

# CarrotType release motion

Shared project skill (canonical path: `.agents/skills/carrottype-release-motion/`). Cursor/Claude entrypoints are symlinks to this folder.

## Authority

Follow **`ops/release-motion.md`** (when required + locked filename/format) and **`ops/motion-tooling.md`** (`MOTION_OS_ROOT` pin). Do not invent a parallel process.

## Steps

1. Decide Yes / N/A / waiver per `ops/release-motion.md`.
2. If Yes: set `MOTION_OS_ROOT`, write/update `motion/briefs/<slug>.md`, run:
   - `npm run motion -- run motion/briefs/<slug>.md --no-capture`
   - `npm run motion -- check motion/out/<slug>.mp4`
3. Rename to `CarrotType-{version}-{slug}-demo.mp4` under `dist/` for upload.
4. Attach to the GitHub Release; add **Демо** link (+ optional SHA) in `docs/github-release-notes-v{version}.md`.
5. Never commit mp4s to `main`; never add `motion-os` as an npm dependency.

## House rules

Silent H.264, ≤60 s (target 15–30), 1920×1080, effect clicks only (no cursor).

## Visual fidelity (required for Settings / sheet films)

Remotion skins that show **Settings, Form, sheet, or Capsule chrome** must track **shipped SwiftUI**, not design mockups or generic System Settings.

Source of truth (read before painting chrome):

- `macos/CarrotType/Views/AppStyle.swift` — `controlAccent` / dark accent, sidebar width
- `macos/CarrotType/Views/CarrotTypeSettingsView.swift` — sidebar brand, SF Symbol rows, warm selection fill, pane heading + subtitle
- The concrete pane/sheet for the hero change (e.g. `DictationSettingsPane`, `MicrophonePrioritySheet`)

Hard rules:

1. **Carrot tint, not system blue.** Selection, toggles-on, default/Done actions, and active-row accents use `AppStyle` carrot family (`#A3471E` / dark `#FFB589`). Do not use `#0A84FF` / `#2F6BE8` for product chrome.
2. **Sidebar brand.** CarrotMark + «CarrotType», Label+symbol rows, selected = warm fill ≈14% opacity — not a solid blue pill with text-only items.
3. **Pane chrome.** Title + subtitle from `settings.description.*`; Form sections match real copy where the hero is visible (hints under toggles when they appear on screen).
4. **Sheets.** Match the shipped sheet layout (header Done vs footer CTA, list reorder affordance, status Labels). Prefer `List.onMove` grabber language over mockup chevrons.
5. **Copy.** Prefer `Localizable.xcstrings` (RU) for on-screen strings shown in the film.
6. **Audit before ship.** After render, spot-check frames against the Debug app or SwiftUI sources. Format `check` PASS alone is not fidelity PASS.
7. Mockups under `docs/mockups/` are **storyboards only** — layout/beat ideas, not final color or chrome.

Effect-click rings may use the warmer stage accent (`#F0873C`) as long as they stay in the carrot family.

## End-card / establish copy

On-screen titles and disclaimers are for **people using CarrotType**, not engineers:

- Prefer clear Russian (or the film’s UI locale); avoid EN jargon (`failover`, `drag reorder`, `Dictation` when the UI says «Диктовка»).
- Brand mark on cards: shipped **CarrotMark** + «CarrotType», not a generic orange dot + lowercase wordmark.
- Keep version hints soft («Новое в CarrotType 0.12»), not changelog slang.

## Live UI capture (when maintainer asks for «живой» / 1:1)

Remotion skins approximate chrome. If the maintainer wants **pixel-real** Settings/sheet:

1. Use a working **Debug** `.app` (adhoc Xcode product is fine; avoid broken Development resign of `CarrotType.debug.dylib`).
2. Drive the real UI (AX / `orca computer`) through the hero path; Screen Recording required.
3. Capture the Settings window (ffmpeg `avfoundation` Capture screen → crop window bounds × scale factor).
4. Export silent H.264 1920×1080 ≤60 s. **No cursor** (hide system cursor; do not use screencapture `-C` / ffmpeg `capture_cursor`). House rule still applies: **effect clicks only**.
5. Prefer window-only capture (`screencapture -l <windowid> -v`). Do drag/reorder **off-camera** (or via menu promote) and cut between before/after; overlay carrot effect rings on «Настроить…» / «Готово». Keep Remotion establish/endcard wrap.
6. Prefer live over Remotion for that release asset; keep Remotion as fallback if capture/TCC blocks.

Motion OS `macos-ax` adapter is still a stub — do not wait on `capture: required`.
