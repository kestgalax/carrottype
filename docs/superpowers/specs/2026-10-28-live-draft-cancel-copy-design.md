# Live draft cancel → Copy capsule + Settings hint layout

Date: 2026-10-28  
Branch: `feat/live-draft-cancel-copy`  
Status: Approved (owner)  
Ship target: **v0.3.5** mini-patch on top of v0.3.4

## Goal

If the user cancels a live-draft dictation (Escape), do not throw away a useful Capsule draft: show a short result capsule with **Copy** / **Close**, then auto-dismiss. Also fix General → Hotkey footer hints so each toggle has its caption underneath (same pattern as Setup → Permissions).

## Behavior — cancel rescue

1. Preconditions: live draft enabled, listening, Capsule draft text non-empty (`liveDraftConfirmed` + `liveDraftVolatile`).
2. **Escape** (explicit cancel): stop recording / cancel preview; **do not** run WAV final STT → cleanup → paste.
3. Capsule enters a new phase `liveDraftResult` (or equivalent): snapshot of the draft text + **Copy** / **Close** (reuse transform button chrome and localization keys where possible).
4. Dismiss when any of:
   - **Close**
   - Escape again
   - **auto-dismiss after 5 seconds**
   - start of a **new dictation** or transform session
5. Soft / silent-too-short cancel with empty draft: unchanged (no result capsule).
6. Normal stop (hotkey release / toggle off): unchanged — Understanding → formatting → paste.

### Copy

- Copies the snapshot string to the pasteboard.
- Brief “Copied” feedback (same as transform).
- Does not resume dictation; does not paste at caret.

### Out of scope (this patch)

- Mid-flight Copy button while still Listening
- Result capsule for cancels without live draft
- Changing default live-draft off, Gemma/Smart prompts, or paste pipeline

## UI — result capsule

- Clickable panel (like `transformResult`), not click-through.
- Body: draft snapshot (no muted “volatile” split — static text).
- Actions: Copy / Close; optional short title such as “Черновик” only if needed for clarity — prefer minimal chrome matching transform.
- Panel sizing: reuse transform-result geometry (or live-draft height rules if the snapshot is long); keep notch-aware placement.

## Settings — per-toggle hints

In `GeneralSettingsPane` Hotkey section:

- Remove the combined Section `footer` that stacks retain-clipboard + live-draft blurbs.
- Under **push-to-talk** toggle: `hotkey.push_to_talk_footer` (caption style like Setup).
- Under **retain clipboard** toggle: `hotkey.retain_clipboard_footer` — update copy so Escape cancel mentions the draft Copy capsule when live draft was showing text (keep RU/EN).
- Under **live draft** toggle: `hotkey.live_draft_footer` / `hotkey.live_draft_unavailable`.
- Recording / capture hint stays tied to the hotkey row (or a thin section footer only while capturing), not dumped under all toggles.

## Implementation sketch

- `StatusCapsulePhase.liveDraftResult` (+ clickable `ignoresMouseEvents` false).
- `AppState`: snapshot property, 5 s dismiss timer, cancel path branches when draft non-empty; clear on new session.
- Wire Copy to pasteboard helper parallel to `copyTransformResult` (shared or thin twin — avoid mixing transform result state).
- Docs: ADR-014 / F-004 / ux-setup-status short note; roadmap + release notes v0.3.5.

## Traceability

- Product: optional live draft (ADR-014) + Status Capsule patterns (transform Copy/Close)
- Release: unsigned DMG v0.3.5 after merge
