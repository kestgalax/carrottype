# Workflow

```text
Idea -> Product Intent -> ADR Gate -> Feature/Tasks -> Implementation -> Review -> Release
```

## Current phase (after v0.6.0)

Unsigned DMG on GitHub Releases; source under MIT (ADR-011). Repository is **public**; preflight found private visibility on 2026-11-10, then the maintainer explicitly authorized public code/history and the change was applied/verified. v0.3.9 parallel unmute + live-draft hygiene; Storage download-cache clear in v0.3.8; security hardening (ADR-015) in v0.3.7; live draft (ADR-014) through v0.3.4–v0.3.6.

Next ordered focus:

1. Staged improvements: reliability → Ultra-only dictation → GitHub app updates → setup/settings → update presentation/What’s New → lifecycle/tests. Target versions and acceptance criteria: [`2026-11-09-product-improvements.md`](../docs/superpowers/plans/2026-11-09-product-improvements.md). Reliability `0.3.10 (23)` was published after the user accepted every Debug manual checklist item and clean Release DMG verification passed. Ultra-only dictation `0.4.0 (24)` was published after its own Debug manual acceptance and verified Release packaging (2026-11-10). 0.5.0 (25) GitHub updates is published (ADR-017), with isolated native installer A → B and signature-negative checks passed. The user explicitly authorized publication after Debug delivery on 2026-11-10; individual UI/TCC results were not enumerated. Clean Release packaging, draft/public asset signatures/hashes and anonymous native feed verification passed. The maintainer separately authorized public repository visibility; 0.6.0 (26) X1–X3 is published: setup/trial, compact bindings and formatting feedback. The user accepted Debug and authorized publication on 2026-11-10. Production checks, clean Release/DMG, signed local/draft/public assets and anonymous native feed probe from build 25 passed (`docs/debug-review-v0.6.0.md`, PR #22). Next is 0.6.1 update presentation/What’s New (N1–N3), added by the maintainer on 2026-11-10 from screenshots; lifecycle/tests is retained as 0.6.2. Task: `docs/specs/tasks/update-release-notes-ux.md`; now implemented on `feat/update-release-notes-ux` as Debug (27), with its own manual acceptance/publication gate pending. See `docs/debug-review-v0.5.0.md`.
2. Optional later: Developer ID sign + notarize (`ops/deploy.md` / `notarize-dmg.sh`) when credentials exist. Updater integration has its own ADR/network gate and unsigned-upgrade verification; notarization is not a prerequisite to begin it.
3. Post-v1 research spikes when useful (`docs/research-post-v1-spikes.md`).

## Phase gates

### Product intent

- Changes to mission / non-goals update `docs/product-intent.md` and roadmap.

### ADR gate

- New STT/cleanup engine, catalog policy, or distribution trust model → ADR before code.
- New outbound network sink, telemetry/analytics, or direct SPM product dependency → ADR before code (closed sinks in `.ai/constraints.md`).
- Accepted ADRs: ADR-002 (stack), ADR-003 (catalog), ADR-004 (Whisper), ADR-005 (Qwen), ADR-006 (Parakeet), ADR-007 (Wave Link unmute), ADR-008 (Apple SpeechAnalyzer STT), ADR-009 (OOP cleanup), ADR-010 (Gemma cleanup), ADR-011 (public MIT distribution), ADR-012 (selection transform), ADR-013 (local usage stats), ADR-014 (live dictation streaming), ADR-015 (hub revision + helper path jail), ADR-016 (Ultra-only dictation, shipped in 0.4.0), ADR-017 (signed GitHub app updates, shipped 0.5.0).

### Feature / Settings UX

- Setup UI follows `docs/specs/ux-setup-status.md` (Ready rules, Make active, L10n, mic meter).
- Language changes must not remount Settings in a way that kills the mic meter.

### Implementation

- Use Developer role (`.ai/developer.md`); keep diffs small and traced to roadmap/spec/ADR.

### Review

- Use Reviewer role (`.ai/reviewer.md`) before calling work complete.

### Release

- For every version, prepare and verify a Debug build first, provide it to the user for manual testing, and wait for their explicit confirmation before publishing. A successful automated build does not substitute for this user gate (maintainer instruction, 2026-11-09).
- Build via `macos/scripts/build-release-dmg.sh`; notes in `docs/github-release-notes-v0.1.0.md`.
- Attach DMG to GitHub Release; do not commit `dist/` to git.

## Planned UI/UX and logo stage — 2026-11-10

Maintainer requested a separate 0.7.0 stage after 0.6.1 update presentation and 0.6.2 lifecycle: audit the real UI/UX, discuss improvements/visual directions and explore a modern minimal logo based on CarrotType/current carrot. References named: OpenBot and GrogBot (confirm exact products during research). Present comparable concepts and discuss before replacing UI/logo; preserve useful features. Task: `docs/specs/tasks/uiux-and-brand-refresh.md`, D1–D3 in staged plan. Planning only; no audit, designs or asset changes claimed. Existing per-version Debug/manual/publication gate remains.

## 0.6.1 implementation — 2026-11-10

N1–N3 implemented on `feat/update-release-notes-ux`, from main with planning commits retained. Debug 0.6.1 (27) delivered in dist; not published or manually accepted yet. Offline bundled What’s New/native buttons/read-version badge, single localized JSON → signed inline HTML/Markdown and unique per-run/scenario staging identities. No standard updater/gate/trust replacement. Production tests, Debug and isolated native installer/negative checks pass; offscreen production SwiftUI layout inspected, actual GUI observation still permission_denied. Manual checklist/evidence: `docs/debug-review-v0.6.1.md`. Latest stable 0.6.0. Next after acceptance/release: 0.6.2 lifecycle, then 0.7.0 UI/UX/logo discussion. Do not publish without this version’s explicit confirmation.

## 0.6.1 release authorization — 2026-11-10

Maintainer accepted the delivered Debug: «все ок, публикуем». This version’s publication gate is satisfied; clean Release packaging and signed draft/public asset verification are now in progress. Individual manual checklist results were not enumerated; preserve independent GUI/TCC/network limits. No authorization for later version releases is inferred.
