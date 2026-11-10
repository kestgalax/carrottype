# 0.8.0 — Dictation rules, cleanup catalog and theme

Trace: maintainer request and implementation authorization (2026-11-10), [audit/P1–P4 plan](../../2026-11-10-post-dictation-formatting-audit.md), [ADR-018](../../decisions/ADR-018-dictation-rules-and-cleanup-catalog.md). Branch `feat/formatting-rules-theme-0.8`, fresh from main `6bc31ec` with planning history retained.

## Metadata

- Task ID: dictation-rules-and-theme
- Status: R1/R2 exact rework implemented for signed Debug review; R3 tone quality failed/open, not release-ready, no publication authorization

## Traceability

- Product Intent Link: `docs/product-intent.md`
- Roadmap Item: `docs/roadmap.md` — 0.8.0 post-dictation rules/theme
- Feature Spec: `docs/specs/ux-setup-status.md`
- Related ADRs: ADR-018, ADR-009, ADR-012, ADR-015, ADR-016, ADR-017

## Implemented

- P1: offer Qwen3 0.6B/Gemma, keep Off/Light. Existing ready active Smart+ and saved binding-specific choices survive; no new Smart+ download/selection/fallback recommendation. Storage and explicit removal remain. Gemma license metadata corrected without repinning weights.
- P2: shared persisted/snapshotted DictationRules; explicit purpose/rules helper v3 separate from Translate/Custom. Tokenizer/chat-template input budgeting, model context preflight, bounded output and normal-stop requirement reject truncated output. Conservative number/negation/URL/code/outer-quote/language checks reject observed losses; visible Light fallback retains source. These are limited checks, not a semantic guarantee. Light preserves meaningful words/line breaks and only removes unambiguous hesitations; empty Light inserts/counts nothing.
- P3: General switches, layout, bounded My Rules (1000 graphemes), summary/reset and text-only trial. Trial uses actual formatting, captures configuration, owns operation/update gate through cancellation/unload, changes no clipboard/history/stats. Closing the section clears/cancels the trial. Theme System (default)/Light/Dark is independently persisted, applied through native application appearance and inherited SwiftUI appearance, without remount; Capsule colors adapt.
- P4: production regressions and native AppState/ModelManager checks; RU/EN/light/dark offscreen layouts; installed Gemma synthetic evaluation. Signed Debug 0.8.0 (30) before any release. [Evidence, model limits and manual checks](../../debug-review-v0.8.0.md).

## Acceptance / limits

Preserve Ultra, Setup trial, caret insertion/last result, live draft, hotkeys/PTT, Wave Link, Translate/Custom, Storage/stats/update trust and selected brand. No new runtime/dependency/network/default STT, implicit model download/delete or installed app replacement. GigaAM deferred without version/date.

Qwen weights are absent: no Qwen comparative quality/latency/RAM claim. Synthetic Gemma results show prompts are preferences rather than guaranteed editing behavior (especially self-correction/paragraph layout). Full system-theme switching, interactive sheets/VoiceOver/TCC/device smoke and network audit remain manual/unverified. Maintainer Debug acceptance and separate publication instruction are pending; 0.7.0 remains stable.

## Acceptance Criteria

- Offer only Qwen3 0.6B/Gemma for new model choices, retain installed active Smart+/binding compatibility/Storage with no silent download/deletion.
- Rules persist, remain bounded/captured, and never replace transform instructions. Incomplete/protected-literal losses trigger visible Light fallback.
- Trial uses actual formatting and retains gate through cancellation/unload; clipboard/history/statistics remain unchanged.
- Theme defaults to System, persists independently of language, updates native windows/Capsule without remount.
- Signed Debug and focused checklist delivered before manual acceptance/separate publication. Known quality/interactive gaps are explicit.

## Verification

- Check: arm64 Debug build, signed app/archive deep strict resources/metadata/helper-v3 jail verified locally.
- Check: production rules/reliability/lifecycle/setup/Ultra/update/notes/catalog/brand suites and actual isolated native AppState/ModelManager/trial/theme passed; evidence in `docs/debug-review-v0.8.0.md`.
- Check: actual offscreen production RU/EN/light/dark/minimum layouts inspected; installed Gemma synthetic diagnostic corpus evaluated with explicit model-quality limits; Qwen absent, no comparative claim.
- Check: local AIDOS validate/trace/review; hosted app CI after source push, manual System/theme/device/TCC review remains pending.

## Documentation Updates

- Update: roadmap, product intent, architecture, UX spec, ADR-018/related ADR cross-references, staged plan/audit, task, quality observations, Debug/draft release notes and memory/workflow.

## ADR Impact

New ADR required: ADR-018 accepted for narrowed cleanup offerings/compatibility and bounded dictation rules/v3 helper purpose. No new engine/runtime/network/trust; existing ADR-009/012/015/016/017 boundaries retained.

## Custom-rule Debug diagnostic

Next: [R1–R4 rework proposal](../../superpowers/plans/2026-11-10-formatting-rework.md), requested by the maintainer after failed combined-rule acceptance. Explicit deterministic controls, separately assessed business style, stage-specific fallback reporting, then signed Debug/manual acceptance. Proposal only; revised ADR and implementation pending.

Maintainer asked to recheck actual Gemma trial against four formatting/tone rules and supplied text. Actual AppState path confirms rules arrive, but combined/style compliance remains unreliable. Prompt priority/content-intent boundaries clarified, question-mark-loss rejection tested, actual-mode/fallback UI made explicit; no generic few-shot contamination retained. [Detailed evidence and unresolved quality](../../2026-11-10-formatting-quality-0.8.0.md). No complete four-rule/business-tone acceptance is claimed, no user message committed, no new engine or implicit download. Signed Debug feedback still precedes any publication.


## R1–R4 implementation review

Maintainer authorized continuation. New main-based `feat/deterministic-formatting-0.8` retains earlier 0.8 commits. R1/R2 exact word/case/final-period controls, legacy decode defaults, explicit Off semantics, safe fallback/empty output and common pipeline implemented. Typed helper failure categories and separate exact/tone stages in shared UI; transform localised errors preserved. Production and actual AppState checks cover these paths. Signed Debug/evidence: `docs/debug-review-v0.8.0.md`.

R3 limited two-candidate Gemma evaluation completed, **quality acceptance failed**. Added reproducible actual trial diagnostic (`verify-formatting-app.py --model-quality`) with public synthetic fixtures only. Tone is experimental/off by default; missing/invented questions are rejected for tone, with ordinary literal question punctuation preserved. Full four-rule requirement remains unaccepted. R4 local checks/build/signing/offscreen review passed, hosted CI/manual pending. Existing settings/models/functions and earlier theme/scroll fixes preserved; no publication. Do not mark the full task complete based on exact-control success or safe fallback.


First-letter maintainer addition: independent persisted `lowercaseFirstLetter`, absent → false; only the first letter changes in the final shared exact stage, with full-lowercase precedence and protected starts retained. New RU/EN examples, legacy defaults/persistence, combinations and real AppState trial check; new signed Debug app recorded in the review document. Tone/publishing status unchanged.
