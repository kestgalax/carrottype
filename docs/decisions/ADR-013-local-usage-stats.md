# ADR-013: Local opt-in usage statistics

## Status

Accepted; amended 2026-11-11 for the native typing-speed calibration prototype.

## 2026-11-11 amendment — native typing-speed calibration

The maintainer approved a small native calibration sheet from Settings → Statistics
(«отлично, мне нравится, давай реализовывать»). It is an assistant for choosing the
existing estimate, not a new statistic or a replacement for manual input.

1. **Existing global baseline.** `carrottype.typingSpeedWPM`, the Stepper range
   (10–200, default 50) and manual editing stay unchanged. One global value is used
   for every month and both dictation languages; a test result never introduces a
   per-language or per-level baseline.
2. **Explicit Apply only.** A measured result writes the existing WPM setting only
   after the user presses «Использовать N WPM». Cancel, Close, Escape, Repeat,
   deactivation, sleep, Settings close, quit or install never write it. The
   collection toggle is not enabled or changed. The sheet explains that all period
   estimates are recalculated from stored aggregates while dictation counts do not
   change.
3. **No accuracy acceptance gate.** Accuracy is informational. A low-accuracy result
   inside 10–200 WPM can still be applied; an out-of-range result is shown honestly
   with an explanation and no silent clamp, and Apply is unavailable.
4. **RAM-only attempts.** The test text, keys, accuracy, language, level, date and
   result exist only for the open sheet/attempt. No seed, attempt or result is
   persisted, and the statistics store/API is not involved.
5. **Local-only scope.** Text comes from small original bundled RU/EN corpora with a
   seeded injectable PRNG; no WebView, network, model, microphone, Accessibility,
   clipboard, LLM, account, ranking or anti-bot system is added. The test does not
   require app Readiness or enabled collection.
6. **Operation boundary.** The test holds the existing `UpdateInstallationGate` only
   while it is actually running (not while Ready or showing a result), pauses only
   CarrotType global hotkeys by token while its input owns focus, and restores both
   idempotently on every exit. A real dictation/transform/maintenance/install
   operation wins; the test is dismissed without applying.
7. **Metric contract.** The first committed printable grapheme starts a fixed
   30-second monotonic deadline. Credited characters are fully correct words plus
   their typed separators plus the correct prefix of the current unfinished word;
   corrections never double count. `CPM = credited × 60 / 30`, `WPM = credited / 5 ×
   60 / 30`. Accuracy is correct committed-grapheme attempts divided by all
   committed-grapheme attempts, including corrected mistakes; Backspace, modifiers,
   navigation and marked IME text are not attempts. NFC extended graphemes preserve
   case and ё.

The native stack (ADR-002), opt-in aggregate storage, privacy/network boundary and
install gate (ADR-017) are unchanged. This amendment does not authorize a new
runtime, dependency, trust model, version or publication.

## Context

CarrotType’s product promise is local-first privacy (`.ai/constraints.md`, ADR-003). Users may still want a rough sense of time saved versus typing. Cloud analytics, crash SDKs, and any upload of usage events are forbidden.

The estimate is not a measurement of real typing speed. It is derived from inserted character counts, recording duration, and a user-visible WPM setting.

## Decision

1. **Opt-in, default off.** No daily buckets are written until the user enables collection in Settings.
2. **On-device only.** Persist aggregates under `~/Library/Application Support/carrottype/stats/`. Do not use a network sink. This is not telemetry.
3. **No transcripts, no audio.** Store per calendar day (local timezone): dictation character count, recording duration, completed dictation session count, and per-binding transform counts (`id` + `kind` + count). Do not store dictation text, selected text, custom instructions, audio, or hotkey chords.
4. **Dictation (clarified for 0.3.10):** record a completed dictation only after dispatching the caret-paste command without a known insertion error. CGEvent does not acknowledge actual insertion in the receiving app. UI labels these as completed dictations, not verified pastes. Cancel, silence, known insertion errors and STT failure are excluded. Existing aggregate data is retained; it was collected with the same dispatch-based mechanism and is not retroactively verified. Copy/recovery does not increment counts.
5. **Selection transform (ADR-012):** record only when the result is shown in the Capsule, keyed by binding `id` and `kind`. Copy from Capsule is not counted. Labels are resolved live from current bindings; deleted bindings stay as an orphan row.
6. **Estimates are computed at display time** from stored dictation counts + current WPM (default 50; 1 word = 5 characters including spaces). Transform stats are counts only — no typing-time estimate.
7. Turning collection off stops writes; existing buckets remain until the user clears them.

## Alternatives

- **On by default** — conflicts with explicit-over-magic and would look like silent tracking; rejected.
- **UserDefaults daily buckets** — fine for size, but mixes with settings and is harder to wipe as a file; rejected.
- **Per-session log / SQLite** — unnecessary for month totals in v1.
- **Upload / optional sync** — forbidden without a new ADR and product-intent change.

## Consequences

- New Settings pane **Statistics**; `UsageStatsStore` + estimate helper; duration exposed from `AudioRecorder.stop()`.
- Closed network sink list in `.ai/constraints.md` is unchanged.
- Feature spec: `docs/specs/features/local-usage-stats.md`.
