# STT side-by-side quality note (RU / EN)

Purpose: decide whether to flip catalog `recommended` from Whisper Base to Parakeet (or Turbo) after a short manual pass.

## Setup

- Same mic, same room noise, Apple Silicon Mac.
- Cleanup: **Light** only (isolate STT quality).
- For each model: download → select → 3 short takes per phrase → note latency feel and text.

## Phrase checklist

### Russian

1. «Привет, это проверка диктовки КарротТайп.»
2. «Завтра в пятнадцать тридцать созвон с командой.»
3. «Отправь счёт на сумму две тысячи триста рублей.»
4. «Не забудь про дефис в слове веб-сайт и кавычки.»
5. «Короткий тест: раз, два, три — готово.»

### English

1. «Hello, this is a CarrotType dictation check.»
2. «Schedule a call tomorrow at three thirty.»
3. «Please send the invoice for two thousand dollars.»
4. «Don't forget the hyphen in web-site and the quotes.»
5. «Short test: one, two, three — done.»

## Log template

| Model | RU accuracy (1–5) | EN accuracy (1–5) | Latency feel | Peak RAM note | Comments |
|-------|-------------------|-------------------|--------------|---------------|----------|
| Whisper Base (ggml) | | | | | |
| Whisper Small (ggml) | | | | | |
| Whisper Turbo q5 (ggml) | | | | | |
| Parakeet TDT 0.6B v3 | | | | | |
| Apple SpeechAnalyzer (macOS 26+) | | | | | EN OK; RU system asset often fails to install |

## Result

- Date: 2026-07-24
- Machine (chip / RAM): maintainer decision (Apple Silicon)
- Winner for **RU default**: Parakeet TDT 0.6B v3
- Winner for **quality opt-in**: Whisper Turbo q5 (optional)
- Keep `recommended` as Whisper Base? **no** — new id: `stt.parakeet-tdt-0.6b-v3`
- Notes: Aligns with ADR-003 target default. Whisper Base remains a light optional download. Formal phrase-grid scores above can still be filled later for documentation; product `recommended` flipped by maintainer.

## Decision gate

Historical catalog through 0.3.10:

- `recommended: true` → `stt.parakeet-tdt-0.6b-v3`
- Whisper Base / Small / Turbo and Apple SpeechAnalyzer remain optional.

## Result — Ultra-only product decision (0.4.0)

- Date: 2026-11-09.
- Decision maker/evidence: maintainer explicitly requested only Parakeet Ultra for dictation after evaluating the usefulness of the alternatives. This is a user-directed product choice, not a claim that Ultra outperforms every other model on every input.
- Selected default and sole offered STT: `stt.parakeet-ultra` (ADR-016).
- Quantitative RU/EN scores, peak RAM and comparative latency: not supplied; none are invented. The previous 2026-07-24 results above remain historical evidence for the old default.
- 0.3.10 manual acceptance covers the prior release, not automatic acceptance of 0.4.0. The new Debug gate explicitly includes Ultra RU/EN, mixed language, numbers, pauses, live draft and migration from retired selections. Release remains blocked until that separate confirmation.

### Supplementary local synthetic smoke

Machine: Apple M1 Pro, 16 GB, macOS 27.2. Both models loaded from existing local caches using the pinned FluidAudio API; no microphone/user recordings. Fixtures were produced locally by `say` (Milena/Samantha), 16 kHz signed 16-bit WAV. Cleanup off, a fresh TdtDecoderState per file. Timings measure file transcription only, excluding model/ANE loading and compilation; one observation per phrase is not a performance benchmark.

| Fixture | Parakeet v3 | Ultra |
|---|---|---|
| RU: «Завтра в пятнадцать тридцать созвон с командой. Отправь счёт на сумму две тысячи триста рублей.» | «Завтра в 15.30 созван с командой. Отправь счет на сумму 2300 рублей.»; ~0.185 s | Same text; ~0.150 s |
| EN: “Schedule a call tomorrow at three thirty. Please send the invoice for two thousand dollars.” | “Schedule a call tomorrow at 3 30, please send the invoice for $2,000.”; ~0.108 s | “Schedule a call tomorrow at 3.30. Please send the invoice for $2,000.”; ~0.112 s |

Both preserved the content/numbers on these synthetic samples, with the same RU substitution «созван» for «созвон». No regression observed on this tiny sample; mixed language, noise, long sessions and live human speech still require the 0.4.0 manual gate. Temporary harness/results: `/tmp/carrottype-ultra-quality/` on the development machine.
