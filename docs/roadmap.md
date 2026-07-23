# Roadmap

## Current Status

Milestone 0–2 vertical slice shipped as **private GitHub Release `v0.1.0`** (unsigned DMG, invite-only): hotkey → on-device STT → optional formatting → caret paste, multi-engine catalog, RU/EN Settings.

Latest artifact: `CarrotType-0.1.0.dmg` on the private Release (SHA-256 in `docs/github-release-notes-v0.1.0.md`).

**Current focus:** fill the STT quality note before flipping `recommended`; notarization after Apple Developer ID; public distribution only after that.

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
- [ ] Notarized GitHub Release (blocked on Apple Developer ID purchase).
- [ ] Flip `recommended` STT only after filling `docs/stt-ru-en-quality-note.md`.

Status: **v0.1.0 on private Release (unsigned DMG)** — invite-only download; install via Right-click → Open until notarization.

## Next focus (ordered)

1. **Quality gate:** fill `docs/stt-ru-en-quality-note.md` (RU/EN Base vs Small vs Turbo vs Parakeet); then decide `recommended`.
2. **Trust:** after Apple Developer purchase — Developer ID sign + `notarytool` + staple (`ops/deploy.md`).
3. **Only then** post-v1 spikes (`docs/research-post-v1-spikes.md`): Sotto cleanup, Qwen3-ASR, etc.

## Near-term polish candidates (if release is blocked)

Small, user-visible fixes that do not expand scope:

- Confirm Whisper Small / Turbo download end-to-end on a clean Application Support folder.
- Menu-bar remaining-hints refresh after language change (if any stale copy remains).
- First-run CTA clarity when Parakeet is already Ready but Whisper Base is still `recommended`.
- **Temporary mic unmute (ADR-007):** implemented on branch `feature/mic-unmute-on-dictation` — Settings toggle + `MicMuteController` (Core Audio / Wave Link hybrid). Merge after Wave:3 checklist in `docs/research-mic-unmute-spike.md`.

## Post-v1 research spikes (no runtime yet)

- **Cleanup:** Sotto LFM2.5-350M MLX (EN dictation cleanup, low rewrite) vs Qwen3 1.7B for RU.
- **STT quality tier:** Qwen3-ASR 0.6B MLX beside Parakeet / Turbo.
- Mic unmute hardware verification: see `docs/research-mic-unmute-spike.md` (feature branch).
