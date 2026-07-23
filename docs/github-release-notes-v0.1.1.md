# CarrotType v0.1.1 — GitHub Release notes

**Distribution:** private repository — DMG is invite-only (collaborators with repo access). Not a public download.

## Download

Attach: `CarrotType-0.1.1.dmg` (Apple Silicon, macOS 14+, ~16 MB app bundle without models).

Artifact path after `./macos/scripts/build-release-dmg.sh`: `dist/CarrotType-0.1.1.dmg`.

SHA-256 (this build): `15bd746805edaa83ba3a7f3a9d43335bfdc7e5376791c2c4ca75a95187380ea2`

## What’s new

- **Experimental:** Settings → **Unmute mic during dictation** (off by default). Supported for **Elgato Wave Link** only: temporarily clears Wave mic mute for the capture window and restores it afterward. Wave Link must be running (ADR-007).
- Wave Link 3 JSON-RPC client fix (`params` must not be `null`; prefer ports 1884–1893).

## Install (unsigned / not notarized yet)

1. Open the DMG and drag **CarrotType** into **Applications** (replace the previous build if present).
2. First launch: **Right-click → Open** (Gatekeeper), or:

```bash
xattr -dr com.apple.quarantine /Applications/CarrotType.app
```

3. Menu bar icon → **Settings…** / **Настройки…**
4. Grant **Microphone** and **Accessibility** if needed.
5. Ensure an STT model is Ready and active (Whisper Base recommended until the RU quality note is filled).
6. Optional: enable **Unmute mic during dictation (experimental)** when using Elgato Wave + Wave Link.

Default hotkey: **⌃⌥Space**.

Models download on demand into `~/Library/Application Support/carrottype/models/` — they are not inside the DMG.

## Included (unchanged from 0.1.0)

- Whisper Base / Small / Turbo q5 (ggml) + Parakeet TDT 0.6B v3
- Formatting: Off / Light / Smart / Smart+ (Qwen3 MLX)
- Settings: RU/EN, Make active, retain-on-clipboard, optional mic meter

## Not yet

- Apple Developer ID notarization (planned after paid membership)
- Flipping `recommended` STT away from Whisper Base (see `docs/stt-ru-en-quality-note.md`)
- Universal (non–Wave Link) mic mute control
