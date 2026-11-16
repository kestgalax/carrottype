# Smart microphone priority / failover

2026-11-16. Coordinator-approved plan, implemented by the OpenCode worker on
`feat/smart-mic-priority`. The maintainer accepted the working behavior («отлично, теперь все
работает») and authorized **release preparation** for 0.12.0 (37) — version metadata, notes, PR
and a Motion companion. Publication (DMG/Release assets, stable/latest) is still a separate gate.

## Metadata

- Task ID: smart-mic-priority
- Status: implemented, accepted by maintainer, in 0.12.0 (37) release preparation; not published.
- Branch: `feat/smart-mic-priority` from `main` (`027dd52`, published 0.11.1).
- Roles: Codex/coordinator design and review; OpenCode implementation.

## Problem

CarrotType remembers exactly one microphone (`carrottype.selectedAudioInputID`). If that
microphone is disconnected — a USB interface, a docked headset, a Wave:3 — the app silently
falls back to the system default or to the first discovered device, and the saved preference is
lost. There is no way to say “use the Wave:3, otherwise the MacBook mic”, and a device that
comes back later is never preferred again.

The capture contract itself is already per-session: `DictationSessionSettings.deviceUID` is
captured at dictation start and used by the recorder, live-draft engine and Wave Link mute
controller. Smart failover must not weaken that.

## Goals

1. An ordered **priority UID list** (`carrottype.audioInputPriorityUIDs`) replaces the single-mic
   mental model.
2. Active input = the first UID in that list that is currently connected.
3. Unavailable UIDs stay in the list so reconnecting restores the preferred microphone.
4. Existing `carrottype.selectedAudioInputID` migrates to a one-element initial priority list;
   the resolved active UID keeps being written back to that key for compatibility.
5. A Core Audio hot-plug / default-input listener refreshes the device list and re-resolves the
   active input while the app is idle.
6. **Never switch microphones mid-recording.** The session device UID is frozen at dictation
   start; hot-plug resolution is suspended for the whole session.
7. Dictation shows a compact active-microphone row whose **Настроить…** button opens a native sheet
   with the ordered priority list, a one-line RU/EN explanation and drag reorder; Setup shows the
   same compact row before the model/trial steps.
8. Menu quick-select **promotes** the chosen microphone to the front of the priority list.
9. The optional mic meter and the experimental Wave Link unmute keep using the resolved/session
   device (ADR-007 unchanged).

## Non-goals

- No new STT/cleanup engine, runtime stack, dependency or distribution channel.
- No change to the system-default-input contract: recording still sets the macOS default input to
  the frozen session device (`AudioRecorder.start`), exactly as before, so an ADR is not required.
- No per-app or per-site microphone rules, no automatic gain/mute policy, no transcript or device
  history persistence beyond local device names for display.
- No keyboard shortcut or global toggle for failover; priority is a Setup/menu preference.
- No claim that hot-plug behavior was verified on real hardware in CI.

## Data model

`AudioInputPriorityList` (pure Swift, `AudioInputPriority.swift`):

- `uids: [String]` — ordered, normalized (trimmed, no empties, no duplicates, order preserved).
- `load(defaults:)` — reads `carrottype.audioInputPriorityUIDs`; when the key is absent, migrates
  `carrottype.selectedAudioInputID` into a one-element list. A stored empty array is an explicit
  “no preference” and is not re-migrated.
- `resolveActiveUID(discoveredUIDs:systemDefaultUID:)`:
  1. first preferred UID that is connected,
  2. else the current macOS default input when connected,
  3. else the first discovered device,
  4. else `nil` (no microphone).
- The list is never pruned or extended by fallback resolution. If no preference is stored at all,
  the resolved default is seeded once so the first entry always matches the active input; connected
  devices that are not listed appear after the preferred ones (and last in the menu) and can be
  promoted explicitly.

`AudioInputService` keeps `selectedAudioInputID` as the resolved active UID (same key as before)
and mirrors the device names of the current list in memory only, for readable rows.

## Behavior

### Idle resolution

`refreshDevices()` always refreshes the published device list, then — unless auto-switch is
suspended — resolves the active UID and writes `carrottype.selectedAudioInputID`. An empty
preference is seeded once with the resolved device, so “first entry wins” always matches the UI;
later fallbacks are used without being added to the list. The menu, Setup rows, meter and next
dictation all use that single resolved value.

### Session freeze

`AppState.sessionPhaseChanged` suspends auto-switch on `.starting` and resumes on `.idle`.
`DictationSessionSettings.deviceUID/deviceName` were already captured before `.starting`, so the
recorder, live draft and Wave Link unmute use the frozen device for the whole session. A
hot-plug event during capture may update the Setup availability list but cannot change the active
UID; the newly resolved preference applies to the next session.

### Hot-plug listener

A small `AudioInputDeviceListener` registers `AudioObjectAddPropertyListenerBlock` for
`kAudioHardwarePropertyDevices` and `kAudioHardwarePropertyDefaultInputDevice`, coalesces bursts
(250 ms) and calls `refreshDevices()` on the main actor. Listeners are removed in `deinit`.
No polling, no new permission, no network.

### Setup / Dictation UI

Dictation and Setup share `MicrophonePrioritySettingsSection`: a compact **Microphone priority**
section showing the active microphone name and a **Настроить…** button (only when microphone access
is granted and devices exist; otherwise a short hint or “no devices”). Setup places it before the
model/trial steps and does not repeat the full list.

