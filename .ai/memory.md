# Memory

Project memory lives in repository artifacts — not in chat transcripts.

## Canonical sources

- Product: `docs/product-intent.md`
- Status / next steps: `docs/roadmap.md`
- Staged improvement plan (2026-11-09): `docs/superpowers/plans/2026-11-09-product-improvements.md` — reliability `0.3.10 (23)` published after all Debug manual checks and verified Release DMG (`docs/debug-review-v0.3.10.md`); Ultra-only dictation `0.4.0 (24)` published after its own Debug acceptance and verified Release DMG (2026-11-10); GitHub updates 0.5.0 (25) is published with signed feed/archive, operation install gate and isolated real native A → B/negative checks passed (ADR-017, `docs/debug-review-v0.5.0.md`); The user explicitly authorized publication after Debug delivery, then separately authorized public code/history on 2026-11-10 after private visibility was found; visibility was changed and verified. Individual UI/TCC results were not enumerated; Clean Release, signed draft/public assets and anonymous native feed checks passed; release/DMG/ZIP/appcast published. 0.6.0 (26) X1–X3 is published after its own user Debug acceptance/authorization on 2026-11-10. Clean Release/DMG, local/draft/public signatures/digests and anonymous feed/archive checks passed; native Sparkle probe from isolated build 25 found the update (`docs/debug-review-v0.6.0.md`, PR #22). Next is 0.6.1 update presentation/What’s New (maintainer request 2026-11-10; `docs/specs/tasks/update-release-notes-ux.md`); retain lifecycle/tests as 0.6.2. Now published as 0.6.1 (27) after explicit Debug acceptance and verified Release/signed assets (see publication evidence below). Styled Sparkle notes plus offline installed-version window/button, no automatic popup or extra network sink.
- Architecture: `docs/architecture.md`
- Decisions: `docs/decisions/` (ADR-001 … ADR-017)
- Setup UX: `docs/specs/ux-setup-status.md`
- Security: `docs/security/secure-coding-checklist.md`, `docs/security/supply-chain.md`
- Release notes: `docs/github-release-notes-v0.6.0.md` (prior: `v0.5.0`, `v0.4.0`, `v0.3.10` … `v0.1.0`)
- License / public posture: `LICENSE`, ADR-011, `ops/deploy.md`
- Ops: `ops/deploy.md`, `ops/environments.md`, `ops/notarization.env.example`

## Rules

- Пользователь (2026-11-09): для каждой версии сначала подготовить Debug build для ручной проверки; публиковать только после его явного подтверждения результатов. Автоматические проверки не заменяют этот gate.
- Пользователь (2026-11-09): не удалять, не скрывать и не ухудшать существующие полезные функции без отдельного согласования. Согласованное сокращение моделей диктовки до Parakeet Ultra не разрешает удалять другие возможности; при рефакторинге и упрощении UI проверять их сохранность.
- Prefer updating these files over relying on conversation context.
- Do not delete ADRs, specs, reviews, or roadmap history unless a human maintainer explicitly instructs it.
- When correcting outdated status (e.g. public vs private distribution), update roadmap and deploy notes in the same change.

## Planned UI/UX and logo stage — 2026-11-10

Maintainer requested a separate 0.7.0 stage after 0.6.1 update presentation and 0.6.2 lifecycle: audit the real UI/UX, discuss improvements/visual directions and explore a modern minimal logo based on CarrotType/current carrot. References named: OpenBot and GrogBot (confirm exact products during research). Present comparable concepts and discuss before replacing UI/logo; preserve useful features. Task: `docs/specs/tasks/uiux-and-brand-refresh.md`, D1–D3 in staged plan. Planning only; no audit, designs or asset changes claimed. Existing per-version Debug/manual/publication gate remains.

## 0.6.1 implementation — 2026-11-10

N1–N3 implemented on `feat/update-release-notes-ux`, from main with planning commits retained. Debug 0.6.1 (27) delivered in dist, subsequently accepted and released (publication evidence below). Offline bundled What’s New/native buttons/read-version badge, single localized JSON → signed inline HTML/Markdown and unique per-run/scenario staging identities. No standard updater/gate/trust replacement. Production tests, Debug and isolated native installer/negative checks pass; offscreen production SwiftUI layout inspected, actual GUI observation still permission_denied. Manual checklist/evidence: `docs/debug-review-v0.6.1.md`. Latest stable 0.6.0. Next after acceptance/release: 0.6.2 lifecycle, then 0.7.0 UI/UX/logo discussion. This version’s explicit confirmation was received before publication; future releases retain their own gates.

## 0.6.1 release authorization — 2026-11-10

Maintainer accepted the delivered Debug: «все ок, публикуем». This version’s publication gate is satisfied; clean Release packaging and signed draft/public asset verification completed before stable/latest publication. Individual manual checklist results were not enumerated; preserve independent GUI/TCC/network limits. No authorization for later version releases is inferred.

## 0.6.1 published — 2026-11-10

User accepted Debug: «все ок, публикуем». Stable/latest 0.6.1 (27) published; clean Release/DMG, signed bundled/local/draft/public assets and anonymous feed/archive digests passed. Native Sparkle probe with isolated build-26 host found the update. Tag/source 7207548; PR #23; release notes/checksums and evidence in `docs/github-release-notes-v0.6.1.md`, `docs/debug-review-v0.6.1.md`. No independent post-release TCC/GUI/network audit claim; no key export. Next: 0.6.2 lifecycle, then separate 0.7.0 UI/UX/logo discussion; new branches and per-version Debug acceptance remain required.

## 0.6.2 implementation — 2026-11-10

C1–C2 on `refactor/dictation-session-lifecycle` from main after PR #23. Debug 0.6.2 (28): single session owner, snapshotted model/formatting/device/mode, joined preview/unmute/teardown and awaited model unload; model maintenance shares the install gate. Streaming pass/feed/recorder peak/fanout are epoch-bound; actual actor tested with test-only SDK. Normal Quit drains cleanup; Sparkle trust/gates preserved. Production helpers replace mirrors; local checks/mutations and Debug pass, Actions workflow added with pinned tooling and no distribution keys. Manual acceptance and publication pending; details: `docs/debug-review-v0.6.2.md`, `docs/specs/tasks/dictation-session-lifecycle.md`. No user models or data removed. Next after this version’s approval/release: separate 0.7.0 UI/UX/logo exploration, options discussed before replacement.

0.6.2 delivery closeout: signed Debug verified against the final successful arm64 build; all local regression suites passed. GitHub refused workflow push (OAuth missing `workflow`); connector writes returned 403. No remote branch/PR/CI run created; commits and workflow remain local. Do not report CI success. Manual checklist at `docs/debug-review-v0.6.2.md`; no publication authorization for 0.6.2 yet.

## 0.6.2 release authorization — 2026-11-10

After signed Debug delivery and the focused lifecycle checklist, maintainer instructed «публикуй». This satisfies this version’s publication authorization; individual manual results were not enumerated. Prepare clean Release/DMG and verify signed local/draft/public assets before stable publication. Remote CI remains unexecuted until GitHub workflow access is restored. No authorization for later versions is inferred.

GitHub authorization restored (`workflow`), source branch/tag pushed and PR #24 created. First hosted run 42815277135 failed before tests because AIDOS is private. CI-only correction separates app regression/build from optional private-tooling checkout: no new secret installed, explicit skip/warning for hosted AIDOS without a narrowly scoped read token. Local governance passed. Release app source/accepted Debug and signed artifacts are unchanged; tag 14dacf3 retains the original workflow. Draft asset verification in progress.
