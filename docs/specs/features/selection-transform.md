# Selection Transform

## Metadata

- Feature ID: F-002
- Title: Selection Transform (bindings + bidirectional Translate)

## Traceability

- Product Intent Link: docs/product-intent.md
- Roadmap Item: Selection Transform (ADR-012)
- Related ADRs: docs/decisions/ADR-009-out-of-process-smart-cleanup.md, docs/decisions/ADR-012-selection-transform.md
- UX Spec: docs/specs/ux-setup-status.md

## Problem

Users need a fast, private way to run instructions (translate, summarize, restyle) on text they already selected in another app, without cloud upload and without opening a chat UI — including cases where replacing the selection is impossible or undesirable (browser, PDF). Multiple shortcuts should map to different actions and models.

## Proposed Behavior

1. User selects text in the frontmost app.
2. User presses a transform **binding** hotkey (fresh default: one Translate binding on **⌥'**, pair **ru ↔ en**).
3. CarrotType reads the selection (Accessibility, with ⌘C fallback).
4. **Translate** bindings: detect language against the configured pair → flip to the other side → dynamic translate prompt. **Custom** bindings: use the binding’s instruction text.
5. On-device MLX helper runs with the resolved instruction and the binding’s Smart/Smart+/Gemma package.
6. Result appears in an expanded Status Capsule: optional direction (`EN → RU`), **Copy** / **Close**; Escape dismisses. Selection is not replaced.
7. Settings → General: bindings list (hotkey, kind, model; pair pickers for Translate; TextEditor for Custom); max 5.

## Acceptance Criteria

- Translate binding flips both ways for the user-configured pair (default ru↔en).
- Custom binding on another chord does not run language detect.
- Works when post-dictation formatting is Off/Light if the binding’s MLX package is Ready.
- Result shows in Capsule without changing the source selection; Copy / Close / Escape as specified.
- Empty Custom instruction / no selection / missing model surface a clear local error.
- Chord conflicts with dictation or another binding are rejected in capture UI.
- Dictation hotkey and literal cleanup behavior are unchanged.

## Verification Plan

- Manual: fresh install → Translate ⌥', pair RU↔EN; select EN → Capsule RU; select RU → Capsule EN.
- Manual: change pair to EN↔DE; verify flip.
- Manual: short “OK” → preferred target (UI locale if in pair, else languageB).
- Manual: Custom summary on a second hotkey.
- Manual: conflict — cannot duplicate chord / match dictation.
- Manual: formatting Off + Smart Ready → transform still runs.
- Manual: dictation ⌥/ still pastes at caret.

## Documentation Impact

- ADR-012; architecture, roadmap, ux-setup-status, constraints.
