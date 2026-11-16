# Worker spec — finalize smart-mic-priority → 0.12.0 release branch

## Goal

Stabilize `feat/smart-mic-priority` for release **0.12.0 (37)**: commit all WIP, bump version metadata, update roadmap/release notes skeleton, push branch, open PR to `main`.

## Context

Worktree: current (smart-mic-priority). Branch already has commit `ec05e11` plus large uncommitted follow-ups:
- Wave Link usability / first-run built-in seed
- Settings focus (LSUIElement → regular while Settings open)
- Dictation/Setup compact mic row + sheet editor with drag reorder
- Generalized priority hint (no Wave copy)
- docs/mockups + sheet design spec

Maintainer accepted behavior («отлично, теперь все работает») and authorized **release preparation**.
A Motion companion was planned then waived at publish; Motion OS tooling was later removed from the
repo. Publication to stable/latest was a **later** gate.

## Required reading

`AGENTS.md` order: README, product-intent, roadmap, architecture, ADRs, `.ai/constitution.md`, `.ai/developer.md`, `.ai/constraints.md`, `ops/deploy.md`.

## Tasks

1. Review `git status` / `git diff`; commit logically on `feat/smart-mic-priority` (feature + docs). Do not commit `dist/`, DerivedData, or mp4s.
2. Bump app to **0.12.0** / build **37** (Info.plist, project.yml / pbxproj if needed, any version sources used by release scripts).
3. Update `docs/roadmap.md` (active work / next focus for 0.12.0 mic priority).
4. Draft `docs/github-release-notes-v0.12.0.md` (RU/EN as project convention) covering:
   - Smart mic priority / failover
   - Sheet UI + drag reorder
   - First-run built-in seed
   - **Демо** subsection (later waived — no mp4)
5. Update task/spec status docs as needed (`smart-mic-priority.md`, sheet design).
6. Push `-u` and open PR to `main` with summary + test plan. Do **not** merge unless coordinator asks.
7. Report: branch, commits, PR URL, version/build, residual risks.

## Agents

Prefer OpenCode. Follow repo commit style. Russian maintainer; notes bilingual per project habit.
