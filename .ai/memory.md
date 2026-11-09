# Memory

Project memory lives in repository artifacts — not in chat transcripts.

## Canonical sources

- Product: `docs/product-intent.md`
- Status / next steps: `docs/roadmap.md`
- Staged improvement plan (2026-11-09): `docs/superpowers/plans/2026-11-09-product-improvements.md` — reliability `0.3.10 (23)` published after all Debug manual checks and verified Release DMG (`docs/debug-review-v0.3.10.md`); Ultra-only dictation `0.4.0 (24)` published after its own Debug acceptance and verified Release DMG (2026-11-10); GitHub updates 0.5.0 (25) is published with signed feed/archive, operation install gate and isolated real native A → B/negative checks passed (ADR-017, `docs/debug-review-v0.5.0.md`); The user explicitly authorized publication after Debug delivery, then separately authorized public code/history on 2026-11-10 after private visibility was found; visibility was changed and verified. Individual UI/TCC results were not enumerated; Clean Release, signed draft/public assets and anonymous native feed checks passed; release/DMG/ZIP/appcast published. Next is 0.6.0. Setup/settings and lifecycle/tests remain planned.
- Architecture: `docs/architecture.md`
- Decisions: `docs/decisions/` (ADR-001 … ADR-017)
- Setup UX: `docs/specs/ux-setup-status.md`
- Security: `docs/security/secure-coding-checklist.md`, `docs/security/supply-chain.md`
- Release notes: `docs/github-release-notes-v0.5.0.md` (prior: `v0.4.0`, `v0.3.10` … `v0.1.0`)
- License / public posture: `LICENSE`, ADR-011, `ops/deploy.md`
- Ops: `ops/deploy.md`, `ops/environments.md`, `ops/notarization.env.example`

## Rules

- Пользователь (2026-11-09): для каждой версии сначала подготовить Debug build для ручной проверки; публиковать только после его явного подтверждения результатов. Автоматические проверки не заменяют этот gate.
- Пользователь (2026-11-09): не удалять, не скрывать и не ухудшать существующие полезные функции без отдельного согласования. Согласованное сокращение моделей диктовки до Parakeet Ultra не разрешает удалять другие возможности; при рефакторинге и упрощении UI проверять их сохранность.
- Prefer updating these files over relying on conversation context.
- Do not delete ADRs, specs, reviews, or roadmap history unless a human maintainer explicitly instructs it.
- When correcting outdated status (e.g. public vs private distribution), update roadmap and deploy notes in the same change.
