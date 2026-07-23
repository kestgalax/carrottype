# CarrotType v0.1.0 — GitHub Release notes

## Download

Attach: `CarrotType-0.1.0.dmg` (Apple Silicon, macOS 14+, ~16 MB app bundle without models).

Artifact path after `./macos/scripts/build-release-dmg.sh`: `dist/CarrotType-0.1.0.dmg`.

SHA-256 (this build): `45622b39e2ac34f0517212b1c59f4f5feb23adc1bde445eba2fa840347e543eb`

## Install (unsigned / not notarized yet)

1. Open the DMG and drag **CarrotType** into **Applications**.
2. First launch: **Right-click → Open** (Gatekeeper), or:

```bash
xattr -dr com.apple.quarantine /Applications/CarrotType.app
```

3. Menu bar icon → **Settings…** / **Настройки…**
4. Grant **Microphone** and **Accessibility**.
5. Download **Whisper Base** (recommended) or another STT package; use **Make active** on a Ready model if more than one is installed.
6. Optional: Smart formatting (Qwen3) or **Whisper Small / Turbo q5** for higher STT quality.
7. Optional: **Also keep the result on the clipboard** after paste; Language: System / Russian / English.

Default hotkey: **⌃⌥Space**.

Models download on demand into `~/Library/Application Support/carrottype/models/` — they are not inside the DMG.

## Included in this build

- Whisper Base / Small / **Turbo q5** (ggml) + SHA-256 verify; reliable download staging (no CFNetwork temp-move failures)
- Parakeet TDT 0.6B v3 (FluidAudio CoreML)
- Formatting: Off / Light / Smart / Smart+ (Qwen3 MLX)
- Settings: RU/EN String Catalog + in-app language; **Make active** for STT and Smart formatting; optional retain-on-clipboard; optional mic meter (survives language change)
- Transparent AppIcon (system squircle mask)

## Not yet

- Apple Developer ID notarization (planned after paid membership)
- Flipping `recommended` STT away from Whisper Base (see `docs/stt-ru-en-quality-note.md`)
