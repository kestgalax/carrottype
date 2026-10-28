# ADR-014: Live Dictation Draft via Offline Re-transcribe Preview

## Status

Accepted (revised 2026-10-27 — OpenBot-style full-buffer preview)

## Context

Users want interim text in the Status Capsule while speaking, without pasting until stop. Cloud realtime STT conflicts with local-first privacy. The first implementation used FluidAudio `SlidingWindowAsrManager` with short windows for latency; that path did **not** rewrite earlier words with growing context, so Capsule drafts stayed choppy compared with OpenBot’s local Parakeet UX.

OpenBot (local Parakeet TDT v3 via sherpa-onnx) re-transcribes the **entire** accumulated recording about once per second (single-flight) and fades only the last two words in the UI. That is the behaviour owners expect.

## Decision

1. **Engine path:** `StreamingSTTEngine` + `ParakeetStreamingEngine` load the same FluidAudio `AsrModels` / package id as offline Parakeet. Live draft **accumulates 16 kHz samples** from the recorder fan-out and, about every **1 s** (skip while a pass is running), runs **offline** `AsrManager.transcribe` on a snapshot of **all** samples so far.
2. **Capability flag:** Catalog `supportsStreaming` (v3 + Ultra `true`; Whisper + Apple `false`). Live draft only when the active package supports it **and** Settings → **Show text while you speak** is on (default **off**).
3. **Capture:** WAV write stays intact. Converted 16 kHz buffers also feed the preview engine. File STT remains the paste path and the only path for non-streaming engines.
4. **Session start (v0.3.6):** When live draft is requested, **mic capture and session WAV start before** awaiting Parakeet model load. The preview engine loads concurrently; `onConvertedBuffer` attaches when ready. Speech during cold load is still on the WAV (final paste unchanged). Preview may lag until attach; load failure → file-only path while recording continues. Escape/stop cancels in-flight load as today.
5. **Stop:** Cancel preview; **always** transcribe the session WAV with offline STT → cleanup → caret paste. Preview failures never block paste.
6. **UI:** Capsule shows draft body at normal opacity and the **last two words** muted (cosmetic interim, OpenBot-style). Capsule **grows with text** (down from notch/menu bar), with a max body height and scroll beyond that.
7. **Escape cancel (v0.3.5):** While recording with live draft on + non-empty preview, **Escape** still cancels capture (no WAV STT, no caret paste). The last preview snapshot stays in the Capsule as **Copy / Close** result chrome (same interaction model as transform results, ADR-012). Capsule auto-dismisses after **5 s**; Escape or Close dismisses sooner. Starting a new dictation dismisses the snapshot. Empty draft or live draft off: Escape behaves as before (immediate hide, no Copy capsule).
8. **Language:** Pass in-app effective language (`ru` / `en`) into FluidAudio `Language` when transcribing.
9. **SlidingWindow** is **not** used for live Capsule preview (kept available in FluidAudio for other uses / research only).

## Consequences

- Live draft CPU cost ≈ one offline Parakeet pass per second while speaking (single-flight).
- One Parakeet model load (selected v3 or Ultra); no dual v3+Ultra.
- Capsule draft quality tracks full-utterance context; final paste quality matches the existing file path.
- “Offline second pass” Settings control removed from General (final path is always WAV STT).

## Alternatives considered

- **SlidingWindow short windows:** fast first token, weak whole-utterance coherence — rejected for Capsule after owner comparison with OpenBot.
- **Mid-speech LLM cleanup:** deferred — not how OpenBot/Grok STT public paths work; needs a separate ADR if productized.
- **Cloud realtime (ElevenLabs / xAI / etc.):** rejected for MVP — closed network sinks / product intent.
- **True FluidAudio EOU / Nemotron streaming:** EN-oriented; not chosen for RU/EN default path.
