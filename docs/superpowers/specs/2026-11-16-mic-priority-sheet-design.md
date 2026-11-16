# Microphone priority sheet (Dictation) — design

2026-11-16. Maintainer approved mockup variant **A** («да, мне нравится»). Implemented on
`feat/smart-mic-priority`; included in the 0.12.0 (37) release preparation (not yet published).

## Mockups

- Compact Dictation row: [docs/mockups/mic-priority-mockup-a-dictation.jpg](../../mockups/mic-priority-mockup-a-dictation.jpg)
- Editor sheet: [docs/mockups/mic-priority-mockup-a-sheet.jpg](../../mockups/mic-priority-mockup-a-sheet.jpg)

## Goal

Keep microphone failover editable, but stop the full priority list from dominating **Settings → Dictation**. Ordering is rare; the main pane should show only the active device plus an entry point.

## Non-goals

- No change to failover / Wave Link usability rules.
- No mid-dictation device switch.
- No new sidebar pane.
- Menu-bar quick-select stays (promote-to-front).

## UX

### Dictation (main Form)

After the hotkey section, a compact section **Приоритет микрофонов**:

| Element | Behavior |
|---|---|
| Label | «Активный микрофон» (or equivalent L10n) |
| Value | Resolved active device name; secondary/empty copy if none / mic not granted |
| Button | **«Настроить…»** opens the sheet |

If microphone TCC is not granted: hide the editor button or disable it with a short hint to grant access in Setup (same gate as today). Do not dump the full list inline.

Formatting rules section follows immediately under this compact block.

### Sheet

Native SwiftUI `.sheet` attached to Settings (same family as Statistics → typing-speed test):

- Title: **Приоритет микрофонов**
- Caption: existing failover hint (usable / Wave Link / mid-session freeze)
- Full reorder list (name, Active / Unavailable / system default) with native `List` drag reorder via
  `onMove`; inaccessible devices are still listed so they can be reordered or promoted
- Trailing **Готово** dismisses (or standard close); edits apply live as today — no separate Save

Suggested size: ~520×420 pt (fit list + caption without stretching the whole Settings window).

## Behavior

- Opening the sheet refreshes devices once.
- Reorder / promote semantics unchanged (`AudioInputService`).
- Closing Settings dismisses the sheet (same pattern as typing-speed sheet if needed).
- Focus/LSUIElement work already in flight stays independent.

## Files (likely)

- `DictationSettingsPane.swift` — compact row + sheet presentation
- Shared list UI currently in `SetupSettingsPane.swift` (`MicrophonePrioritySettingsSection` / `AudioInputPriorityRow`) — reuse inside sheet
- `Localizable.xcstrings` — compact row / button strings
- `docs/specs/ux-setup-status.md` — Dictation bullet

## Acceptance

- [x] Dictation no longer shows the full priority list inline
- [x] Active mic name + **Настроить…** visible when mic granted
- [x] Sheet shows full ordered list with existing statuses and reorder
- [x] Failover / migration / menu promote unchanged
- [x] Debug build for manual click-through (`dist/debug-smart-mic-priority/CarrotType.app`)

## Out of scope for this change

- Further focus/TCC polish beyond what already landed on the branch
- Publication to stable/latest; 0.12.0 (37) packaging and the Motion film are separate
  release-preparation steps.
