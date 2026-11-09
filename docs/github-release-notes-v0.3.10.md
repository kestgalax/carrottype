# CarrotType v0.3.10 — GitHub Release notes

**Distribution:** public MIT repository. DMG without Apple Developer ID notarization; first launch may require **System Settings → Privacy & Security → Open Anyway**.

## Download

`CarrotType-0.3.10.dmg` — Apple Silicon, macOS 14+, build 23. Models are downloaded separately.

SHA-256: `c7bc0e0a51271237fbb195890166ca4ed4b55907c844555c43defae988ab22a6`.

## What changed

- **Recover the last dictation:** Copy Last Dictation and Clear Last Dictation in the menu. One completed result stays in memory until replaced, cleared, or app exit; no transcript history is written to disk. Cancelling a later recording does not erase it. A known insertion error offers Copy / Close recovery in the Capsule.
- **Safer clipboard restore:** a newer copy takes precedence over delayed restoration. Empty clipboards and multiple items/types are restored correctly.
- **Visible errors:** Details stays available when Ready; last-operation errors remain visible after permission refresh and can be dismissed. Model and session errors are shown separately.
- **Honest completion status:** the Capsule says Done after dispatching the paste command. Completed-dictation statistics describe dispatch, not verified insertion in the receiving application; existing aggregates remain intact.
- **More robust Smart/Gemma helper:** concurrent stdout/stderr draining, bounded output, timeout/cancellation cleanup and protection against SIGPIPE when the helper exits early. Existing Light fallback remains.

Existing STT choices, cleanup modes, Translate/Custom bindings, live draft, hold-to-talk, Wave Link, RU/EN, Storage and opt-in statistics remain available. The Ultra-only catalog and in-app updater are separate future versions.

## Install / update

1. Quit the running CarrotType, including a Debug test copy if open.
2. Open the DMG and drag **CarrotType** into **Applications**, replacing the previous application.
3. If Gatekeeper blocks launch: attempt to open CarrotType in Finder, then **System Settings → Privacy & Security → Open Anyway**, and confirm. Right-click → Open alone may be insufficient.
4. Recheck **Microphone** and **Accessibility** permissions if macOS requests them. Existing models, settings and statistics remain in Application Support/UserDefaults.

Default dictation hotkey: **⌥/**. Default transform binding: **⌥'**.

## Verification and limits

- Debug build 0.3.10 (23), production-code reliability checks and existing catalog/live-draft/Wave Link checks passed. The maintainer confirmed every item in the Debug manual checklist before release preparation.
- Clean Release arm64 build passed. Final DMG checksum, deep app signature, helper model-path jail and embedded MLX shaders verified. Installer Finder layout/background preserved from the checksum-verified 0.3.9 DMG because local Finder Apple Events authorization is unavailable.
- CGEvent does not acknowledge actual insertion in other apps. If ⌘V was ignored, use Copy Last Dictation.
- macOS does not identify the writer of a clipboard change. An external copy concurrent with the short selection ⌘C fallback window cannot reliably be distinguished from the requested copy; the AX selection path avoids that ambiguity.
- Full offline network audit remains deferred. No runtime/dependency/network-sink changes in this release; models and speech/text processing remain local.
