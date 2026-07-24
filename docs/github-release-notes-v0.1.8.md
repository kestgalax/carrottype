# CarrotType v0.1.8 — GitHub Release notes

**Distribution:** private repository — DMG is invite-only (collaborators with repo access). Not a public download.

## Download

Attach: `CarrotType-0.1.8.dmg` (Apple Silicon, macOS 14+, app bundle without models).

Artifact path after `./macos/scripts/build-release-dmg.sh`: `dist/CarrotType-0.1.8.dmg`.

SHA-256 (this build): _(fill after DMG build)_

## What’s new

- **Idle menu bar icon** — `waveform.badge.microphone` instead of plain `waveform`, so Ready/idle reads more clearly as dictation.

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

- Status Capsule session chrome (Listening → Understanding → Writing → Inserted)
- Settings sidebar panes (General / Setup / Models / Storage) + Status header
- Whisper Base / Small / Turbo q5 (ggml) + Parakeet TDT 0.6B v3 + optional Apple SpeechAnalyzer
- Formatting: Off / Light / Smart / Smart+ via session-scoped `CarrotTypeCleanupHelper`
- Experimental Wave Link unmute (ADR-007); Escape cancel + soft silent cancel; Check for updates

## Not yet

- In-app auto-update (Sparkle) — blocked on Developer ID / public or authenticated feed
- Apple Developer ID notarization
- Reliable Russian Apple SpeechAnalyzer assets (system-side; EN Prepare works)
