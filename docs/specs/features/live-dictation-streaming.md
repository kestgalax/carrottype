# Live dictation draft (streaming STT)

## Metadata

- Feature ID: F-004
- Title: Live draft in Status Capsule via Parakeet SlidingWindow

## Traceability

- Product Intent Link: docs/product-intent.md
- Roadmap Item: Live dictation draft (v0.3.4 candidate)
- Related ADRs: docs/decisions/ADR-014-live-dictation-streaming.md, docs/decisions/ADR-006-parakeet-fluidaudio-stt.md
- UX Spec: docs/specs/ux-setup-status.md
- Quality phrases: docs/stt-ru-en-quality-note.md

## Problem

Users only see progress after stop. Interim text while speaking (without pasting into the target app) reduces uncertainty and matches expected dictation UX.

## Proposed Behavior

1. Settings → General → **Live draft in Status Capsule** (default **off**). Disabled with explanation when the active STT package has `supportsStreaming: false`.
2. Optional **Offline second pass after live draft** (default **off**): after stop, re-transcribe the session WAV with the same Parakeet `AsrModels`.
3. When live draft is on and the active model supports streaming: fan-out 16 kHz buffers into `ParakeetStreamingEngine`; Capsule shows confirmed + faded volatile tail (volatile replaced each update).
4. On stop: streaming `finish()` (or offline second pass) → cleanup → caret paste. WAV path unchanged as fallback / Whisper / Apple.
5. Streaming start/finish failures fall back silently to file STT and log.

## Acceptance Criteria

- Live draft off: behaviour matches pre-feature file path.
- Live draft on + Parakeet: interim text in Capsule; no paste until stop.
- Live draft on + Whisper/Apple: toggle unavailable; file path used.
- Escape / silent cancel: no paste; streaming cancelled.
- Catalog marks Parakeet v3/Ultra `supportsStreaming: true`, others false.

## Verification Plan

- Owner Mac: Debug build (this VM cannot compile the macOS app).
- Time to first word in Capsule; draft jitter; final quality vs offline Ultra on phrases from `docs/stt-ru-en-quality-note.md`.
- Memory: one model load (no v3+Ultra dual load).
- Fallback: force streaming failure → file path still pastes.
- Setting off → unchanged prior behaviour.

## Documentation Impact

- ADR-014; architecture; roadmap; ux-setup-status; catalog version 9.
