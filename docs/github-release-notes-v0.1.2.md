# CarrotType v0.1.2 — GitHub Release notes

**Distribution:** private repository — DMG is invite-only (collaborators with repo access). Not a public download.

## Download

Attach: `CarrotType-0.1.2.dmg` (Apple Silicon, macOS 14+, ~16 MB app bundle without models).

Artifact path after `./macos/scripts/build-release-dmg.sh`: `dist/CarrotType-0.1.2.dmg`.

SHA-256 (this build): `c8a8e6c5109f008762e57e9a63dfc9f67884784a530053f439c1c7cfca64dd76`

## What’s new

- **Escape cancels recording** — while dictating, Escape discards the capture (no STT / no paste) and restores mic mute if unmute-on-dictation was used.
- **Silent session soft-cancel** — finishing a too-short / silent recording returns to idle without a red error.
- **Status shows app version** (`v0.1.2` from the bundle) and **Check for updates…** opens the private GitHub Releases page (manual download; no auto-updater yet).

## Install (unsigned / not notarized yet)

1. Open the DMG and drag **CarrotType** into **Applications** (replace the previous build if present).
2. First launch: **Right-click → Open** (Gatekeeper), or:

```bash
xattr -dr com.apple.quarantine /Applications/CarrotType.app
```

3. Menu bar icon → **Settings…** / **Настройки…**
4. Grant **Microphone** and **Accessibility** if needed.
5. Ensure an STT model is Ready and active (Whisper Base recommended until the RU quality note is filled).

Default hotkey: **⌃⌥Space**. While recording: **Escape** cancels; the dictation hotkey again commits.

Models download on demand into `~/Library/Application Support/carrottype/models/` — they are not inside the DMG.

## Included (unchanged)

- Whisper Base / Small / Turbo q5 (ggml) + Parakeet TDT 0.6B v3
- Formatting: Off / Light / Smart / Smart+ (Qwen3 MLX)
- Experimental Wave Link unmute during dictation (ADR-007)
- Settings: RU/EN, Make active, retain-on-clipboard, optional mic meter

## Not yet

- In-app auto-update (Sparkle) — blocked on Developer ID / public or authenticated feed
- Apple Developer ID notarization
- Flipping `recommended` STT away from Whisper Base (see `docs/stt-ru-en-quality-note.md`)
