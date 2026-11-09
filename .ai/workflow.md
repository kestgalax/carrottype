# Workflow

```text
Idea -> Product Intent -> ADR Gate -> Feature/Tasks -> Implementation -> Review -> Release
```

## Current phase (after v0.3.10)

Unsigned DMG on GitHub Releases; source under MIT (ADR-011). Repository is **public**. v0.3.9 parallel unmute + live-draft hygiene; Storage download-cache clear in v0.3.8; security hardening (ADR-015) in v0.3.7; live draft (ADR-014) through v0.3.4–v0.3.6.

Next ordered focus:

1. Staged improvements: reliability → Ultra-only dictation → GitHub app updates → setup/settings → lifecycle/tests. Target versions and acceptance criteria: [`2026-11-09-product-improvements.md`](../docs/superpowers/plans/2026-11-09-product-improvements.md). Reliability `0.3.10 (23)` was published after the user accepted every Debug manual checklist item and clean Release DMG verification passed. Next: Ultra-only dictation with its own Debug acceptance gate.
2. Optional later: Developer ID sign + notarize (`ops/deploy.md` / `notarize-dmg.sh`) when credentials exist. Updater integration has its own ADR/network gate and unsigned-upgrade verification; notarization is not a prerequisite to begin it.
3. Post-v1 research spikes when useful (`docs/research-post-v1-spikes.md`).

## Phase gates

### Product intent

- Changes to mission / non-goals update `docs/product-intent.md` and roadmap.

### ADR gate

- New STT/cleanup engine, catalog policy, or distribution trust model → ADR before code.
- New outbound network sink, telemetry/analytics, or direct SPM product dependency → ADR before code (closed sinks in `.ai/constraints.md`).
- Accepted ADRs: ADR-002 (stack), ADR-003 (catalog), ADR-004 (Whisper), ADR-005 (Qwen), ADR-006 (Parakeet), ADR-007 (Wave Link unmute), ADR-008 (Apple SpeechAnalyzer STT), ADR-009 (OOP cleanup), ADR-010 (Gemma cleanup), ADR-011 (public MIT distribution), ADR-012 (selection transform), ADR-013 (local usage stats), ADR-014 (live dictation streaming), ADR-015 (hub revision + helper path jail).

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
