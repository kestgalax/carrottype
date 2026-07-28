# CarrotType v0.1.9 — GitHub Release notes

**Distribution:** private repository — DMG is invite-only (collaborators with repo access). Not a public download.

## Download

Attach: `CarrotType-0.1.9.dmg` (Apple Silicon, macOS 14+, app bundle without models).

Artifact path after `CLEAN=1 ./macos/scripts/build-release-dmg.sh`: `dist/CarrotType-0.1.9.dmg`.

SHA-256 (this build): _pending — filled after DMG build_

## What’s new

- **Optional Gemma 4 E2B cleanup** (ADR-010) — downloadable formatting package beside Smart / Smart+ (`cleanup.gemma4-e2b-4bit`, ~3.5 GB, Apache-2.0 MLX 4-bit). Same out-of-process helper as Qwen; not the default (Light stays default until you Make active).
- **Hardened literal cleanup prompt** — shared Qwen/Gemma instructions: anti-instruction, no paraphrase, self-corrections, output-only; user framed as `Транскрипт:`; `temperature: 0`; Qwen keeps `enable_thinking` off.
- **MLX package download progress** — cleanup downloads report progress more like STT (MainActor hop + on-disk estimate when Hub `fractionCompleted` stalls). Delete still clears Application Support only; Hugging Face hub cache under `~/.cache/huggingface/hub` may remain.

## Install (unsigned / not notarized yet)

1. Open the DMG and drag **CarrotType** into **Applications** (replace the previous build if present).
2. First launch: **Right-click → Open** (Gatekeeper), or:

```bash
xattr -dr com.apple.quarantine /Applications/CarrotType.app
```

3. Menu bar icon → **Settings…** / **Настройки…**
4. Grant **Microphone** and **Accessibility** if needed.
5. Download an STT model (**Parakeet** recommended for new installs) and Make active if needed.
6. Optional: Models → post-dictation formatting → download **Gemma 4 E2B** (or Smart / Smart+) and Make active.

Default hotkey: **⌥/**. While recording: **Escape** cancels; the dictation hotkey again commits.

Models download on demand into `~/Library/Application Support/carrottype/models/` — they are not inside the DMG. MLX cleanup packages may also use `~/.cache/huggingface/hub`.

## Included (unchanged from recent builds)

- Status Capsule session chrome (Listening → Understanding → Writing → Inserted)
- Idle menu bar icon `waveform.badge.microphone`
- Settings sidebar panes (General / Setup / Models / Storage) + Status header
- Whisper Base / Small / Turbo q5 (ggml) + Parakeet TDT 0.6B v3 + optional Apple SpeechAnalyzer
- Formatting: Off / Light / Smart / Smart+ / Gemma 4 E2B via session-scoped `CarrotTypeCleanupHelper`
- Experimental Wave Link unmute (ADR-007); Escape cancel + soft silent cancel; Check for updates

## Not yet

- In-app auto-update (Sparkle) — blocked on Developer ID / public or authenticated feed
- Apple Developer ID notarization
- Reliable Russian Apple SpeechAnalyzer assets (system-side; EN Prepare works)
