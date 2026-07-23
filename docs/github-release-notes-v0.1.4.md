# CarrotType v0.1.4 — GitHub Release notes

**Distribution:** private repository — DMG is invite-only (collaborators with repo access). Not a public download.

## Download

Attach: `CarrotType-0.1.4.dmg` (Apple Silicon, macOS 14+, ~16 MB app bundle without models).

Artifact path after `./macos/scripts/build-release-dmg.sh`: `dist/CarrotType-0.1.4.dmg`.

SHA-256 (this build): `PLACEHOLDER_AFTER_BUILD`

## What’s new

- **Recommended STT is Parakeet TDT 0.6B v3** — aligns with ADR-003; Whisper Base/Small/Turbo remain optional. The recommended-download CTA only appears when **no** STT model is installed yet.
- **Optional Apple SpeechAnalyzer** (macOS 26+, ADR-008) — Prepare system speech assets; calm copy when RU assets fail to install (EN usually works). Use Whisper/Parakeet for Russian until Apple delivers the RU pack.
- **Models: Delete on Ready rows** — remove an installed STT or Smart formatting package without going through Storage bulk cleanup.
- **Storage breakdown** — total used plus per-package size and share of total.
- **Settings polish** — recommended CTA uses the live recommended package name/size (no hard-coded Whisper Base).

## Install (unsigned / not notarized yet)

1. Open the DMG and drag **CarrotType** into **Applications** (replace the previous build if present).
2. First launch: **Right-click → Open** (Gatekeeper), or:

```bash
xattr -dr com.apple.quarantine /Applications/CarrotType.app
```

3. Menu bar icon → **Settings…** / **Настройки…**
4. Grant **Microphone** and **Accessibility** if needed.
5. Download an STT model (**Parakeet** recommended for new installs) and Make active if needed.

Default hotkey: **⌥/**. While recording: **Escape** cancels; the dictation hotkey again commits.

Models download on demand into `~/Library/Application Support/carrottype/models/` — they are not inside the DMG.

## Included (unchanged from recent builds)

- Settings sidebar panes (General / Setup / Models / Storage) + Status header
- Whisper Base / Small / Turbo q5 (ggml) + Parakeet TDT 0.6B v3 + optional Apple SpeechAnalyzer
- Formatting: Off / Light / Smart / Smart+ (Qwen3 MLX)
- Experimental Wave Link unmute (ADR-007); Escape cancel + soft silent cancel; Check for updates

## Not yet

- In-app auto-update (Sparkle) — blocked on Developer ID / public or authenticated feed
- Apple Developer ID notarization
- Reliable Russian Apple SpeechAnalyzer assets (system-side; EN Prepare works)
