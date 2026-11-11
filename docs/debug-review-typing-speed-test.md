# Typing-speed calibration — implementation and Debug evidence

2026-11-11. Status: **signed Debug delivered for Codex review; no version, merge, push,
publication or user-installation authorization.** The maintainer approved the implementation
scope («отлично, мне нравится, давай реализовывать»). This is implementation evidence, not
manual acceptance.

## Traceability

- Task/spec: `docs/specs/tasks/typing-speed-test.md` (T1–T4).
- ADR: `docs/decisions/ADR-013-local-usage-stats.md` (2026-11-11 amendment).
- Roadmap: "Typing-speed calibration — implementation for review (no version assigned)".
- Feature/UX: `docs/specs/features/local-usage-stats.md`, `docs/specs/ux-setup-status.md`.
- Architecture: "Typing-speed calibration — pre-release prototype".

## Branch and commits

- Worktree: `/Users/kestgalax/orca/workspaces/carrottype/typing-speed-test`.
- Branch: `kestgalax/typing-speed-test`, based on `origin/main` `58bdca2`.
- Planning commits cherry-picked in order: `129ae80`, `8b35759`, `53e7890`.
- Implementation commit: `af39ec2` (`feat: add native typing-speed calibration in Statistics`).
- No version bump: the Debug bundle remains 0.9.0 (33). Dynamic Island 0.9.0 behavior and
  published assets are unchanged. GigaAM remains deferred.

## User-facing behavior

- Statistics → Typing speed keeps the existing Stepper (10–200, default 50, manual editing) and
  adds a compact **Measure…** action with a short note that the value estimates saved time.
- The native sheet is 600×390 inside the real 720×520 Settings shell. Ready shows RU/EN text
  language, Easy/Medium(default)/Advanced level, a three-line prompt preview, the instruction
  and Start. Running shows the same fixed prompt with per-character feedback, an error underline
  and colour, a caret block and remaining time. Result shows WPM, CPM, accuracy, 30 s, text
  language and level, with Repeat / Close / **Use N WPM**.
- Only Use writes the existing `carrottype.typingSpeedWPM` and closes the sheet. The footer
  explains that all period estimates are recalculated while dictation counts do not change.
  Low accuracy is informational; an out-of-range result is displayed honestly with an
  explanation and Apply disabled (no clamp). Cancel/Close/Repeat never write baseline WPM.
- Attempt text, keys, accuracy, language, level, seed, result and date remain RAM-only.
  Collection stays off if it was off; `daily.json` is never written by the test.

## Ownership and metric

- `TypingTestCorpus` + `TypingTestPromptBuilder`: original RU/EN corpora, seeded injectable
  `SplitMix64`, fresh attempt on open/Repeat/language/level change, immediate whole-prompt repeat
  avoidance, no adjacent duplicate fragment at refill boundaries, at least 650 NFC graphemes.
- `TypingSpeedTestEngine`: first committed printable grapheme starts a fixed monotonic 30 s
  deadline. Credited characters = fully correct words + their typed separators + the correct
  prefix of the current unfinished word. `CPM = credited × 60 / 30`,
  `WPM = credited / 5 × 60 / 30`. Accuracy uses committed-grapheme insertion attempts and keeps
  corrected mistakes; Backspace/navigation/marked IME text are not attempts. Late events are
  discarded; tick count never defines duration.
- `TypingSpeedTestSheetModel`: one ≤10 Hz Timer only while Running; fresh prompt and RAM-only
  result; no idle polling.
- `TypingSpeedTestCoordinator`: the existing `UpdateInstallationGate` is reserved only while
  Running. Input focus suspends only CarrotType global hotkeys by token. Completion/cancel/close/
  deactivation/sleep/Settings close/quit/install release both exactly once. A real
  dictation/transform/maintenance/install request dismisses the test without applying.
- Native input: transparent `NSTextView` adapter accepts committed inserts/Backspace/IME/dead
  keys; paste/drop/autocorrect/substitutions/spellcheck/undo are disabled; the clipboard is not
  read. TextKit renders the prompt and scrolls by line.

## Verification run

Commands and results from this worktree:

- `bash scripts/verify-typing-speed-test.sh` — PASS. Covers bundled-corpus validation/size,
  all 3×2 language/level modes, seeded reproducibility/variation, immediate-repeat avoidance,
  no adjacent duplicate at refill, metric fixtures (words, separators, last partial, wrong
  words, case/ё, NFC), exact deadline/late events, corrections/accuracy denominator, empty/
  out-of-range/low-accuracy policy, refill without shortening 30 s.
