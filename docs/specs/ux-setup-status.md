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
| **Ready** | Microphone granted **and** Accessibility granted **and** Parakeet Ultra `Ready` |
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

- **Status header** (not a pane): Ready / Almost / Blocked + version (`vX.Y.Z`). When Almost/Blocked, **Details…** opens the Status checklist in the detail column (deep-links to Setup / Models). Details remains accessible when Ready (0.3.10); readiness and the last operation error are displayed separately.
- **Panes** (SF Symbols):
  1. **General** (`info.square`) — dictation hotkey, optional Walkie-talkie (hold to talk), retain clipboard, transform selected text **bindings** (hotkey + Translate/Custom + model + language pair), language
  2. **Setup** (`gear`) — Microphone, input device, optional mic meter, optional unmute during dictation (ADR-007), Accessibility
  3. **Models** (`cpu`) — Parakeet Ultra + post-dictation formatting
  4. **Storage** (`internaldrive`) — installed packages (sizes, Active/Unused, delete unused) + catalog-scoped Hugging Face download cache size/clear
  5. **Statistics** (`chart.bar`) — opt-in local time-saved estimates for a selected month (ADR-013); off by default

Default pane after open (post first-run): **General** if Ready, else **Setup**.

### Detail panes (one job each)

1. **Welcome** (only while `showFirstRun`) — one privacy sentence + **Continue**; then navigate to Setup (or Models if permissions already OK)
2. **Status Details** (via Details… at every readiness state) — readiness, remaining hint buttons, last session / model error, **Check for updates…** (opens public GitHub Releases; no auto-install)
3. **General** — dictation hotkey capture + optional **Walkie-talkie (hold to talk)** (off by default: press starts, press again commits; on: **hold** records, **release** commits — repeat press does not commit) + optional **Also keep the result on the clipboard** + optional **Show text while you speak** (ADR-014, off by default; disabled when active STT `supportsStreaming` is false; Capsule grows with adapting preview text); while recording, **Escape** cancels (no STT/paste); silent/too-short finish is a soft cancel; **Transform selected text** bindings list (max 5): each row has hotkey (default first binding **⌥'**), kind Translate/Custom, Ready Smart/Smart+/Gemma model, language pair for Translate or instruction editor for Custom (ADR-012); Language System / Russian / English (must not remount Settings or stop the optional mic meter)
4. **Setup** — Microphone, input device picker, Accessibility; optional **Show microphone meter** (off by default); optional **Unmute mic during dictation (experimental)** (off by default — ADR-007); tip to remove/re-add the app if Accessibility status is stuck
5. **Models** — one Parakeet Ultra row with state, size/license, download/cancel/retry/delete; no STT picker or alternative STT offerings (0.4.0, ADR-016). Already-installed Ultra is reused without download. Without Ultra, explain the explicit download requirement and optional legacy cleanup in Storage. Formatting Off / Light / Smart / Smart+ / Gemma retains Ready-only selection and Make active / Delete controls.
6. **Storage** — Installed packages (current Ultra/cleanup sizes, Active/Unused, delete unused), optional Retired Dictation Models (known former catalog directories, per-group removal with confirmation) and Download cache (current Hub repos plus the allowlisted retired Parakeet v3 repo). Nothing is removed automatically. Legacy Apple cleanup removes only the app preparation marker; shared system assets and unknown experimental packages remain untouched. Package Delete does not clear Hub cache; cache clear does not uninstall Ready packages.
7. **Statistics** — toggle to collect local counts (off by default); month stepper (current month default); two estimates (**Would have typed** / **Time saved**) plus **characters** and **completed dictation** counts side by side; **typing speed** (WPM default 50, 1 word = 5 characters, recomputes dictation times only); then **Bindings** rows with per-hotkey successful transform counts (live labels; deleted bindings remain as an orphan row). **Clear statistics** wipes the local JSON. No charts or transcripts. Copy from Capsule is not counted.

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
| Understanding | `⋯ Understanding` / `⋯ Распознаю` (STT **and** cleanup; also transform while LLM runs) |
| Writing | `✍ Pasting` / `✍ Вставляю` (~0.35s after paste-command dispatch) |
| Inserted | `✓ Done` / `✓ Готово` (~1s, then hide) |

**Transform result** (ADR-012): after a successful selection transform the capsule expands to show the result text (Translate may show direction e.g. `EN → RU`) with **Copy** and **Close** buttons (mouse events enabled for result/recovery phases). Escape dismisses. Does not auto-replace the selection.

**Live-draft cancel Copy** (ADR-014, v0.3.5): Escape during recording with live draft on and non-empty preview cancels without paste but keeps a **Copy / Close** snapshot in the Capsule (transform-style chrome); auto-dismiss ~5 s; new dictation clears it.

Escape cancel with empty preview, soft silent cancel, and pipeline errors hide the capsule immediately (no Writing/Inserted). Design: `docs/superpowers/specs/2026-07-24-status-capsule-design.md`.

## First-run behavior

1. Settings opens on first launch.
2. Welcome detail explains local privacy in one sentence.
3. **Continue** clears `showFirstRun` and selects Setup (or Models if mic + Accessibility already granted).
4. The Models pane offers the explicit Ultra download while not Ready; no other STT is offered.

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

## Reliability changes — 0.3.10

- Menu → Copy Last Dictation / Clear Last Dictation appear when a completed non-empty dictation is retained. Only one text is held in RAM, until replaced by another completed dictation, explicit clear, or exit. Starting/cancelling a session or a later STT error does not erase it. No transcript files or logs are added.
- A known insertion error presents the completed text in Copy / Close recovery chrome (existing transform-result panel, dismissed with Escape/new dictation). Other session errors remain readable in the menu and Status Details. A readiness refresh does not dismiss them; a subsequent successful dictation/transform or explicit Dismiss Error does.
- Details is always accessible. Last session and model errors have separate messages; actions lead to Setup/Models and to Copy recovery where available. Readiness continues to describe permissions/model readiness, not the last operation's outcome.
- Done means the paste command was sent, not that an external application acknowledged insertion. Statistics count completed dictations with dispatched paste commands, excluding known insertion errors; existing aggregates remain and are not reclassified as verified insertions. Copy does not count.
- Clipboard restore checks the current change count and preserves a newer copy. An initially empty clipboard is restored as empty; item types and multiple items are preserved. Selection ⌘C fallback observes a short window and cleans up before returning cancellation; concurrent external copies in this window cannot be distinguished from the requested copy by macOS.
- All existing model choices, Light/Smart/Gemma modes, transform bindings, RU/EN, microphone/meter, Wave Link, live draft, hold-to-talk and opt-in statistics remain available in this version.

## Ultra migration — 0.4.0

- On launch, old/unknown saved STT ids migrate to Ultra; no model download starts automatically. Without Ultra readiness is Almost and Models offers Download. An already-installed Ultra cache (even without its historical marker) is reused.
- Existing formatting selection, transform bindings, microphone/meter, Wave Link, clipboard/recovery, RU/EN and opt-in statistics are preserved.
- Storage exposes known legacy files for explicit, confirmed deletion only. Show package-local Apple preparation metadata without claiming removal of system speech assets. No cleanup of unknown experiments.
- A user who wants to return to 0.3.10 should retain old weights until the Ultra migration is accepted. Deletion confirmation explains potential re-download for the older app.
- Debug manual acceptance is separate from the already accepted/released 0.3.10.
