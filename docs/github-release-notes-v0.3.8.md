# CarrotType v0.3.8 — GitHub Release notes

**Distribution:** public repository ([MIT](../LICENSE), ADR-011). Unsigned DMG — not notarized; first launch usually needs **System Settings → Privacy & Security → Open Anyway** (not only Right-click → Open).

## Download

`CarrotType-0.3.8.dmg` (Apple Silicon, macOS 14+, app bundle without models).

SHA-256 (this build): `23c67825fd85c0db358cecf76638ba8bb717f031af1d37b1dd99e42efd7566b2`

## What’s new

- **Storage redesign** — Settings → Storage now has two sections:
  - **Installed packages** — disk used, Active/Unused rows, **Delete unused packages** (unchanged rules).
  - **Download cache** — size of Hugging Face hub folders for CarrotType catalog repos only, plus **Clear download cache** (confirmation). Clears cache only — does **not** uninstall Ready packages.
- Per-package **Delete** stays on **Models**. Deleting a package still does not wipe the Hub cache (re-download can stay fast until you clear cache).

## Install (unsigned / not notarized)

1. Open the DMG and drag **CarrotType** into **Applications** (replace the previous build if present).
2. First launch is usually **blocked** by Gatekeeper — on current macOS, Right-click → Open alone is often not enough:
   1. In Finder → **Applications**, open CarrotType (or **Right-click → Open**).
   2. Acknowledge / dismiss the blocked-app warning if shown.
   3. Open **System Settings → Privacy & Security** and choose **Open Anyway** for CarrotType.
   4. Confirm the final Open prompt.
3. Optional shortcut (may still need Privacy & Security on some versions):

```bash
xattr -dr com.apple.quarantine /Applications/CarrotType.app
```

4. Menu bar icon → **Settings…** / **Настройки…**
5. Grant **Microphone** and **Accessibility** if needed.
6. Download an STT model (default **Parakeet TDT 0.6B v3**) and Make active if needed.
7. Optional: Settings → **Storage** to review package sizes or clear the Hugging Face download cache.
8. Optional: live draft, transform bindings, Statistics, Wave Link unmute — same as v0.3.7.

Default dictation hotkey: **⌥/**. Default transform binding: **⌥'**.

Models download on demand into `~/Library/Application Support/carrottype/models/` — they are not inside the DMG. Hub download cache (if any) lives under `~/.cache/huggingface/hub`.

## Included (unchanged from v0.3.7)

- Secure Coding hardening (ADR-015): helper path jail, MLX `hubRevision` pins, clipboard restore/copy honesty, notarization prep
- Recorder-first live draft; Escape cancel → Copy capsule; Walkie-talkie; Selection Transform; Statistics; custom DMG window
- Whisper / Parakeet / optional Apple SpeechAnalyzer; Off / Light / Smart / Smart+ / Gemma cleanup via helper

## Not yet

- Replace-selection / paste output mode for transform
- Dedicated Translate-only models
- In-app auto-update (Sparkle)
- Apple Developer ID notarization (prep scripts exist; unsigned + Open Anyway remains supported)
