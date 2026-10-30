# CarrotType v0.3.7 — GitHub Release notes

**Distribution:** public repository ([MIT](../LICENSE), ADR-011). Unsigned DMG — not notarized; first launch usually needs **System Settings → Privacy & Security → Open Anyway** (not only Right-click → Open).

## Download

`CarrotType-0.3.7.dmg` (Apple Silicon, macOS 14+, app bundle without models).

SHA-256 (this build): `fda02bf85c2b027ac43ca07b04bbdc093068c649661fa127e13b827425c06d4f`

## What’s new

- **Secure Coding / supply-chain hardening** (ADR-015) — Cleanup helper only loads models under `~/Library/Application Support/carrottype/models/` (rejects other paths). MLX Smart / Smart+ / Gemma Hub downloads use pinned `hubRevision` commit SHAs from the catalog (no user input); a `.hub-revision` marker must match for Ready. Whisper ggml SHA-256 unchanged.
- **Clipboard** — Faster restore after paste (~0.20s). Retain-clipboard Settings copy notes that other apps can read the system pasteboard while the result stays there.
- **Docs / prep** — OWASP Mobile Top 10 checklist + supply-chain note under `docs/security/`; notarization prep script and env example (`ops/deploy.md`) — still **not** notarized until a Developer ID is available.

**Note:** If you already downloaded Smart / Smart+ / Gemma before v0.3.7, re-download once so the revision marker is written.

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
6. Download an STT model (the default download is **Parakeet TDT 0.6B v3**; **Parakeet Ultra** is in the model list) and Make active if needed.
7. Optional: Settings → General → **Show text while you speak** (Parakeet only).
8. For transform / Smart formatting: download Smart / Smart+ / Gemma in Models (re-download if upgrading from ≤0.3.6); configure bindings under **Transform selected text**.
9. Optional: Settings → **Statistics** → enable local collection.
10. Optional (Elgato Wave + Wave Link): Setup → **Unmute mic during dictation (experimental)** — off by default (ADR-007).

Default dictation hotkey: **⌥/**. Default transform binding: **⌥'**. While recording: **Escape** cancels; with live draft text, the Capsule may keep a Copy snapshot. Escape also closes transform / cancel Copy capsules.

Models download on demand into `~/Library/Application Support/carrottype/models/` — they are not inside the DMG. MLX cleanup packages may also use `~/.cache/huggingface/hub`. Local stats (if enabled) live in `~/Library/Application Support/carrottype/stats/`.

## Included (unchanged from v0.3.6)

- Recorder-first live draft (mic + WAV before Parakeet load; ADR-014)
- Live-draft Escape cancel → Copy capsule (non-empty preview, no paste)
- Settings → General per-toggle hints (Walkie-talkie, clipboard, live draft)
- Optional live draft while speaking (Parakeet v3 / Ultra)
- Optional Parakeet Ultra beside default Parakeet TDT 0.6B v3
- Statistics month characters beside successful dictations; typing speed above Bindings
- Local opt-in usage statistics (ADR-013)
- Hidden DMG packaging folders (`.background` / `.fseventsd`)
- Walkie-talkie / hold-to-talk dictation mode
- Custom DMG Finder install window
- Selection Transform bindings + bidirectional Translate (ADR-012)
- Status Capsule session chrome (Listening → Understanding → Writing → Inserted)
- Idle menu bar icon `waveform.badge.microphone`
- Settings sidebar panes (General / Setup / Models / Storage / Statistics) + Status header
- Whisper Base / Small / Turbo q5 (ggml) + Parakeet TDT 0.6B v3 + optional Parakeet Ultra + optional Apple SpeechAnalyzer
- Formatting: Off / Light / Smart / Smart+ / Gemma 4 E2B via session-scoped `CarrotTypeCleanupHelper`
- Escape cancel + soft silent cancel; Check for updates (opens Releases)

## Not yet

- Replace-selection / paste output mode for transform
- Dedicated Translate-only models
- In-app auto-update (Sparkle)
- Apple Developer ID notarization (optional; unsigned + Privacy & Security → Open Anyway is the supported install path; prep scripts exist)
