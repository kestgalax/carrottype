# 0.7.0 design decision: Native A + Carrot A

Maintainer selected both A concepts on 2026-11-10: «согласен, мне нравится A как для интерфейса так и для логотипа». Implementation branch `feat/native-ui-brand-0.7` starts from main after PR #24, with the exploration preserved.

Scope: familiar native grouped settings and five-pane navigation; brand/title/spacing hierarchy and compact status at the bottom of the sidebar; formatting-mode access in General using the same Ready-only ModelManager binding; accessibility A1–A5, dictation grouping U1/U2 and deletion confirmations; original geometric Carrot A icon and idle menu template. Keep active recording/processing/error state symbols and semantics.

Preserve all controls and functions, RU/EN and settings/data, native light/dark, window sizes, local/trust/runtime policy and no-remount language behavior. Deferred: extra sidebar destinations/dashboard, U3 readiness restructuring, geometry changes without native evidence, UI variants B/C. Existing models/formatting engines stay.

Verification: vector/PNG provenance and 16/18/32 px checks, native offscreen rendering where available (not interactive QA), Debug arm64 and relevant production regressions, concise manual checklist. Debug 0.7.0 must be accepted separately before publishing. No new ADR impact.
