# Local usage statistics (time saved)

## Metadata

- Feature ID: F-003
- Title: Local opt-in time-saved statistics

## Traceability

- Product Intent Link: docs/product-intent.md
- Roadmap Item: Local usage statistics (near-term; not a notarization substitute)
- Related ADRs: docs/decisions/ADR-013-local-usage-stats.md
- UX Spec: docs/specs/ux-setup-status.md

## Problem

Users want a private, local sense of how much typing time dictation replaced, without sending usage data off-device.

## Proposed Behavior

1. Settings → **Statistics**. Collection is **off** by default.
2. When on, each successful dictation paste appends to a daily bucket: inserted character count + recording duration + one session. No transcript. Cancel, silence, and failed STT do not increment the session count.
3. When on, each successful selection transform (result shown in Capsule) increments that binding’s count for the day (`id` + `kind`). Copy, empty selection, empty instruction, and errors do not count. Instruction text is not stored.
4. For the selected calendar month (default: current, local timezone), show:
   - **Would have typed:** `characters / (WPM × 5 / 60)` seconds
   - **Time saved:** `max(0, would-have-typed − recording duration)`
   - **Characters** and **Successful dictations** side by side: inserted character total and paste count for the month
   - **Bindings:** per-binding successful transform counts (live label from current bindings; deleted bindings as “Deleted binding” + kind)
5. WPM default 50 (range 10–200), shown above **Bindings**. Footer: one word = 5 characters including spaces. Changing WPM recomputes the two numbers from stored totals. WPM does not apply to transforms.
6. Month stepper: current month and past months that have data; cannot step into the future.
7. Clear statistics deletes the local JSON file. Disabling collection stops writes but keeps history.

## Acceptance Criteria

- Collection off: successful paste does not write `daily.json`.
- Collection on: successful paste increments today’s dictation bucket; successful Capsule transform increments that binding’s count; cancel / silent / STT error / transform error / Copy do not.
- Current month is the default period; estimates use the current WPM setting, not a stored duration.
- Default WPM is 50; custom WPM in 10–200 updates both numbers immediately.
- Clear removes counts; models and other settings are untouched.
- No new outbound network.

## Verification Plan

- Debug build.
- Opt-out: dictate, confirm no stats file (or unchanged file).
- Opt-in: successful paste updates the two numbers; cancel and silent finish do not.
- Opt-in: successful transform increments that binding’s row; Copy / error / empty selection do not.
- Delete a used binding: orphan row “Deleted binding” remains with its count.
- Change WPM: numbers recompute without a new dictation.
- Month stepper: current month; previous month only if it has data.
- Clear: numbers empty; further dictations (if collection on) start fresh.

## Documentation Impact

- ADR-013; architecture, roadmap, ux-setup-status, constraints, workflow ADR list.