- `python3 scripts/verify-typing-speed-app.py --build-log /tmp/typing-speed-debug.log` — PASS.
  Actual AppState/hotkey/gate fakes: focus vs running lease, busy/installing/waiting exclusion,
  idempotent/nested token restore, Apply-only WPM write with stats off, deactivation/sleep/
  Settings close/quit/install cleanup, queued hotkey dismissal without capture, 20-cycle
  timer/gate/hotkey cleanup. Native input harness: committed inserts, Backspace diff, paste
  blocked, IME marked text only on commit, Escape/focus. No microphone/model/clipboard/stats
  writes.
- Existing regressions: `verify-setup-formatting.sh`, `verify-dynamic-island.sh`,
  `verify-formatting-rules.sh`, `verify-launch-at-login.sh`, `verify-session-lifecycle.sh`,
  `verify-dictation-reliability.sh`, `verify-ultra-models.sh`, `verify-app-updates.sh`,
  `verify-release-notes.sh`, `verify-model-catalog-streaming.py`, `verify-brand.py` — PASS.
- Local governance: `npm run aidos:validate`, `aidos:trace` (no missing links), `aidos:review`
  (Outcome: Approve) — PASS.
- Debug arm64 build: `xcodebuild ... -configuration Debug -destination 'platform=macOS,arch=arm64'`
  — BUILD SUCCEEDED.

Measured data (not a promise of absolute RSS/performance):

- Bundled authored corpus: **15,359 UTF-8 bytes** (RU easy 160 words, EN easy 152; 45 medium and
  42 advanced fragments per language).
- Production model event benchmark, 650 committed graphemes: **19.22 ms total, 0.030 ms/event**
  (ran again after final source; earlier runs 11.64–17.54 ms total).
- Twenty fresh prompt builds: **4.61 ms total, 0.230 ms/build**.
- App integration: 20 attempt cycles completed with no active timer, install-gate lease or
  hotkey suspension left behind.

## Native visual evidence

Offscreen native snapshots (actual shared `CarrotTypeSettingsView` at 720×520 with Statistics
selected, composited with the actual sheet view; **not** a standalone pane and **not** a live
sheet-window capture) are under:

`dist/.builds.noindex/Typing-Speed-Native-Review/native`

They cover Ready/Running/Result for RU/EN × Light/Dark × Easy/Medium/Advanced (36 states), plus
out-of-range, low-accuracy, long English advanced, and minimum-window bottom-scroll snapshots.
The Statistics form scrolls to the Measure row at the real minimum without enlarging the window.
The sheet itself stays within 600×390.

## Signed Debug app

- Path:
  `/Users/kestgalax/orca/workspaces/carrottype/typing-speed-test/dist/.builds.noindex/Typing-Speed-Debug-2026-11-11/CarrotType.app`
- Bundle: `app.carrottype.macos`, version **0.9.0 (33)**, arm64 Debug.
- Identity: `CarrotType Development` (self-signed development identity; not notarized).
- `codesign --verify --deep --strict`: valid on disk, satisfies its Designated Requirement.
- CDHash: `98897b2d46729d96012b71c4ad236febe0d587ce5af47a60961e5b8c4cab0c0c`
- Executable SHA-256:
  `8cd1b431c79368f6cbb6a04744fa5141e6c52be71f2e7f305b79f8a5cf6c34bd`
- `CarrotType.debug.dylib` SHA-256:
  `926f002e67734602b1b1c483c2f3d0b88e93375fa8e0e404118880a62d83758a`
- Previous potentially running Debug copies and the installed/user app, preferences, models and
  published release assets were not replaced. No DMG/ZIP/release was produced.

## Honest limitations / manual checks remaining

- The native snapshots are offscreen compositions of real views; they do not prove a live sheet
  presentation, actual key events on a device, or independent GUI inspection.
- Real interactive typing/focus across the Start button, a live sheet on a physical keyboard,
  actual third-party IME/dead-key composition, VoiceOver reading order/announcements, real
  app deactivation/sleep, and real updater quit/install handoff remain for Codex/maintainer
  manual review. The native input harness exercises the production adapter but not those OS
  environments.
- No real model, microphone, Accessibility permission or statistics collection was required or
  touched. No network call was added; the corpus is bundled.
- The test is a calibration aid, not a scientific/competitive measurement. No comparison or
  ranking with Monkeytype is claimed.
- Self-signed Debug apps still require the project's normal Debug/Gatekeeper handling; this is
  not a notarized or public release. No version/publication authorization is inferred.
