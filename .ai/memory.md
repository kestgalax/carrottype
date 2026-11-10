# Memory

Project memory lives in repository artifacts — not in chat transcripts.

## Canonical sources

- Product: `docs/product-intent.md`
- Status / next steps: `docs/roadmap.md`
- Staged improvement plan (2026-11-09): `docs/superpowers/plans/2026-11-09-product-improvements.md` — reliability `0.3.10 (23)` published after all Debug manual checks and verified Release DMG (`docs/debug-review-v0.3.10.md`); Ultra-only dictation `0.4.0 (24)` published after its own Debug acceptance and verified Release DMG (2026-11-10); GitHub updates 0.5.0 (25) is published with signed feed/archive, operation install gate and isolated real native A → B/negative checks passed (ADR-017, `docs/debug-review-v0.5.0.md`); The user explicitly authorized publication after Debug delivery, then separately authorized public code/history on 2026-11-10 after private visibility was found; visibility was changed and verified. Individual UI/TCC results were not enumerated; Clean Release, signed draft/public assets and anonymous native feed checks passed; release/DMG/ZIP/appcast published. 0.6.0 (26) X1–X3 is published after its own user Debug acceptance/authorization on 2026-11-10. Clean Release/DMG, local/draft/public signatures/digests and anonymous feed/archive checks passed; native Sparkle probe from isolated build 25 found the update (`docs/debug-review-v0.6.0.md`, PR #22). Next is 0.6.1 update presentation/What’s New (maintainer request 2026-11-10; `docs/specs/tasks/update-release-notes-ux.md`); retain lifecycle/tests as 0.6.2. Now implemented as Debug 0.6.1 (27); manual acceptance/publication pending (see implementation evidence below). Styled Sparkle notes plus offline installed-version window/button, no automatic popup or extra network sink.
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

N1–N3 implemented on `feat/update-release-notes-ux`, from main with planning commits retained. Debug 0.6.1 (27) delivered in dist; not published or manually accepted yet. Offline bundled What’s New/native buttons/read-version badge, single localized JSON → signed inline HTML/Markdown and unique per-run/scenario staging identities. No standard updater/gate/trust replacement. Production tests, Debug and isolated native installer/negative checks pass; offscreen production SwiftUI layout inspected, actual GUI observation still permission_denied. Manual checklist/evidence: `docs/debug-review-v0.6.1.md`. Latest stable 0.6.0. Next after acceptance/release: 0.6.2 lifecycle, then 0.7.0 UI/UX/logo discussion. Do not publish without this version’s explicit confirmation.
