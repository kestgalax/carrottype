# Review — 0.8.0 dictation rules and theme

## Metadata

- Review ID: 2026-11-10-0.8.0
- Outcome: ready for signed Debug/manual review with documented quality limits; **not release approval**.
- Performed by implementation agent against production diff; no independent reviewer claim.

## Traceability Check

- Product Intent: [local dictation preferences](../product-intent.md)
- Roadmap: [0.8.0](../roadmap.md)
- Task: [rules/theme P1–P4](../specs/tasks/dictation-rules-and-theme.md)
- ADRs: 018 plus unchanged 009/012/015/016/017 boundaries.

## Governance Checklist

- Product intent/architecture respected: no new runtime/STT/network/dependency/trust, silent download/delete, installed app replacement or useful feature removal. Rules are separated from transform instructions; text trial is RAM-only and gated through awaited unload/cancel/quit. Theme has no view-identity remount.
- Findings corrected: non-downloadable legacy incorrectly failed Ready status/restore; model numeric/outer-quote/code/language loss; Light meaningful-word/newline/code indentation loss; bounded output/context and incomplete generation rejection.
- Verification evidence: [Debug report](../debug-review-v0.8.0.md). Production components, actual isolated native AppState/ModelManager, offscreen native layouts and synthetic installed-Gemma cases. Governance deterministic validate/trace/review passed locally, not independent human review.

## ADR Impact

ADR-018 accepts narrowed offerings, legacy compatibility, bounded dictation preferences/v3 helper purpose and local trial/theme. Existing ADR history remains with explicit cross-references. No distribution/STT policy change.

## Residual Risks / Follow-Up

Qwen absent; no hidden weights download/comparative quality/latency/RAM claim. Gemma self-correction/paragraph preferences remain inconsistent. Protected-literal checks are conservative and incomplete, can fall back on valid edits, cannot prove meaning. Full interactive System/theme/sheets/VoiceOver/device/TCC/network checks remain manual. No signed Release/DMG/feed or publication until maintainer Debug acceptance and separate instruction.


## R1–R4 self-review addendum

Scope: exact controls and explicit tone outcome on new main-based `feat/deterministic-formatting-0.8`. Outcome: suitable for signed Debug/manual exact-control review; **request changes / quality decision for business tone before release**. This is self-review, not independent approval.

- ADR-018 updated before implementation; no new engine/model/weights/dependency/network/trust. Old user preferences/custom text and earlier theme/catalog/scroll changes retained. Off's independent exact controls explicitly documented/default off. Transform instructions/localised errors preserved and actual engine contracts tested.
- Checks: exact legacy decode/bounds/idempotence/protected literals/empty and all fallback reasons, actual AppState lease/theme/compatibility/clipboard/history/stats, normal helper/streaming lifecycle regressions, Debug build, signed bundle/ZIP and local governance. Offscreen UI inspected. Interactive devices/TCC/VoiceOver, Qwen weights and final hosted CI remain unverified/pending.
- Open blocking quality finding BUS-01: Gemma can retain conversational wording, lose protected content or invent questions. Tone-only question-count rejection catches the supplied observed extra question; exact controls still work on fallback. No semantic guarantee or complete four-rule pass. Experimental/off-by-default UI is disclosure, not resolution. Do not mark 0.8 release-ready on generation/build/fallback success.
