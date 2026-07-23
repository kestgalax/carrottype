# UX Spec: Setup Status (Models + Permissions)

## Traceability

- Product Intent: `docs/product-intent.md`
- Related ADRs: `docs/decisions/ADR-002-runtime-stack.md`, `docs/decisions/ADR-003-model-catalog-and-cleanup.md`
- Feature: `docs/specs/features/hotkey-carrottype-caret-paste.md`

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
- Settings → **Language** picker: System / Russian / English (overrides without reinstall).

## Screen layout (Apple HIG / Tahoe)

Use native **`Settings` scene** with:

```text
Form { … }.formStyle(.grouped)
```

No custom Liquid Glass / `NSVisualEffectView`. System controls pick up Tahoe appearance when built with a current Xcode SDK.

Sections in order (one job each):

1. **Welcome** (only while `showFirstRun`) — one privacy sentence + **Continue**
2. **Status** — Ready / Almost / Blocked + remaining hints; short version (`vX.Y.Z` from the app bundle); **Check for updates…** opens the private GitHub Releases page (no auto-install)
3. **Permissions** — Microphone, input device picker, Accessibility; optional **Show microphone meter** (off by default — avoids keeping the mic hardware awake); optional **Unmute mic during dictation (experimental)** (off by default — ADR-007: Elgato Wave Link only; temporarily clear mute for capture, restore after; Wave Link must be running); tip to remove/re-add the app if Accessibility status is stuck
4. **Dictation model** — Picker for active (downloaded-only) model; per-package status; first-run CTA for recommended Whisper Base; on Ready-but-not-active rows show **Make active** (same pattern as formatting)
5. **Post-dictation formatting** — Picker Off / Light / Smart / Smart+ (Smart* only when package Ready); Ready-but-not-active Smart packages show **Make active**
6. **Hotkey** — capture UI + optional **Also keep the result on the clipboard**; while recording, **Escape** cancels (no STT/paste); a silent/too-short finish is a soft cancel (no red error)
7. **Language** — System / Russian / English (changing language must not remount Settings or stop the optional mic meter)
8. **Storage** — disk used + delete unused packages

No marketing cards, no stat strips. Progress belongs on the model row being downloaded.

## Menu bar icon states

- Idle (Ready)
- Needs setup (Almost/Blocked)
- Recording
- Processing (STT / formatting)
- Error (transient)

Menu content: readiness summary, **Settings…**, Quit.

## First-run behavior

1. Settings opens on first launch.
2. Welcome section explains local privacy in one sentence.
3. Recommended STT download CTA lives in the dictation-model section (same Form).
4. Optional Smart formatting download toggle.
5. **Continue** clears `showFirstRun`; full Settings Form remains.

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
- Custom branding / NavigationSplitView settings sidebar
