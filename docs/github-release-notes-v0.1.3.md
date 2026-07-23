# CarrotType v0.1.3 — GitHub Release notes

**Distribution:** private repository — DMG is invite-only (collaborators with repo access). Not a public download.

## Download

Attach: `CarrotType-0.1.3.dmg` (Apple Silicon, macOS 14+, ~16 MB app bundle without models).

Artifact path after `./macos/scripts/build-release-dmg.sh`: `dist/CarrotType-0.1.3.dmg`.

SHA-256 (this build): `PLACEHOLDER_AFTER_BUILD`

## What’s new

- **Settings sidebar panes** — General / Setup / Models / Storage with a Status header (Ready / Almost / Blocked + version) and **Details…** when not Ready.
- **Larger resizable Settings window** — default ~880×680, min ~720×520; plain fixed sidebar (no NavigationSplitView focus ring).
- **Window chrome watchdog** — resize/zoom without traffic-light flicker.
- **Default hotkey ⌥/** — Option-slash. If an older chord was saved, use **Reset** in Settings.

## Install (unsigned / not notarized yet)

1. Open the DMG and drag **CarrotType** into **Applications** (replace the previous build if present).
2. First launch: **Right-click → Open** (Gatekeeper), or:

```bash
xattr -dr com.apple.quarantine /Applications/CarrotType.app
```

3. Menu bar icon → **Settings…** / **Настройки…**
4. Grant **Microphone** and **Accessibility** if needed.
5. Ensure an STT model is Ready and active (Whisper Base recommended until the RU quality note is filled).

Default hotkey: **⌥/**. While recording: **Escape** cancels; the dictation hotkey again commits.

Models download on demand into `~/Library/Application Support/carrottype/models/` — they are not inside the DMG.

## Included (unchanged)

- Whisper Base / Small / Turbo q5 (ggml) + Parakeet TDT 0.6B v3
- Formatting: Off / Light / Smart / Smart+ (Qwen3 MLX)
- Experimental Wave Link unmute during dictation (ADR-007)
- Escape cancel + soft silent cancel; Status version + Check for updates
- Settings: RU/EN, Make active, retain-on-clipboard, optional mic meter

## Not yet

- In-app auto-update (Sparkle) — blocked on Developer ID / public or authenticated feed
- Apple Developer ID notarization
- Apple SpeechAnalyzer STT (planned after this release)
- Flipping `recommended` STT away from Whisper Base (see `docs/stt-ru-en-quality-note.md`)
