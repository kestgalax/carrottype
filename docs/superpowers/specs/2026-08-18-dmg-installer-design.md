# Design: Custom DMG installer window

## Traceability

- Product intent: first-run install from GitHub Releases (`README.md`, ADR-011)
- Roadmap: unsigned `.dmg` packaging polish (not notarization)
- Visual brief: `docs/research/dmg-preview/index.html`
- Layout constants: `macos/packaging/dmg/layout.sh`

## Goal

Replace the default Finder folder window with a branded drag-to-Applications screen: one English sentence, a straight arrow, the app icon, and an Applications alias.

## Decisions

- Layout grammar from Wispr Flow (instruction + two icons + arrow). Visual language from CarrotType (carrot orange, no serif).
- Copy (baked into the background PNG): `To install, drag CarrotType to Applications`. Italic only on `drag`.
- Language: English only. Finder cannot localize a background image. App UI stays RU/EN after install.
- Arrow: straight stroke + filled head. Not a hand-drawn loop.
- Arrow / accent colour: `#FE6C19` (sampled from the carrot body on the app icon).
- Background: `#F1F2EF`. Text: `#1D1D1F`.
- Type: SF Pro Display for the baked headline (same San Francisco family Finder uses for icon labels).
- Volume name: `CarrotType` (no version in the window title).
- Icon labels: Finder-drawn `CarrotType.app` and `Applications`.
- Packaging: extend `macos/scripts/build-release-dmg.sh` with RW DMG + AppleScript. No `create-dmg` / npm / extra Python packages.
- After Finder layout: `chflags hidden` on `.background`, delete `.fseventsd`, park leftover icons off-canvas. Those folders are packaging-only (wallpaper + FSEvents) and must not appear in the install window.
- No new ADR: distribution channel remains unsigned GitHub DMG (ADR-011).

## Layout (points)

- Finder window: 640 x 420 (toolbar and status bar hidden).
- Background art: 640 x 368 (icon view), shipped as `background@2x.png` (1280 x 736, 144 DPI).
- Icon size: 128.
- `CarrotType.app` centre: `{140, 200}`.
- `Applications` centre: `{500, 200}`.
- Headline: 26pt, centred, top offset 36.

## Out of scope

- Notarization / Developer ID
- Localized background variants
- Dual-language headline
