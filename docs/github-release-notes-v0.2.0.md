# CarrotType v0.2.0 — GitHub Release notes

**Distribution:** public repository ([MIT](../LICENSE), ADR-011). Unsigned DMG — not notarized; first launch usually needs **System Settings → Privacy & Security → Open Anyway** (not only Right-click → Open).

## Download

`CarrotType-0.2.0.dmg` (Apple Silicon, macOS 14+, app bundle without models).

SHA-256 (this build): `0c39c863b30564caad83ce3888e6019b62b5c90d815039988a36fe09728e027d`

## What’s new

- **Selection Transform** (ADR-012 / F-002) — secondary loop beside dictation: select text → binding hotkey → on-device LLM → Status Capsule (**Copy** / **Close**, no auto-replace).
- **Transform bindings** (up to 5) in Settings → General — each maps a shortcut to **Translate** or **Custom**, plus a Ready Smart / Smart+ / Gemma model.
- **Bidirectional Translate** — configure a language pair (default **ru ↔ en**); `NLLanguageRecognizer` flips to the other side. Capsule can show direction (`EN → RU`).
- **Default binding:** Translate on **⌥'**, pair ru↔en.
- **Storage Active/Unused** — cleanup packages used by transform bindings count as Active (and are kept by Delete unused).
- Helper protocol: optional custom `instructions` on `CleanupHelperRequest` (dictation still uses the literal cleanup prompt).

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
6. Download an STT model (**Parakeet** recommended) and Make active if needed.
7. For transform: download Smart / Smart+ / Gemma in Models; configure bindings under **Transform selected text**.
8. Optional (Elgato Wave + Wave Link): Setup → **Unmute mic during dictation (experimental)** — off by default (ADR-007).

Default dictation hotkey: **⌥/**. Default transform binding: **⌥'**. While recording: **Escape** cancels; Escape also closes the transform result Capsule.

Models download on demand into `~/Library/Application Support/carrottype/models/` — they are not inside the DMG. MLX cleanup packages may also use `~/.cache/huggingface/hub`.

## Included (unchanged from recent builds)

- Status Capsule session chrome (Listening → Understanding → Writing → Inserted)
- Idle menu bar icon `waveform.badge.microphone`
- Settings sidebar panes (General / Setup / Models / Storage) + Status header
- Whisper Base / Small / Turbo q5 (ggml) + Parakeet TDT 0.6B v3 + optional Apple SpeechAnalyzer
- Formatting: Off / Light / Smart / Smart+ / Gemma 4 E2B via session-scoped `CarrotTypeCleanupHelper`
- Escape cancel + soft silent cancel; Check for updates (opens Releases)

## Not yet

- Replace-selection / paste output mode for transform
- Dedicated Translate-only models
- In-app auto-update (Sparkle)
- Apple Developer ID notarization (optional; unsigned + Privacy & Security → Open Anyway is the supported install path)
