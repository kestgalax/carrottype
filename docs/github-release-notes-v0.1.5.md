# CarrotType v0.1.5 — GitHub Release notes

**Distribution:** private repository — DMG is invite-only (collaborators with repo access). Not a public download.

## Download

Attach: `CarrotType-0.1.5.dmg` (Apple Silicon, macOS 14+, ~16 MB app bundle without models).

Artifact path after `./macos/scripts/build-release-dmg.sh`: `dist/CarrotType-0.1.5.dmg`.

SHA-256 (this build): `f2706a9bdd7ac40e7ec0a28af095bbc4a0c30f02392c9c6ef5d3f2de6c797d10`

## What’s new

- **Smart idle memory** — after Smart/Smart+ formatting, MLX Metal cache is cleared (`Memory.clearCache()`); leaving Smart also unloads engines so RAM does not stay near the 1–2 GB peak.
- **Smart+ honesty** — Models shows size/license/blurb under Smart packages; Smart+ warns to expect ~1–2 GB RAM while running.
- **Formatting copy** — footer clarifies Smart is optional; try Off/Light first (can improve or worsen text).
- **Storage Active/Unused** — each installed package is marked so “Delete unused” is obvious without opening Models.

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
