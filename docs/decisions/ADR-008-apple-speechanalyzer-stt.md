# ADR-008: Apple SpeechAnalyzer STT (optional)

## Status

Accepted

## Context

CarrotType already ships Whisper ggml (ADR-004) and Parakeet FluidAudio CoreML (ADR-006). Apple’s Speech framework on macOS 26+ adds `SpeechAnalyzer` / `SpeechTranscriber` with on-device models managed by `AssetInventory`, including Russian (`ru_RU`). Users on Tahoe should be able to try that runtime without replacing Whisper as the recommended default.

## Decision

1. **Runtime:** Speech framework `SpeechAnalyzer` + `SpeechTranscriber` (+ `AssetInventory` for locale assets). Catalog id: `stt.apple-speechanalyzer`, `runtimeHint: apple-speechanalyzer`.
2. **Optional only:** `recommended: false`. Catalog recommended STT is Parakeet (see `docs/stt-ru-en-quality-note.md`); SpeechAnalyzer stays opt-in.
3. **No HF download:** “Prepare” installs system speech assets for the mapped locale. Ready = macOS 26+ and assets installed (marker under Application Support after Prepare).
4. **Deployment target:** remains macOS 14; API calls gated with `#available(macOS 26, *)`. On older OS the catalog row is hidden.
5. **Locale:** map in-app language (`ru` → `ru_RU`, else `en_US`) via `SpeechTranscriber.supportedLocale(equivalentTo:)`; refuse clearly if unsupported.
6. **Privacy:** audio stays on-device (system Speech / AssetInventory). No new cloud STT sink. System may download Apple speech assets when the user taps Prepare.

## Consequences

- Tahoe users get a zero-HF STT option alongside Whisper/Parakeet.
- Asset size and availability are OS-managed; Delete releases the locale reservation and clears the local Ready marker (system may keep shared assets).
- Builds require an SDK that knows SpeechAnalyzer symbols (Xcode 26+); older OS binaries still run Whisper/Parakeet.

## Alternatives considered

- **Make SpeechAnalyzer recommended on macOS 26+:** deferred — quality gate and fallback story not proven.
- **Raise minimum OS to 26:** rejected — blocks current invite users on macOS 14/15.
- **SFSpeechRecognizer:** rejected for new work — SpeechAnalyzer is the current on-device path.
