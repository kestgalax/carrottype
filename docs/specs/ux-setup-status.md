# UX Spec: Setup Status (Models + Permissions)

## Traceability

- Product Intent: `docs/product-intent.md`
- Related ADRs: `docs/decisions/ADR-002-runtime-stack.md`, `docs/decisions/ADR-003-model-catalog-and-cleanup.md`
- Feature: `docs/specs/features/hotkey-carrottype-caret-paste.md`
- Design: `docs/superpowers/specs/2026-07-23-settings-sidebar-design.md`

## Goal

One clear Setup / Status surface so the user always knows:

1. whether carrottype is Ready;
2. which models are downloaded / active;
3. what is still missing (permissions or downloads).

## Entry points

- Menu bar icon → **Settings…** / **Настройки…** (opens SwiftUI `Settings` scene)
- Keyboard: **⌘,** when the app is active
- First launch → same Settings window opens automatically (`showFirstRun`)

## Ready rules

| State | Condition |
|-------|-----------|
| **Ready** | Microphone granted **and** Accessibility granted **and** active STT model `Ready` |
| **Almost** | Some requirements missing (show remaining checklist) |
| **Blocked** | Hard failure (download corrupt, unsupported Mac, etc.) |

Post-dictation formatting is **not** required for Ready. Hotkey must be set (ship a default).

## Localization

- String Catalog `Localizable.xcstrings` with **ru** and **en**.
- Default follows the system locale (`ru*` → Russian, otherwise English).
- Settings → **General** → **Language** picker: System / Russian / English (overrides without reinstall).

## Screen layout (Apple HIG / Tahoe)

Use native **`Settings` scene** with a fixed-width sidebar + detail (`HStack`, not `NavigationSplitView` — avoids the blue column focus ring and collapse control):

```text
HStack {
  Status header + pane buttons (fixed ~200pt)
  Divider
  Form { … }.formStyle(.grouped)
}
```

Window title: **carrottype**. Default size ~880×680 (min 720×520); window is resizable and zoomable (AppKit chrome re-applies `.resizable`). No sidebar focus ring. No custom Liquid Glass / `NSVisualEffectView`. System controls pick up Tahoe appearance when built with a current Xcode SDK.

### Sidebar

- **Status header** (not a pane): Ready / Almost / Blocked + version (`vX.Y.Z`). When Almost/Blocked, **Details…** opens the Status checklist in the detail column (deep-links to Setup / Models). When Ready, no Details link.
- **Panes** (SF Symbols):
  1. **General** (`info.square`) — hotkey, retain clipboard, language
  2. **Setup** (`gear`) — Microphone, input device, optional mic meter, optional unmute during dictation (ADR-007), Accessibility
  3. **Models** (`cpu`) — dictation STT + post-dictation formatting
  4. **Storage** (`internaldrive`) — total disk used + per-package sizes (share of total) with Active/Unused markers + delete unused packages

Default pane after open (post first-run): **General** if Ready, else **Setup**.

### Detail panes (one job each)

1. **Welcome** (only while `showFirstRun`) — one privacy sentence + **Continue**; then navigate to Setup (or Models if permissions already OK)
2. **Status Details** (via Details… only) — readiness, remaining hint buttons, last session / model error, **Check for updates…** (opens private GitHub Releases; no auto-install)
3. **General** — hotkey capture + optional **Also keep the result on the clipboard**; while recording, **Escape** cancels (no STT/paste); silent/too-short finish is a soft cancel; Language System / Russian / English (must not remount Settings or stop the optional mic meter)
4. **Setup** — Microphone, input device picker, Accessibility; optional **Show microphone meter** (off by default); optional **Unmute mic during dictation (experimental)** (off by default — ADR-007); tip to remove/re-add the app if Accessibility status is stuck
5. **Models** — STT picker for active (downloaded-only) model; per-package status; prominent recommended-download CTA only when **no** STT package is Ready yet; **Make active** on Ready-but-not-active rows; **Delete** on every Ready STT / Smart formatting package (not only Storage → delete unused); optional **Apple SpeechAnalyzer** (macOS 26+, ADR-008) uses **Prepare…** for system assets instead of HF download; formatting Off / Light / Smart / Smart+ with the same Make active + Delete pattern
6. **Storage** — total used + per-package on-disk sizes with share of total; each row marks **Active** (current STT or selected Smart package) or **Unused**; bulk delete removes unused only

No marketing cards, no stat strips. Progress belongs on the model row being downloaded.

## Menu bar icon states

- Idle (Ready)
- Needs setup (Almost/Blocked)
- Recording (Listening)
- Processing / cleanup (Understanding — STT + formatting share one label)
- Error (transient)

Menu content: readiness summary, **Settings…**, Quit.

## Status Capsule (session chrome)

During an active dictation session a compact floating **Status Capsule** appears near the camera notch (or under the menu bar on non-notch displays). It reports process state only (no hover/click actions):

| Phase | Capsule |
|-------|---------|
| Listening | `● Listening` / `● Слушаю` |
| Understanding | `⋯ Understanding` / `⋯ Распознаю` (STT **and** cleanup) |
| Writing | `✍ Writing` / `✍ Печатаю` (~0.35s after successful paste) |
| Inserted | `✓ Inserted` / `✓ Вставлено` (~1s, then hide) |

Escape cancel, soft silent cancel, and pipeline errors hide the capsule immediately (no Writing/Inserted). Design: `docs/superpowers/specs/2026-07-24-status-capsule-design.md`.

## First-run behavior

1. Settings opens on first launch.
2. Welcome detail explains local privacy in one sentence.
3. **Continue** clears `showFirstRun` and selects Setup (or Models if mic + Accessibility already granted).
4. Recommended STT download CTA lives in the Models pane while that package is not Ready.

## Clipboard option

When **Also keep the result on the clipboard** is on: paste at caret still runs, but the previous pasteboard is **not** restored — the dictation text remains for ⌘V if focus moved.

## Permissions notes

- Microphone TCC is requested only when status is `notDetermined`.
- Accessibility must be enabled manually in System Settings; CarrotType polls while waiting and refreshes on app activation.
- If System Settings already shows the app checked but CarrotType still shows denied: remove CarrotType from the Accessibility list, add it again, then refresh status or restart the app.
- Optional **Unmute mic during dictation (experimental)** (default off, ADR-007): Elgato Wave Link only in product copy; for the capture window only; restores prior mute. Wave Link must be running.

## Out of scope for this UX

- Model training UI
- Account / cloud sync
- Multi-profile voice cloning
- App Store permission flows beyond Mic + Accessibility
- Collapsible Settings sidebar
- Colored System Settings–style icon tiles / settings search
- Third-party settings packages or private API swizzling
