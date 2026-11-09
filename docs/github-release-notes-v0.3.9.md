# CarrotType v0.3.9 — GitHub Release notes

**Distribution:** public repository ([MIT](../LICENSE), ADR-011). Unsigned DMG — not notarized; first launch usually needs **System Settings → Privacy & Security → Open Anyway** (not only Right-click → Open).

## Download

`CarrotType-0.3.9.dmg` (Apple Silicon, macOS 14+, app bundle without models).

SHA-256 (this build): `_pending_after_dmg_`

## What’s new

- **Faster dictation start with Wave Link unmute** (ADR-007) — mic capture starts immediately; unmute runs in parallel instead of blocking Listening. Wave Link TCP port is cached in-process; discover + unmute share one WebSocket round. Restore still waits for any in-flight unmute.
- **Live draft quality** (ADR-014) — Capsule preview no longer forces UI `appLanguage` into FluidAudio’s Latin/Cyrillic script filter (that produced transliteration / `<unk>` / comma spam). Live draft matches file STT: multilingual auto-detect. Preview PCM attaches after unmute; muted leading silence is dropped from the preview buffer; decoder junk tokens are stripped from Capsule text. Final paste path unchanged (session WAV → offline STT).

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
6. Download an STT model (default **Parakeet TDT 0.6B v3**) and Make active if needed.
7. Optional: Setup → **Unmute mic during dictation (experimental)** for Elgato Wave + Wave Link — should feel snappier than v0.3.8.
8. Optional: Settings → General → **Show text while you speak** (Parakeet) for live draft.
9. Optional: Storage / Statistics / transform bindings — same as v0.3.8.

Default dictation hotkey: **⌥/**. Default transform binding: **⌥'**.

Models download on demand into `~/Library/Application Support/carrottype/models/` — they are not inside the DMG. Hub download cache (if any) lives under `~/.cache/huggingface/hub`.

## Included (unchanged from v0.3.8)

- Storage: installed packages + catalog-scoped Hugging Face download cache clear
- Secure Coding hardening (ADR-015)
- Recorder-first live draft; Escape cancel → Copy capsule; Walkie-talkie; Selection Transform; Statistics; custom DMG window
- Whisper / Parakeet / optional Apple SpeechAnalyzer; Off / Light / Smart / Smart+ / Gemma cleanup via helper

## Not yet

- Replace-selection / paste output mode for transform
- Dedicated Translate-only models
- In-app auto-update (Sparkle)
- Apple Developer ID notarization (prep scripts exist; unsigned + Open Anyway remains supported)
