# Live dictation draft (offline re-transcribe preview)

## Metadata

- Feature ID: F-004
- Title: Live draft in Status Capsule via full-buffer offline Parakeet (OpenBot-style)

## Traceability

- Product Intent Link: docs/product-intent.md
- Roadmap Item: Live dictation draft (v0.3.4); Escape cancel Copy capsule (v0.3.5); recorder-first session start (v0.3.6)
- Related ADRs: docs/decisions/ADR-014-live-dictation-streaming.md, docs/decisions/ADR-006-parakeet-fluidaudio-stt.md
- UX Spec: docs/specs/ux-setup-status.md
- Design: docs/superpowers/specs/2026-10-27-live-draft-offline-preview-design.md
- Quality phrases: docs/stt-ru-en-quality-note.md

## Problem

Users only see progress after stop. Interim text while speaking (without pasting) should **adapt earlier words** as context grows — matching OpenBot local Parakeet UX — and remain readable for long utterances.

## Proposed Behavior

1. Settings → Dynamic Island → **Show text while you speak** (default **off**). The switch is visible but disabled outside the **Full capsule** mode; a missing/invalid island mode means Full. The effective preview is `full && saved switch && supportsStreaming`, captured at session start. Disabled when active STT `supportsStreaming` is false.
2. When on + Parakeet + Full: **start mic and session WAV before** Parakeet model load; load preview engine concurrently and attach 16 kHz fan-out when ready. ~1 s single-flight **offline** re-transcribe of **all** samples so far (post-attach buffers feed preview; WAV holds full utterance for paste); Capsule shows body + muted last 2 words; Capsule height grows with text (scroll after max).
3. On stop: cancel preview → session WAV file STT → cleanup → caret paste. This final path is unchanged in Minimal/Menu-only, which simply never start the preview.
4. On Escape while recording: cancel preview and capture; **no paste**. If live draft was on, Full mode, and the preview was non-empty, show the snapshot in Copy / Close Capsule chrome (~5 s auto-dismiss; new dictation clears it). Minimal/Menu-only compute no draft and show no Copy result.
5. Preview start/pass failures: log; recording and WAV paste path unchanged.
6. Cold load: words spoken before preview attach remain on the session WAV; Capsule preview may appear after load completes.

## Acceptance Criteria

- Live draft off: behaviour matches pre-feature file path.
- Live draft on + Parakeet + Full capsule: Capsule text appears while speaking and can rewrite earlier words as speech continues; no paste until stop.
- Minimal/Menu-bar-only: no preview pass is invoked at all; Escape has no draft Copy, while stop still transcribes the WAV and pastes.
- Long drafts: Capsule expands; content beyond max height scrolls.
- Live draft on + Whisper/Apple: toggle unavailable; file path used.
- Escape / silent cancel: no paste; preview cancelled. Escape with non-empty live draft in Full: Copy capsule (no paste); soft empty cancel unchanged.
- Escape Copy capsule: 5 s auto-dismiss; Close / second Escape dismiss; starting dictation clears.
- Catalog: Parakeet v3/Ultra `supportsStreaming: true`, others false.

## Verification Plan

- Owner Mac Debug build.
- Compare Capsule coherence vs OpenBot on multi-clause RU phrases.
- Memory: one Parakeet load; no v3+Ultra dual load.
- Fallback: preview failure → file path still pastes.
- Cold start: speak immediately after hotkey with live draft on — first words appear in final paste even if Capsule preview is still loading.
- Setting off → unchanged prior behaviour.

## Documentation Impact

- ADR-014 (revised); architecture; roadmap; ux-setup-status; design + plan under `docs/superpowers/`.
