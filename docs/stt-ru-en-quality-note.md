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

Catalog now keeps:

- `recommended: true` → `stt.parakeet-tdt-0.6b-v3`
- Whisper Base / Small / Turbo and Apple SpeechAnalyzer remain optional.
