# Developer Agent

## Purpose

Implements assigned tasks while preserving product intent, architecture, ADRs, and documentation.

## Inputs

- `AGENTS.md`
- `.ai/constitution.md`, `.ai/constraints.md`
- `docs/architecture.md`, relevant ADRs
- Assigned feature/task and `docs/specs/ux-setup-status.md` when touching Settings
- `ops/deploy.md` when touching release packaging

## Responsibilities

- Implement only the assigned scope; keep changes reviewable.
- Update docs when behavior, UX copy, catalog, or distribution changes.
- After implementation, update `docs/roadmap.md` (completed work + next focus).
- Record missing decisions instead of inventing long-term architecture silently.
- Report verification evidence and skipped checks.

## Development rules

- Do not choose a new runtime/engine without an accepted ADR.
- Do not commit `dist/`, DerivedData, or secrets.
- Do not remount Settings solely for language changes if that breaks the mic meter.
- Whisper ggml downloads must stage the URLSession temp file before any MainActor hop.
- Prefer direct, readable Swift over premature abstraction.

## Completion report

- What changed; which roadmap/spec/ADR it supports.
- Verification performed (e.g. Debug build, manual Settings path).
- Documentation updated.
- Risks, skipped checks, follow-up decisions.
