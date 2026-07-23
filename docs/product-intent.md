# Product Intent

## Context

Typing is slow for many tasks; cloud STT tools send audio off-device. Existing open-source tools (e.g. voice dictation apps) show demand for local push-to-talk, but this project starts from a narrower goal: one reliable caret paste loop on macOS, not a voice studio.

## Mission

Turn speech into text at the caret with one hotkey — fully local, private, and fast.

## Vision

Anyone can speak into any macOS app and get accurate text without leaving the keyboard flow or sending audio to the cloud.

## Intent

Build a macOS background / menu-bar app whose primary loop is:

1. Global hotkey starts recording.
2. Same or release hotkey stops recording.
3. On-device STT (default Parakeet TDT v3; user-selectable catalog) produces text.
4. Optional cleanup / post-dictation formatting (Light heuristics or Qwen3 Smart) formats text without rewriting meaning.
5. Text is inserted at the current caret in the frontmost app.
6. Optional: keep the result on the clipboard after paste so ⌘V still works if focus moved.
7. UI language follows the system (RU/EN) with an in-app override.

Prefer a small, dependable MVP over feature breadth. Inspiration from products like TypeWhisper / Voicebox is allowed for UX direction only — no code or branding copying.

## Principles

- Local-first privacy
- Minimal friction (hotkey → paste)
- Explicit over magic
- Human control of when recording starts/stops

## Non-Goals

- Not a voice studio or voice-cloning product
- Not a cloud-first SaaS
- Not multi-platform in MVP
- Not a full IDE/plugin ecosystem

## Trade-Offs

```text
Latency & reliability of the hotkey→paste loop > Feature breadth
Local privacy > Cloud convenience
Maintainability of a small app shell > Premature multi-platform abstraction
```

## Success Criteria

- Hotkey can start/stop capture without focusing a dedicated UI.
- Transcription runs fully on-device for the chosen model path.
- Resulting text is inserted at the caret of the frontmost app.
- Audio is not uploaded by default.
- First successful end-to-end carrottype session is documented and reproducible.
- Setup UI makes readiness, active STT, and formatting mode obvious without rebuilding the app.

## Current product status (2026-07)

**v0.1.1** ships as an unsigned DMG on a **private** GitHub Release (invite-only early access). Next: decide default STT via `docs/stt-ru-en-quality-note.md`, then notarization after Apple Developer ID before any public download.
