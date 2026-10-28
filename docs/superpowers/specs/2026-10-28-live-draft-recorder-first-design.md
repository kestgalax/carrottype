# Live draft: recorder-first start (no eaten words)

Date: 2026-10-28  
Branch: `feat/live-draft-recorder-first`  
Status: Approved (owner)  
Ship target: **v0.3.6** mini-patch

## Goal

When live draft is on, pressing the dictation hotkey must start **capturing audio immediately**. Parakeet CoreML load must not block `recorder.start()`, so speech during model warm-up is still on the session WAV (and available for final paste). Capsule preview may appear a moment later once streaming is ready.

## Problem

Today `startDictationSession` awaits `pipeline.startLiveDraftIfPossible` (AsrModels.load + loadModels) **before** `recorder.start()`. Cold load can take hundreds of ms to seconds; words spoken in that window are lost from both WAV and live draft.

## Behavior

1. Optional Wave Link unmute — **unchanged** (still awaited before record; out of scope).
2. If live draft requested (enabled + streaming STT): do **not** await model load before mic.
3. `recorder.start()` as soon as possible → `menuBarMode = .recording`, Capsule `.listening`, Escape armed.
4. Start live-draft engine **concurrently** (Task / unstructured async after mic is up).
5. When `startLiveDraftIfPossible` succeeds: set `recorder.onConvertedBuffer` to feed the streaming engine. Samples already written to the WAV file remain for final STT; only post-attach buffers feed the Capsule preview.
6. If live-draft start fails: log + file-only path (current behavior); keep recording.
7. Escape / soft cancel / normal stop while load is in flight: cancel the load task and `cancelLiveDraft`; no paste on Escape (incl. existing liveDraftResult path); normal stop still WAV → cleanup → paste.
8. Live draft **off**: unchanged (mic start without streaming load).

## Non-goals

- Keeping Parakeet warm across sessions / preload on Settings toggle
- Parallelizing or removing Wave Link unmute await
- Changing preview cadence, Capsule UI, or paste pipeline semantics

## Implementation sketch

- `AppState.startDictationSession`: reorder — start recorder + listening chrome first; spawn load task; wire `onConvertedBuffer` only after `isLiveDraftActive`.
- Hold a cancellable `Task` for live-draft startup; cancel it from `cancelDictationSession` / error paths / `finishDictationSession` teardown as needed.
- Docs: short note in ADR-014 / F-004; roadmap + release notes v0.3.6.

## Traceability

- ADR-014 live draft; product paste loop reliability (WAV is source of truth on stop)
- Follow-up to owner report: hotkey lag / eaten first words with live draft on
