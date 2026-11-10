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
2. Same hotkey stops recording: **press again** in toggle mode (default), or **release** when Walkie-talkie is on in Settings (hold-to-talk only). The modes are mutually exclusive; same dictation shortcut either way.
3. On-device STT (Parakeet Ultra only from 0.4.0; explicit download, existing installed Ultra reused) produces text. Optional live draft (ADR-014) may show adapting interim text in the Status Capsule while speaking (periodic full-buffer Parakeet preview); mic and session WAV start immediately even while Parakeet loads (v0.3.6); paste still happens only after stop via the WAV. Escape cancel with non-empty preview can offer Copy from the Capsule without pasting (v0.3.5).
4. Optional cleanup / post-dictation formatting (Light heuristics, Qwen3 0.6B or Gemma) formats text without rewriting meaning.
5. Text is inserted at the current caret in the frontmost app.
6. Optional: keep the result on the clipboard after paste so ⌘V still works if focus moved. Starting with 0.3.10, the last completed non-empty dictation is also available to Copy from RAM until replaced, explicitly cleared, or app exit; no transcript history is written to disk. A dispatched paste is not a verified insertion in the receiving app.
7. UI language follows the system (RU/EN) with an in-app override.

**Secondary loop** (ADR-012): transform **bindings** (hotkey + Translate with a user language pair, or Custom instruction + model) read the current text selection, run an on-device LLM, and show the result in the Status Capsule (Copy / Close, optional direction) without replacing the selection. Fresh default: Translate on ⌥' with pair ru↔en. Uses the same local cleanup packages as Smart formatting; does not require formatting to be active for dictation.

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

## Setup trial (0.6.0)

Setup guides microphone → Accessibility → Ultra → an optional local trial. Ready still uses the existing permissions/model requirements. The trial is explicitly started/stopped/cancelled by the user, runs on-device, and delivers its final text in Settings rather than at an external caret. It does not automatically change clipboard, Last Dictation or usage statistics. Only completion Boolean persists; trial text stays in RAM. Ordinary dictation and selection transforms retain their existing behavior.

## Application updates (0.5.0, ADR-017)

Manual in-app checks and opt-in automatic checks/downloads use signed GitHub Release assets. Dictation remains local and independent of update availability. Installation waits for active dictation/text processing, preserves external model/settings/statistics storage, and does not force a background restart. No profiling or transcript upload. The first updater-enabled installation is manual; notarization remains separate.

## Current product status (2026-11)

**v0.7.0** native settings/accessibility/confirmation polish, General formatting access and selected carrot-microphone A brand; published after signed Debug review and explicit authorization, retaining all useful functions and local/update trust boundaries. **v0.6.2** coordinated session lifecycle, awaited teardown and generation-safe live draft; released after Debug delivery and explicit publication authorization. **v0.6.1** offline What’s New and structured localized signed update notes, released after its own Debug acceptance. **v0.6.0** guided setup/local trial, compact transform bindings and actual formatting feedback. **v0.5.0** signed native GitHub app updates with opt-in checks/downloads and installation deferred until active work ends (ADR-017), published after Debug delivery and explicit authorization. **v0.4.0** Ultra-only STT, explicit migration and optional confirmed legacy-model cleanup (ADR-016), released after separate Debug acceptance. **v0.3.10** last dictation recovery in RAM, ownership-aware clipboard restore, visible operation errors and bounded cleanup helper IPC; Debug manually accepted before release. **v0.3.8** Storage Settings: installed packages inventory plus catalog-scoped Hugging Face download cache clear. **v0.3.7** Secure Coding hardening (ADR-015): helper model-path jail, MLX Hub `hubRevision` pins, clipboard restore/copy honesty; notarization still optional prep only. **v0.3.6** live draft starts recording before Parakeet model load so speech during cold start is not lost; Capsule preview attaches when ready; final paste unchanged. **v0.3.5** Escape cancel during live draft with non-empty preview keeps a **Copy / Close** Capsule snapshot (no caret paste); normal stop unchanged. **v0.3.4** adds optional **live draft** in the Status Capsule (ADR-014): while speaking with Parakeet, the Capsule shows an adapting preview (full-buffer offline re-transcribe); paste still only after stop via the session WAV. Default off. **v0.3.3** added optional **Parakeet Ultra** beside Parakeet TDT 0.6B v3; the default download for a new install stays v3. **v0.3.2** adds a month **character** total next to successful dictations in Settings → Statistics, and moves typing speed (WPM) above Bindings. **v0.3.1** is a packaging patch: the unsigned DMG install window no longer shows `.background` / `.fseventsd`. **v0.3.0** ships **local opt-in usage statistics** (ADR-013). Also includes Walkie-talkie, Selection Transform (ADR-012), optional Gemma cleanup (ADR-010), Status Capsule chrome, OOP cleanup helper (ADR-009). Since **0.4.0**, Ultra is the sole offered/default STT (ADR-016); old weights are retained for explicit optional cleanup. Distribution posture (ADR-011): **MIT** source; repository **may be public**; notarization is optional later.

## Dictation preferences — 0.8.0

Optional local rules guide filler/repetition/self-correction handling, paragraphs and term spelling without turning dictation into translation or answering questions. The base instruction preserves meaning/language/numbers/negations; model compliance is not guaranteed. General exposes a text-only local trial and honest Light fallback when formatting fails. Rules apply to the next session and remain separate from Translate/Custom. Existing Smart+ users/bindings retain compatibility; new choices are Qwen3 0.6B/Gemma. Independent System/Light/Dark theme defaults to System, matching language's system-first approach. No transcript persistence or model/default STT change.

Explicit presentation/word/tone preferences override generic cleanup defaults. A requested tone may change wording while retaining content and intent; without such a request the cleanup stays literal. Free-text preferences are model guidance, not guaranteed executable rules. Trial feedback must name the actual applied mode and make rejected model output/Light fallback clear.
