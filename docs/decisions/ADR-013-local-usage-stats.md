# ADR-013: Local opt-in usage statistics

## Status

Accepted

## Context

CarrotType’s product promise is local-first privacy (`.ai/constraints.md`, ADR-003). Users may still want a rough sense of time saved versus typing. Cloud analytics, crash SDKs, and any upload of usage events are forbidden.

The estimate is not a measurement of real typing speed. It is derived from inserted character counts, recording duration, and a user-visible WPM setting.

## Decision

1. **Opt-in, default off.** No daily buckets are written until the user enables collection in Settings.
2. **On-device only.** Persist aggregates under `~/Library/Application Support/carrottype/stats/`. Do not use a network sink. This is not telemetry.
3. **No transcripts, no audio.** Store per calendar day (local timezone): dictation character count, recording duration, successful dictation session count, and per-binding transform counts (`id` + `kind` + count). Do not store dictation text, selected text, custom instructions, audio, or hotkey chords.
4. **Dictation:** record only successful caret paste. Cancel, silence, and STT/cleanup failure are out of scope.
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
