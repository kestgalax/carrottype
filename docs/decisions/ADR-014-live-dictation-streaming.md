# ADR-014: Live Dictation Draft via FluidAudio SlidingWindow

## Status

Accepted

## Context

CarrotType records 16 kHz mono WAV chunks (~85–90 ms) and transcribes the whole file after stop (`DictationPipeline` → `STTEngine.transcribe`). Users want interim text while speaking (Status Capsule), without pasting into the frontmost app until stop. Cloud realtime STT conflicts with local-first privacy. FluidAudio **0.17.7** (already pinned, ADR-006) ships `SlidingWindowAsrManager` with `volatileTranscript` / `confirmedTranscript`, `.streaming` config, `Language` hints, and `AsrModels` reference sharing for v3 and Ultra.

## Decision

1. **Engine path:** Add `StreamingSTTEngine` (`start` / `feed` / `finish` / `cancel` / `unload`) and `ParakeetStreamingEngine` on `SlidingWindowAsrManager(config: .streaming.applying(language:))`. Same package id → `ParakeetSTTEngine.PackageKind` / `fluidCacheDirectory` as offline Parakeet.
2. **Capability flag:** Catalog field `supportsStreaming` (v3 + Ultra `true`; Whisper + Apple SpeechAnalyzer `false`). Live draft runs only when the active package supports streaming **and** Settings → **Live draft** is on (default **off**).
3. **Capture fan-out:** Keep WAV write intact. `AudioRecorder` also emits converted 16 kHz buffers for streaming (copy before fan-out). File path remains the fallback and the only path for non-streaming engines.
4. **Stop behaviour:** Prefer streaming `finish()` → existing cleanup → caret paste. Optional **Offline second pass** (default off) re-runs offline STT on the same WAV using the already-loaded `AsrModels` (`MLModel` refs), then cleanup/paste.
5. **Failure:** If streaming fails to start or `finish()` errors, fall back silently to file STT and log (`NSLog`).
6. **UI:** Capsule shows confirmed text at normal opacity and the volatile tail faded; each update **replaces** the volatile segment. No caret insertion while recording.
7. **Language:** Pass the in-app effective language code (`ru` / `en`) into FluidAudio `Language` for script-aware filtering, consistent with Settings language.

## Consequences

- No new SPM dependency or cloud sink.
- Parakeet sessions may load CoreML slightly earlier (before/at record start) when live draft is on.
- Whisper / Apple SpeechAnalyzer users see the live-draft toggle disabled with an unavailable footer.
- Sliding-window ASR is pseudo-streaming (overlapping windows); draft quality and latency must be validated on device (see roadmap / PR checklist).

## Alternatives considered

- **Apple SpeechAnalyzer volatile stream:** deferred — current integration is file-based (`finishAfterFile`); RU asset install remains fragile (ADR-008).
- **True FluidAudio EOU / Nemotron streaming:** EN-oriented in 0.17.7; not chosen for RU/EN product path.
- **Cloud realtime (ElevenLabs / Soniox / etc.):** rejected for MVP — violates closed network sinks without a new product-intent + ADR.
- **Always dual-load v3 draft + Ultra final:** rejected — doubles disk/RAM; Ultra alone on both passes is preferred when the user selected Ultra.
