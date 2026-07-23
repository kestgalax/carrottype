# Hotkey CarrotType Caret Paste

## Metadata

- Feature ID: F-001
- Title: Hotkey CarrotType Caret Paste

## Traceability

- Product Intent Link: docs/product-intent.md
- Roadmap Item: Milestone 2: First Feature
- Related ADRs: docs/decisions/ADR-001-initial-project-structure.md, docs/decisions/ADR-002-runtime-stack.md, docs/decisions/ADR-003-model-catalog-and-cleanup.md
- UX Spec: docs/specs/ux-setup-status.md

## Problem

Users need a fast, private way to turn speech into text in whatever app they are already typing in, without cloud upload and without a heavy voice-studio product.

## Proposed Behavior

1. User presses a global hotkey to start recording.
2. User presses again (or releases, if push-to-talk) to stop.
3. Audio is transcribed on-device with a Parakeet/Whisper-class model.
4. Resulting text is inserted at the caret of the frontmost application.

## Acceptance Criteria

- Global hotkey works while another app is focused.
- Recording start/stop is under explicit user control.
- Transcription completes without network dependency for the default model path.
- Text is pasted/inserted at the current caret (not only shown in a separate window).
- Failure modes (mic denied, model missing, empty audio) surface a clear local status.

## Verification Plan

- Manual: hotkey start/stop while TextEdit is focused; spoken text appears at caret.
- Manual: repeat in a browser text field.
- Manual: airplane mode / blocked network still succeeds for the default local model path.
- Manual: deny Microphone and Accessibility once each; app shows a clear recovery hint.

## Documentation Impact

- Update `ops/environments.md` with run and permission steps after the Xcode skeleton exists.
- Keep `docs/architecture.md` aligned if the STT engine choice changes.
- Record release/install notes in README when the first GitHub Release is cut.
