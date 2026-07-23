# ADR-007: Temporary mic unmute during dictation

## Status

Accepted (shipped experimental in v0.1.1; Wave:3 + Wave Link verified on feature branch)

## Context

Users often keep an external mic muted between dictation sessions (privacy, calls, ambient noise). Elgato Wave:3 exposes a capacitive mute that is software/DSP-driven via Wave Link, not a physical disconnect. CarrotType’s hotkey starts `AVAudioEngine` capture but does not clear mute, so muted hardware yields silent/too-short recordings.

There is no single macOS API that covers every vendor mute:

- Core Audio `kAudioDevicePropertyMute` (input scope) works for many devices and tools (MicCheck, Hushboard).
- Elgato Wave Link exposes an unofficial local WebSocket JSON-RPC used by the Stream Deck plugin (`setInputDevice` / `inputs[].isMuted`).
- Wave Link channel/mix mute is a third layer when recording virtual mixes.

Product principles require **explicit** opt-in and human control of when recording is live.

## Decision

1. Add an **optional, experimental** Settings toggle next to the input device picker: temporarily unmute for the dictation session (default **off**).
2. **Product support scope (UX):** Elgato Wave Link only. Settings copy must say the feature is experimental and requires Wave Link running. Do not advertise universal mute control.
3. On session start (when enabled): snapshot mute state → unmute if muted → record. On every exit path (stop, error, cancel, quit): **restore** the prior mute state (never “always remute”).
4. Backend (implementation detail, not UX promise):
   - Primary: if Wave Link is reachable **and** the selected input looks like Wave/Elgato/Wave Link → unmute via Wave Link `setInputDevice` on the `commonWave` hardware input.
   - Silent fallback: Core Audio mute on the selected device UID when settable (not promised in UI).
   - If neither works → proceed with recording as today; do not crash the session.
5. Do not keep `AVAudioEngine` awake solely for mute; mute is a HAL / Wave Link property change only (idle policy unchanged).
6. Wave Link protocol is unofficial and version-sensitive; treat failures as soft. Wave Link 3 rejects JSON-RPC `"params": null` — omit the key or send `{}`.

## Alternatives

- **Core Audio only** — simpler, but insufficient for Wave:3 LED mute; rejected as the product promise.
- **Wave Link only in code** — matches UX; Core Audio kept only as silent soft fallback.
- **Always unmute without a setting** — conflicts with “explicit over magic”.
- **Official Elgato SDK** — not available for third-party apps.

## Consequences

- New service `MicMuteController` + AppState session hooks + Settings/L10n.
- Users must leave Wave Link running for Wave:3 hardware mute control.
- Possible races with third-party mute enforcers (MicCheck, etc.).
- Verification notes: `docs/research-mic-unmute-spike.md`.
