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

1. **Welcome** (only while `showFirstRun`) — privacy sentence, live four-step progress + **Continue**; always navigate to Setup, including the local trial when already Ready (0.6.0)
2. **Status Details** (via Details… at every readiness state) — readiness, remaining hint buttons, last session / model error, **Check for updates…** (native Sparkle in 0.5.0; available regardless of readiness)
3. **General** — dictation hotkey capture + optional **Walkie-talkie (hold to talk)** (off by default: press starts, press again commits; on: **hold** records, **release** commits — repeat press does not commit) + optional **Also keep the result on the clipboard** + optional **Show text while you speak** (ADR-014, off by default; disabled when active STT `supportsStreaming` is false; Capsule grows with adapting preview text); while recording, **Escape** cancels (no STT/paste); silent/too-short finish is a soft cancel; **Transform selected text** bindings list (max 5): each row has hotkey (default first binding **⌥'**), kind Translate/Custom, Ready Smart/Smart+/Gemma model, language pair for Translate or instruction editor for Custom (ADR-012); Language System / Russian / English (must not remount Settings or stop the optional mic meter)
4. **Setup** — Microphone, input device picker, Accessibility; optional **Show microphone meter** (off by default); optional **Unmute mic during dictation (experimental)** (off by default — ADR-007); tip to remove/re-add the app if Accessibility status is stuck
5. **Models** — one Parakeet Ultra row with state, size/license, download/cancel/retry/delete; no STT picker or alternative STT offerings (0.4.0, ADR-016). Already-installed Ultra is reused without download. Without Ultra, explain the explicit download requirement and optional legacy cleanup in Storage. Formatting Off / Light / Qwen3 0.6B / Gemma retains Ready-only selection and Make active / Delete controls. From 0.8.0 Smart+ is legacy-only: keep an existing active ready selection/binding and Storage, no new download/Make active.
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
3. **Continue** clears only `showFirstRun` and selects Setup. Readiness/progress still derives from actual permissions, Ultra and trial completion.
4. Setup and Models offer the explicit Ultra download while not Ready; installed Ultra is reused. No other STT is offered.

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

## Application updates — 0.5.0

- Menu, Details and General expose the same native Check for updates action, disabled only while Sparkle cannot accept another check. Native Sparkle handles available/no update/network/signature/read-only-location errors.
- General → App Updates: automatic checks off by default; separate opt-in background download/install-on-quit. Controls observe Sparkle's actual settings (including changes in its dialogs). Turning checks off disables the download control without silently discarding the saved preference.
- A requested restart waits for capture/processing/cancellation to finish; General displays that wait. At install handoff hotkeys cannot start another operation. Aborted installation releases that lock. Background downloading does not stop dictation or selection transforms. Downloaded automatic updates install on quit; no forced background restart.
- Models, language, hotkeys, clipboard option, Wave Link, formatting, bindings and statistics are retained outside the replaceable app. Last dictation recovery is still RAM-only and ends at app exit. First updater-enabled version is installed manually. Current self-signed downloads still need the Gatekeeper steps; permissions may need re-granting after an update.
- Before first publication the production feed endpoint does not yet exist; the regular Debug build may correctly report a network/feed error. Use the isolated signed staging feed to verify A → B, never publish a dummy release for a test.

## Setup/settings — 0.6.0 implementation contract (X1–X3)

- Setup shows four ordered steps: microphone, Accessibility, Ultra, local trial. Readiness still uses the three existing requirements; completing Welcome is not Ready. A successful trial persists only a completion Boolean, never its transcript. Existing users can run the same trial from Setup; no automatic recording/download on navigation.
- The trial starts only with an explicit button. It uses the existing recorder/STT/formatting/mute path and updater reservation, but delivers text only into a RAM-backed field in Settings. It never calls caret insertion, modifies the system clipboard, replaces Last Dictation or increments usage counts. Finish/Cancel are explicit; Escape cancels capture. Leaving Setup cancels capture or discards a processing result. The trial is controlled by Start/Finish buttons even if hold-to-talk is enabled; the dictation shortcut can also finish the active trial, and its key-up does not stop the trial; normal hotkey behavior is preserved outside a trial.
- Setup reuses permission actions, input picker/meter/Wave Link and model download/cancel/retry controls. Progress and next-step guidance update as permissions/model readiness change. Setup remains accessible after Welcome and after relaunch, including denied/offline/download-error states. Language changes update copy without remounting Settings.
- Transform bindings use disclosure rows with action, chord, language pair and model summary. All existing editing controls remain inside; newly added rows expand. A missing saved model remains visibly selected/unavailable; the UI explains the same fallback the runtime resolves rather than displaying a fictitious selection. Models links navigate to the actual Models pane. No download starts from selecting a fallback or visiting Models. An explicitly saved empty bindings list remains empty after relaunch. Capturing a hotkey temporarily unregisters app chords so conflicting chords reach the local editor; apply/conflict/cancel and leaving General restore registration without triggering dictation.
- Dictation pipeline reports requested/actual formatting mode and a safe fallback reason. Missing or failing Smart/Smart+/Gemma preserves the transcription via Light. Capsule briefly says basic formatting was applied; Details retains actual-mode information for the last completed dictation. No helper error, prompt or transcript is added to logs or disk. Trial formatting information remains within the trial. Stats/recovery remain counted once only for the normal paste-dispatch path.
- Scope stays within existing ADR-005/009/010/012/014/016/017. No new inference runtime, dependencies, download sink or updater trust changes. Full lifecycle coordinator work remains planned as 0.6.2.

## Update presentation — 0.6.1 implementation contract (N1–N3)

- General retains App Updates, automatic-check/download toggles and native Check action. Add the installed version and persistent What’s New button; Details adds the same button next to version. No new sidebar pane, Settings remount or automatic popup.
- What’s New opens a native sheet with app icon, installed version/date, summary, nonempty New/Improved/Fixed sections and item counts derived from content. Scroll only the content; keep full-changelog link and Got it button available. Use restrained carrot accents with native light/dark colors, keyboard/default action and selectable text.
- A validated bundled `ReleaseNotes.json` is the single content source. The native sheet reads it offline; packaging produces localized inline HTML/CSS and Markdown from the same source. English fallback is required. Missing/invalid/version-mismatched notes show a useful fallback with installed version and an explicit project changelog link; launch/updater remain usable.
- Store only observed/read version+build identifiers. First tracked launch establishes a quiet baseline; later observed changes display Updated until the sheet is viewed, preserving unread state across relaunch. An upgrade from a client without tracking has no misleading inferred badge. Opening notes never checks/downloads updates or changes opt-ins. No transcript or new HTTP source.
- The standard Sparkle driver remains responsible for update UI/actions, signed feed/archive verification and safe installation. Styled HTML is inline in the signed feed with explicit RU/EN `xml:lang`; only escaped prose and fixed template markup, no scripts or external resources. Standard Sparkle labels/description selection follow system preferred localization, while the native sheet follows the in-app language override. Changing that override does not rewrite process-wide AppleLanguages or restart/remount Settings.
- New templates are exercised against the pinned Sparkle 2.10.1 used by 0.5.0/0.6.0. Published assets remain immutable. Current installed notes and future available-version notes are separate presentations. Debug and manual acceptance precede publication; no new trust/runtime/network decision.

## Session reliability — 0.6.2 candidate

- Capture/preview/final file STT/caret and trial UX stay the same. Toggle/hold choice is fixed for an active recording, so changing settings does not strand release handling. Model and formatting changes apply to the next recording; clipboard/statistics opt-ins keep their existing live semantics.
- Stop/cancel detaches preview immediately and restores the original mute only after a pending unmute completes. Cancelled trial results are discarded even if an engine returns late. The next operation/install waits for the old WAV/preview/engine cleanup; stale callbacks cannot change a newer Capsule.
- Models/Storage deletion while pipeline work or maintenance is active reports “Models are in use. Try removing them after the current operation finishes.” No package is removed; retry remains available. Idle selection changes unload safely under the same gate.
- Ordinary Quit drains active cancellation/mute/helper/model cleanup before exit and admits no new recording while doing so. Sparkle retains its existing busy-install/restart policy. Abnormal OS termination is still best effort. Native cold start/unmute/quit scenarios are in the 0.6.2 Debug checklist, not inferred from fake-engine tests.

## Native A presentation — 0.7.0

Selected interface/logo A retains the fixed 200pt sidebar, five panes and existing window minimum/default sizes. Brand/title at top, readiness/progress/errors/Details and persistent What’s New at bottom; pane titles describe context, native grouped Forms keep all controls. General has Dictation plus an observed formatting selector sharing ModelManager with Models; Ready-only selection, all packages and fallback semantics stay. Sidebar selection is exposed to accessibility and keyboard focus has a visible outline. Language pickers have distinct localized names. Capsule respects Reduce Motion and increases interim-text contrast; status colors/symbols remain semantic. Installed-package/bulk deletion and stats clearing require explicit confirmation; cancellation has no maintenance side effect. Legacy/cache confirmation, selected model policy and install/session gate remain. Debug/manual acceptance required before publication; offscreen layouts do not prove interactive/VoiceOver/device behavior.

Final 0.7.0 brand selection is the original carrot-microphone A from the second comparison, not the initial plain carrot. Only idle brand assets change; active session symbols/labels stay semantic. SVG paths are editable filled outlines, with the selected microphone stroke expanded without a new runtime renderer. Maintainer explicitly accepted and authorized 0.7.0 publication after reviewing Debug and icon alternatives.

## 0.8.0 — Rules and theme

General shows the same model selection source as Models, followed by model-only formatting controls: fillers, accidental repetitions, self-corrections, preserve structure/paragraphs, My Rules (1000 characters), readable summary and reset. Base meaning/language/numeric constraints stay visible; additional rules concern presentation/term spelling. Off/Light explain that arbitrary model preferences are not applied. Model mistakes and visible fallback are stated explicitly.

Expandable text trial accepts up to 6000 characters and offers Run/Cancel/result. It never starts microphone capture or writes clipboard, Last Dictation or statistics; busy operations/install block Run. Capture rules/model for the run, retain the operation reservation through cancellation/unload, clear on section close. An empty Light result displays no speech text rather than a fake successful paste.

Appearance and language contains independent System/Light/Dark and System/RU/EN selectors. Missing/invalid theme is System; apply immediately and persist, react to OS changes only in System. No Settings identity remount, operation interruption or forced language change. Own native windows/sheets/Capsule should follow theme; template menu icon and accessibility preferences retain contrast. Interactive system-change/device/sheet checks are in the Debug checklist, not inferred from offscreen layouts.

0.8.0 maintainer feedback: outer Settings Form scrollbars are always hidden using `.scrollIndicators(.never)`; scrolling itself remains enabled. This applies to all five panes plus Welcome/Details. Nested My Rules/trial/Custom text editors keep automatic native indicators. No global Show Scroll Bars setting is modified.

0.8.0 custom-rule review: distinguish the requested model from the actual trial mode in the result heading. Highlight Light fallback (rules not applied) with an explicit warning. Explain that custom presentation preferences override defaults, and that combined/style instructions may be unreliable. A style request may alter wording while retaining meaning/intent; translation/summarizing remain separate transforms. Do not imply the free-text field is a deterministic rule engine.


### 0.8.0 exact-control review

General distinguishes exact controls (always-remove word list, lowercase prose, omit final sentence period) from model preferences/experimental business tone. Exact controls remain visible and opt-in under Off/Light, with protected-fragment/punctuation guidance and the effective validated word list. Existing model preferences remain visible when a model is selected, with free text preserved. Reset resets all dictation preferences, not theme or models. Trial/Setup/Details share actual mode, typed fallback reason, exact-controls status and separate tone status; unchanged wording is not reported as a business rewrite. Failed/inactive tone does not prevent exact controls. Settings outer scrolling stays hidden/functional; text-editor scrolling remains automatic. Defaults do not enable any new exact/style behavior.
