# Spike: temporary mic unmute for dictation

Branch: `feature/mic-unmute-on-dictation`  
Related: ADR-007, optional Settings toggle «Снимать mute на время диктовки».

## Goal

Confirm which mute layer must be cleared so CarrotType hears audio when the user keeps a mic muted between sessions (especially Elgato Wave:3).

## Layers under test

| Layer | API | Expected effect |
|-------|-----|-----------------|
| Core Audio HAL mute | `kAudioDevicePropertyMute` input scope | Silences capture for all apps on that device when settable |
| Wave Link hardware input mute | JSON-RPC `setInputDevice` → `inputs[].isMuted` | Matches Wave:3 capacitive mute / LED (when Wave Link is running) |
| Wave Link channel/mix mute | `setChannel` / mix mute | Only if CarrotType records a Wave Link virtual mix |

## Desktop checklist (Wave:3 + Wave Link, macOS)

Run with CarrotType built from this branch, Settings → enable the unmute toggle.

1. Mute Wave:3 (LED red). Note Core Audio mute vs Wave Link `getInputDevices` `isMuted` (Debug log / Instruments).
2. Unmute **only** via Core Audio — does `AVAudioEngine` / CarrotType meter hear audio?
3. Unmute **only** via Wave Link `setInputDevice` — does LED clear and does recording hear audio?
4. Repeat with input device = **Mic In (Wave:3)** vs **Wave Link Stream Mix**.
5. Abort mid-session (quit app while recording) — mic must return to prior muted state.

## Research conclusions (pre-hardware)

- No universal vendor API; Core Audio is the portable default.
- Wave:3 capacitive mute is owned by Wave Link / device DSP; Core Audio alone often **does not** clear the red LED.
- Wave Link exposes an unofficial local WebSocket JSON-RPC (Stream Deck plugin protocol). Ports: try `1824`, then `1884…1893`. Origin `streamdeck://`.
- Implementation therefore uses a **hybrid**: Wave Link when the selected input looks like Wave/Elgato **and** Wave Link answers; otherwise Core Audio. Always restore prior state.

## Status

- [x] Desk research + hybrid controller implemented on feature branch
- [x] Root cause on live Wave Link 3 (mac): `"params": null` → `-32602 Invalid params`; dead-port connect to 1824 skipped real server on **1884**. Fixed: omit `params` / prefer 1884–1893 + TCP probe + prefer `commonWave` hardware mute.
- [ ] Hardware verification on Wave:3 (manual; required before merge to main) — re-test LED unmute after rebuild
- [ ] Confirm Stream Mix path if that is the user’s default input
