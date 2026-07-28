# CarrotType v0.1.9 — GitHub Release notes

**Distribution:** public repository ([MIT](../LICENSE), ADR-011). Unsigned DMG — not notarized; first launch usually needs **System Settings → Privacy & Security → Open Anyway** (not only Right-click → Open).

## Download

`CarrotType-0.1.9.dmg` (Apple Silicon, macOS 14+, app bundle without models).

SHA-256 (this build): `4ab2fb7df541395be5efceec748985dcd996a46d296d7ecb4de386d41842a8bc`

## What’s new

- **Optional Gemma 4 E2B cleanup** (ADR-010) — downloadable formatting package beside Smart / Smart+ (`cleanup.gemma4-e2b-4bit`, ~3.5 GB, Apache-2.0 MLX 4-bit). Same out-of-process helper as Qwen; not the default (Light stays default until you Make active).
- **Hardened literal cleanup prompt** — shared Qwen/Gemma instructions: anti-instruction, no paraphrase, self-corrections, output-only; user framed as `Транскрипт:`; `temperature: 0`; Qwen keeps `enable_thinking` off.
- **MLX package download progress** — cleanup downloads report progress more like STT (MainActor hop + on-disk estimate when Hub `fractionCompleted` stalls). Delete still clears Application Support only; Hugging Face hub cache under `~/.cache/huggingface/hub` may remain.

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
6. Download an STT model (**Parakeet** recommended for new installs) and Make active if needed.
7. Optional: Models → post-dictation formatting → download **Gemma 4 E2B** (or Smart / Smart+) and Make active.
8. Optional (Elgato Wave + Wave Link): Setup → **Unmute mic during dictation (experimental)** — hotkey temporarily clears mic mute for capture and restores it afterward so you do not need a separate physical mute toggle. Wave Link must be running; off by default (ADR-007).

Default hotkey: **⌥/**. While recording: **Escape** cancels; the dictation hotkey again commits.

Models download on demand into `~/Library/Application Support/carrottype/models/` — they are not inside the DMG. MLX cleanup packages may also use `~/.cache/huggingface/hub`.

## Included (unchanged from recent builds)

- Status Capsule session chrome (Listening → Understanding → Writing → Inserted)
- Idle menu bar icon `waveform.badge.microphone`
- Settings sidebar panes (General / Setup / Models / Storage) + Status header
- Whisper Base / Small / Turbo q5 (ggml) + Parakeet TDT 0.6B v3 + optional Apple SpeechAnalyzer
- Formatting: Off / Light / Smart / Smart+ / Gemma 4 E2B via session-scoped `CarrotTypeCleanupHelper`
- Escape cancel + soft silent cancel; Check for updates (opens Releases)

## Not yet

- In-app auto-update (Sparkle)
- Apple Developer ID notarization (optional; unsigned + Privacy & Security → Open Anyway is the supported install path)
- Reliable Russian Apple SpeechAnalyzer assets (system-side; EN Prepare works)
