# Typing-speed calibration — Codex review R1/R2

2026-11-11. Status: **review findings resolved in source and signed Debug; awaiting Codex
re-review and maintainer manual acceptance.** This is implementation/review evidence, not
publication authorization.

## Scope

Review of `kestgalax/typing-speed-test` implementation `af39ec2` found two changes requested:

- **R1 blocker — Start focus lifecycle.** `TypingSpeedTestSheetModel.start()` changed Ready to
  armed and synchronously called a focus closure while `TypingTestInputView` is mounted only by
  the armed/running branch. The native field therefore did not exist at the button action, so a
  real Start could return to Ready immediately. Existing tests injected successful focus or
  mounted the adapter separately, so they did not exercise the real button-to-field path. A
  second-part issue: after a failed `beginRun` (a real operation won the gate), the reset path
  cancelled the existing engine without rebuilding it, so the next Start could reuse a cancelled
  engine.
- **R2 — accessible reference text.** The custom-drawn prompt exposed only typed/prompt counts
  as `accessibilityValue`; the reference prompt itself was not readable by VoiceOver because the
  drawn glyphs have no accessible children.

## Resolution

### R1 — real mounted-field focus, token-safe

- `TypingSpeedTestSheetModel.start()` now only acquires the focused ownership, enters `.armed`,
  enables input, and publishes a unique `focusRequest` token. It does not synchronously call
  `controller.focus()`.
- `TypingSpeedTestInputView` now observes that token. Its `TypingTestField` reports
  `viewDidMoveToWindow`; the coordinator makes **one deterministic main-loop hop** only after the
  field is attached to a window and enabled, then calls `window.makeFirstResponder`. There is no
  sleep, polling or retry loop. A stale token, disabled field, detached window or superseded
  request aborts the pending focus.
- The result is reported by token to `handleInputFocusResult`. A real failure returns to Ready,
  releases the gate/hotkey ownership and shows the localized focus message.
- `resetInputAfterFailedStart` now builds a fresh engine/prompt (and resets the native document
  token) after a failed `beginRun`, so Start is retryable instead of reusing a cancelled engine.
- `focusRequest` is cleared on cancel/close/repeat/result/configuration change/sheet disappear.

### R2 — readable accessible prompt

`TypingPromptDisplayView` now exposes the **full reference prompt** as its accessibility value
(static text), while keeping typed/prompt progress in `accessibilityHelp`. The input field keeps
its own localized text-area label. Native harness assertions check both value and progress.

## Exact validation

Executed in the worktree after the fix:

- `bash scripts/verify-typing-speed-test.sh` — PASS (production model fixtures unchanged:
  metric/deadline/corrections/NFC/IME/refill/range; 650-grapheme benchmark).
- `python3 scripts/verify-typing-speed-app.py --build-log /tmp/typing-r1r2.log` — PASS. New
  actual-window regression: create an `NSHostingView` + `NSWindow` with the real
  `TypingSpeedTestSheet` in Ready, invoke the production `model.start()`, wait for real
  SwiftUI/AppKit layout (no injected focus success), assert the mounted native field is the
  window `firstResponder`, commit a printable grapheme, assert Running + install-gate lease +
  timer + hotkey suspension, assert the prompt accessibility value is the full reference text
  and progress is separate, then Repeat/Cancel and assert gate/hotkey/timer restoration.
- Model-level regressions additionally cover focus failure returning to Ready and a failed
  `beginRun` followed by a successful retry with a fresh engine.
- `xcodebuild ... -configuration Debug -destination 'platform=macOS,arch=arm64'` — BUILD
  SUCCEEDED.

## New signed Debug

- Path:
  `dist/.builds.noindex/Typing-Speed-Debug-R1R2-2026-11-11/CarrotType.app`
- Prior app preserved at
  `dist/.builds.noindex/Typing-Speed-Debug-2026-11-11/CarrotType.app` (not replaced).
- Bundle `app.carrottype.macos`, 0.9.0 (33), arm64 Debug.
- `codesign --verify --deep --strict`: valid; designated requirement satisfied.
- CDHash: `911541c5bd4a2ca6dba57d4cc33a3188d183ed92349c5d5fb9037832542d0082`
- Executable SHA-256:
  `83760a134066c98ae192908caa8059fb1484d7e5bdf063ca683c434fe31134a2`
- `CarrotType.debug.dylib` SHA-256:
  `109effd2da669ca201764cb6bdd8825558d80deeef70b83d0552cd7dac07731c`

## Remaining manual checks

Physical keyboard input in a live sheet, actual third-party IME/dead-key composition,
VoiceOver reading order/announcements, real app deactivation/sleep, and real updater
quit/install handoff remain manual. The new native window regression proves the mounted field
and first-responder path, but it is not a device/TCC/VoiceOver acceptance. No merge, push,
version bump, publication, installed-app, preferences, models or prior Debug copy was changed.
