# Roadmap

## Current Status

Milestone 0–2 vertical slice shipped; **private GitHub Release `v0.1.4`** (unsigned DMG, invite-only): Parakeet recommended STT; optional Apple SpeechAnalyzer (ADR-008); Models Delete + Storage per-package breakdown; Settings sidebar from v0.1.3.

Latest artifact: `CarrotType-0.1.4.dmg` on the private Release (SHA-256 in `docs/github-release-notes-v0.1.4.md`).

**Current focus:** notarization after Apple Developer ID; public distribution only after that.

Privacy / supply-chain agent governance lives in `.ai/constraints.md` (§ Privacy / network / dependencies). A full security pass / offline network audit is **deferred** — not current focus.

## Milestone 0: Product Intent

Goal: clarify why the project exists and what success means.

Exit criteria:

- `docs/product-intent.md` describes the hotkey → record → local STT → caret paste loop.
- Non-goals exclude voice studio / cloud-first scope.

Status: **Done**

## Milestone 1: Architecture Decision

Goal: decide the initial architecture and runtime stack through ADRs.

Status: **Done** — ADR-002 Accepted (native Swift macOS + on-device STT). `docs/architecture.md` updated.

## Milestone 1.5: Dev Environment

Goal: define the local development environment for the accepted stack.

Checklist:

- [x] Local runtime and package manager are selected (Xcode / Swift / SPM).
- [x] `ops/environments.md` documents local/test environments.
- [x] Model catalog + cleanup policy accepted (`ADR-003`, `docs/specs/ux-setup-status.md`).
- [x] `ops/ci.md` documents governance checks for CI.
- [x] Xcode app skeleton exists (`macos/CarrotType`, XcodeGen `project.yml`).

Status: **Done**

## Milestone 2: First Feature

Goal: deliver the first traced feature through AIDOS workflow (`docs/specs/features/hotkey-carrottype-caret-paste.md`), including Setup status for models and permissions.

Checklist:

- [x] Real HTTPS download of ggml Whisper into Application Support (progress / cancel).
- [x] On-device STT via WhisperMetalKit (ADR-004).
- [x] Hotkey toggle → record → transcribe → Light cleanup → caret paste (⌘V + Accessibility).
- [x] Parakeet STT runtime via FluidAudio CoreML (ADR-006) + catalog download.
- [x] Qwen3 Smart/Smart+ cleanup via MLX (ADR-005) + idle unload / Settings-scoped mic meter.
- [x] Optional Whisper Turbo q5 (ggml) + SHA-256 verify for ggml packages.
- [x] Release `.dmg` build script (`macos/scripts/build-release-dmg.sh`) without notarization + Gatekeeper install docs (`ops/deploy.md`).
- [x] Clean Parakeet/Whisper package delete (FluidAudio sibling layout) + select-only-when-ready UX.
- [x] Settings copy polish (dictation model / post-dictation formatting) + optional retain-in-clipboard + RU/EN localization.
- [x] «Make active» on Ready STT packages (same pattern as post-dictation formatting).
- [x] Reliable Whisper ggml download (stage temp file before URLSession cleanup) — fixes Small/Turbo move errors.
- [x] Language switch no longer remounts Settings / kills the mic meter.
- [x] Publish GitHub Release `v0.1.0` with DMG + `docs/github-release-notes-v0.1.0.md`.
- [x] Publish GitHub Release `v0.1.1` — experimental Wave Link unmute during dictation (ADR-007) + `docs/github-release-notes-v0.1.1.md`.
- [x] Publish GitHub Release `v0.1.2` — Escape cancel / soft silent cancel + Status version + Check for updates + `docs/github-release-notes-v0.1.2.md`.
- [x] Publish GitHub Release `v0.1.3` — Settings sidebar + default hotkey ⌥/ + window chrome polish + `docs/github-release-notes-v0.1.3.md`.
- [x] Optional Apple SpeechAnalyzer STT (ADR-008) — catalog `stt.apple-speechanalyzer`, macOS 26+, Prepare assets (not recommended).
- [x] Flip catalog `recommended` STT to Parakeet TDT 0.6B v3 (`docs/stt-ru-en-quality-note.md`).
- [x] Publish GitHub Release `v0.1.4` — Parakeet recommended + Apple SpeechAnalyzer + Models/Storage polish + `docs/github-release-notes-v0.1.4.md`.
- [ ] Notarized GitHub Release (blocked on Apple Developer ID purchase).

Status: **v0.1.4 on private Release (unsigned DMG)** — invite-only download; install via Right-click → Open until notarization.

## Next focus (ordered)

1. **Trust:** after Apple Developer purchase — Developer ID sign + `notarytool` + staple (`ops/deploy.md`).
2. **Only then** post-v1 spikes (`docs/research-post-v1-spikes.md`): Sotto cleanup, Qwen3-ASR, etc.

## Near-term polish candidates (if release is blocked)

Small, user-visible fixes that do not expand scope:

- [x] Settings sidebar panes (General / Setup / Models / Storage) + Status header + chrome polish — `docs/superpowers/specs/2026-07-23-settings-sidebar-design.md` (shipped in v0.1.3).
- [x] Default hotkey ⌥/ (shipped in v0.1.3; Reset in Settings if an old chord was saved).
- Confirm Whisper Small / Turbo download end-to-end on a clean Application Support folder.
- Menu-bar remaining-hints refresh after language change (if any stale copy remains).
- [x] Recommended STT is Parakeet (first-run CTA targets Parakeet when not Ready).
- Sparkle (or similar) auto-update after Developer ID / public or auth feed — Status currently only opens Releases.

## Post-v1 research spikes (no runtime yet)

- **Cleanup:** Sotto LFM2.5-350M MLX (EN dictation cleanup, low rewrite) vs Qwen3 1.7B for RU.
- **STT quality tier:** Qwen3-ASR 0.6B MLX beside Parakeet / Turbo.
