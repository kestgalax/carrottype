# CarrotType v0.1.6 — GitHub Release notes

**Distribution:** private repository — DMG is invite-only (collaborators with repo access). Not a public download.

## Download

Attach: `CarrotType-0.1.6.dmg` (Apple Silicon, macOS 14+, app bundle without models).

Artifact path after `./macos/scripts/build-release-dmg.sh`: `dist/CarrotType-0.1.6.dmg`.

SHA-256 (this build): `ede680d80b973cf3e798340d8e43a89994a756ff40e0450a636a890b941f5f6b`

## What’s new

- **Out-of-process Smart cleanup (ADR-009)** — Qwen3 Smart/Smart+ runs in `CarrotTypeCleanupHelper` (spawn → one cleanup → exit). The menu-bar host no longer keeps MLX/Metal heap after Smart sessions.
- **Host stays light** — MLX inference libs link only into the helper; package download stays in the app. Helper + `mlx-swift_Cmlx.bundle` ship inside the `.app`.
- Builds on v0.1.5 Storage/Models UX and Smart+ RAM honesty.

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

**Note:** Smart/Smart+ may take a moment longer on each use (cold load of the helper). Peak RAM (~1–2 GB) appears only while the helper runs, then that process exits.

## Included (unchanged from recent builds)

- Settings sidebar panes (General / Setup / Models / Storage) + Status header
- Whisper Base / Small / Turbo q5 (ggml) + Parakeet TDT 0.6B v3 + optional Apple SpeechAnalyzer
- Formatting: Off / Light / Smart / Smart+ (Qwen3 MLX)
- Experimental Wave Link unmute (ADR-007); Escape cancel + soft silent cancel; Check for updates

## Not yet

- In-app auto-update (Sparkle) — blocked on Developer ID / public or authenticated feed
- Apple Developer ID notarization
- Reliable Russian Apple SpeechAnalyzer assets (system-side; EN Prepare works)
