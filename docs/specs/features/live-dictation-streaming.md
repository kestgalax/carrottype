# Live dictation draft (offline re-transcribe preview)

## Metadata

- Feature ID: F-004
- Title: Live draft in Status Capsule via full-buffer offline Parakeet (OpenBot-style)

## Traceability

- Product Intent Link: docs/product-intent.md
- Roadmap Item: Live dictation draft (v0.3.4); Escape cancel Copy capsule (v0.3.5)
- Related ADRs: docs/decisions/ADR-014-live-dictation-streaming.md, docs/decisions/ADR-006-parakeet-fluidaudio-stt.md
- UX Spec: docs/specs/ux-setup-status.md
- Design: docs/superpowers/specs/2026-10-27-live-draft-offline-preview-design.md
- Quality phrases: docs/stt-ru-en-quality-note.md

## Problem

Users only see progress after stop. Interim text while speaking (without pasting) should **adapt earlier words** as context grows — matching OpenBot local Parakeet UX — and remain readable for long utterances.

## Proposed Behavior

1. Settings → General → **Show text while you speak** (default **off**). Disabled when active STT `supportsStreaming` is false.
2. When on + Parakeet: fan-out 16 kHz buffers into `ParakeetStreamingEngine`; ~1 s single-flight **offline** re-transcribe of **all** samples so far; Capsule shows body + muted last 2 words; Capsule height grows with text (scroll after max).
3. On stop: cancel preview → session WAV file STT → cleanup → caret paste.
4. On Escape while recording: cancel preview and capture; **no paste**. If live draft was on and the preview was non-empty, show the snapshot in Copy / Close Capsule chrome (~5 s auto-dismiss; new dictation clears it).
5. Preview start/pass failures: log; paste path unchanged.

## Acceptance Criteria

- Live draft off: behaviour matches pre-feature file path.
- Live draft on + Parakeet: Capsule text appears while speaking and can rewrite earlier words as speech continues; no paste until stop.
- Long drafts: Capsule expands; content beyond max height scrolls.
- Live draft on + Whisper/Apple: toggle unavailable; file path used.
- Escape / silent cancel: no paste; preview cancelled. Escape with non-empty live draft: Copy capsule (no paste); soft empty cancel unchanged.
- Escape Copy capsule: 5 s auto-dismiss; Close / second Escape dismiss; starting dictation clears.
- Catalog: Parakeet v3/Ultra `supportsStreaming: true`, others false.

## Verification Plan

- Owner Mac Debug build.
- Compare Capsule coherence vs OpenBot on multi-clause RU phrases.
- Memory: one Parakeet load; no v3+Ultra dual load.
- Fallback: preview failure → file path still pastes.
- Setting off → unchanged prior behaviour.

## Documentation Impact

- ADR-014 (revised); architecture; roadmap; ux-setup-status; design + plan under `docs/superpowers/`.
