# Workflow

```text
Idea -> Product Intent -> ADR Gate -> Feature/Tasks -> Implementation -> Review -> Release
```

## Current phase (after v0.3.1)

Unsigned DMG on GitHub Releases; source under MIT (ADR-011). Repository is **public**.

Next ordered focus:

1. Optional later: Developer ID sign + notarize (`ops/deploy.md`) for one-click Gatekeeper UX.
2. Post-v1 research spikes when useful (`docs/research-post-v1-spikes.md`).

## Phase gates

### Product intent

- Changes to mission / non-goals update `docs/product-intent.md` and roadmap.

### ADR gate

- New STT/cleanup engine, catalog policy, or distribution trust model → ADR before code.
- New outbound network sink, telemetry/analytics, or direct SPM product dependency → ADR before code (closed sinks in `.ai/constraints.md`).
- Accepted ADRs: ADR-002 (stack), ADR-003 (catalog), ADR-004 (Whisper), ADR-005 (Qwen), ADR-006 (Parakeet), ADR-007 (Wave Link unmute), ADR-008 (Apple SpeechAnalyzer STT), ADR-009 (OOP cleanup), ADR-010 (Gemma cleanup), ADR-011 (public MIT distribution), ADR-012 (selection transform), ADR-013 (local usage stats).

### Feature / Settings UX

- Setup UI follows `docs/specs/ux-setup-status.md` (Ready rules, Make active, L10n, mic meter).
- Language changes must not remount Settings in a way that kills the mic meter.

### Implementation

- Use Developer role (`.ai/developer.md`); keep diffs small and traced to roadmap/spec/ADR.

### Review

- Use Reviewer role (`.ai/reviewer.md`) before calling work complete.

### Release

- Build via `macos/scripts/build-release-dmg.sh`; notes in `docs/github-release-notes-v0.1.0.md`.
- Attach DMG to GitHub Release; do not commit `dist/` to git.