**Настроить…** opens `MicrophonePrioritySheet`, a native Settings `.sheet` (~520×420) attached to
the pane:

- one row per priority entry: order, mic glyph, name, badges for active/default/unavailable;
- native `List` + `onMove` drag reorder of the displayed list (including devices that are not
  preferred yet, which materializes them into the saved order); accessibility hint explains drag;
- a caption explains RU/EN: the first usable microphone in the list is used, disconnected ones stay
  for reconnect, and dictation never switches device mid-session;
- **Готово** dismisses; edits apply live, no separate Save.

The meter toggle, unmute toggle and their hints remain in the Setup permissions section unchanged.
The old single-device picker is removed; the same selection action is available from the menu.
Mockups/design: [sheet design](../../superpowers/specs/2026-11-16-mic-priority-sheet-design.md).

### Menu

The microphone picker lists connected devices. Choosing one promotes it to the front of the
priority list (and restarts the meter when it is on). The menu title keeps showing the resolved
active microphone.

## Traceability

- Product Intent Link: `docs/product-intent.md` — dependable hotkey → caret loop, explicit control.
- Roadmap Item: `docs/roadmap.md` — smart mic priority implementation entry.
- Feature Spec: `docs/specs/ux-setup-status.md` (Setup microphone section).
- Related ADRs: ADR-002 (native stack), ADR-007 (temporary unmute is per session device),
  ADR-014 (session/device snapshot), no new ADR.

## Likely files

- `macos/CarrotType/Services/AudioInputPriority.swift` (new, pure)
- `macos/CarrotType/Services/AudioInputService.swift`
- `macos/CarrotType/AppState.swift`
- `macos/CarrotType/Views/Settings/SetupSettingsPane.swift`
- `macos/CarrotType/Views/Settings/DictationSettingsPane.swift`
- `macos/CarrotType/Views/MenuBarViews.swift`
- `macos/CarrotType/Resources/Localizable.xcstrings`
- `scripts/verify-smart-mic-priority.sh`, `scripts/tests/AudioInputPriorityChecks.swift`
- `.github/workflows/macos.yml`
- Docs: this spec, `docs/roadmap.md`, `docs/specs/ux-setup-status.md`

## Acceptance criteria

- [x] Ordered priority list is the source of truth; active = first **usable** preferred UID.
- [x] Unavailable / unusable UIDs are retained across refreshes and app relaunches; fallback
  resolution never appends or prunes entries, and an empty list is seeded once with a first-run
  friendly usable device (built-in preferred over Wave Link virtual / Continuity / system default).
- [x] Legacy single selection migrates exactly once to an initial one-entry list; absent, invalid
  and duplicate values normalize safely; `selectedAudioInputID` still holds the resolved UID.
- [x] Hot-plug/default-input changes refresh the list and re-resolve only while idle.
- [x] No resolution or microphone change can happen between dictation start and teardown; the
  session uses the UID captured at start.
- [x] Wave Link virtual mixes count as usable only while physical Wave hardware is present, and the
  menu hides orphan virtual endpoints.
- [x] Dictation and Setup show a compact active-microphone row; the full reorderable RU/EN priority
  list with availability/active state lives in a native sheet with drag reorder. The meter still
  follows the resolved device.
- [x] Settings regains focus after the microphone permission sheet while it is open, and returns to
  menu-bar-only activation when it closes.
- [x] Menu selection promotes to the front instead of replacing a single value.
- [x] Wave Link unmute keeps receiving the session device UID/name (ADR-007 unchanged).
- [x] No new ADR: capture graph, system-default-input behavior, engines, dependencies, network
  sinks and distribution are unchanged.

## Verification

- `scripts/verify-smart-mic-priority.sh` — normalization, migration (legacy/absent/existing/empty/
  duplicates), resolution (preferred available, skip disconnected, system-default fallback,
  discovery fallback, none), retention of unavailable UIDs, promote, bounded move, defaults
  round-trip, Wave Link virtual/hardware usability, first-seed preference and the unusable
  system-default case. No hardware, models or permissions.
- `scripts/verify-release-notes.sh` — 0.12.0 (37) metadata and contiguous 37→27 history.
- Debug arm64 build of the app target.
- Existing regression scripts and local governance where available.
- Real hot-plug, sheet drag by mouse, menu and VoiceOver behavior remain a manual Debug check:
  connecting/disconnecting a USB microphone while idle and during dictation is not covered by CI.
  The TCC focus restore is best-effort over six bounded retries and is not proven on every macOS
  permission flow.

## Residual risks

- Core Audio property listeners can fire in bursts or be missed across sleep/wake; the 250 ms
  coalescing and the next explicit refresh (Settings/menu appearance, recording start) bound the
  impact. No polling fallback is added.
- Device names for disconnected microphones are cached locally; a renamed or replaced device with
  the same UID shows the remembered name until it reconnects.
- The priority list can accumulate stale UIDs. There is no automatic pruning (by design, for
  reconnect); a future explicit “remove from list” action would need its own UX decision.
- Wave Link usability and the first-run seed are heuristic: virtual endpoints are recognised by
  transport type plus name/manufacturer text, so a renamed third-party mix could be classified
  differently. The list can be reordered manually, which is the escape hatch.
- A failed system-default switch is still reported through the existing recorder error path; smart
  failover does not add a retry.
