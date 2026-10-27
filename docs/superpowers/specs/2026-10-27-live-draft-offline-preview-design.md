# Live draft offline preview + dynamic Capsule

Date: 2026-10-27  
Branch: `feat/live-dictation`  
Status: Approved (owner)

## Goal

Match OpenBot-style live dictation: Capsule text **re-adapts with full utterance context** while speaking, and Capsule **grows** so long drafts remain readable.

## Decisions

### A — Offline re-transcribe preview (replaces SlidingWindow for live)

1. While recording with live draft on + Parakeet: accumulate 16 kHz mono samples (fan-out from `AudioRecorder`).
2. ~1 s cadence, **single-flight**: skip tick if a pass is in progress.
3. Each pass: offline `AsrManager.transcribe` on a snapshot of **all** samples so far (full context → earlier words may change). Long audio uses FluidAudio’s sample/`URL` chunking as needed.
4. Capsule split is **cosmetic**: body normal, **last 2 words** muted (OpenBot `DICTATION_INTERIM_WORDS = 2`).
5. On stop: cancel preview; **final paste always from session WAV file STT** → cleanup → caret (unchanged reliability). Preview failures never block paste.
6. Remove SlidingWindow live path for Capsule (ADR-014 updated). Models: one Parakeet load (v3 or Ultra as selected).

### Dynamic Capsule

1. Drop fixed ~78 pt / `lineLimit(3)` for live draft.
2. Width ~320–420 (notch-aware). Height grows with text, panel grows **downward** from notch/menu bar.
3. Cap content height (~280 pt / ~12 lines); overflow → `ScrollView`.
4. Smooth size updates when draft text changes.

## Non-goals

- Mid-speech LLM cleanup
- Cloud streaming
- Changing default live-draft off / catalog `supportsStreaming`

## Traceability

- ADR-014, F-004, product intent (local paste loop + optional live draft)
- Reference: OpenBot local Parakeet via periodic full offline re-transcribe + last-2-words interim UI
