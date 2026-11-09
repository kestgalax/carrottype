# Roadmap

## Current Status

Milestone 0–2 vertical slice shipped; **GitHub Release `v0.5.0`**: signed in-app GitHub updates (ADR-017). **v0.4.0**: Ultra-only dictation, explicit migration and optional legacy-model cleanup (ADR-016). **v0.3.10**: dictation recovery, clipboard safety, visible errors and helper IPC reliability. **v0.3.9**: parallel Wave Link unmute + live-draft auto language / silence hygiene. **v0.3.8**: Storage UX — installed packages + catalog-scoped HF download cache clear. **v0.3.7**: Secure Coding hardening (ADR-015). **v0.3.6**: recorder-first live draft. **v0.3.5**: Escape cancel Copy capsule. **v0.3.4** live draft (ADR-014). **v0.3.3** Parakeet Ultra. **v0.3.2** Statistics characters + WPM. **v0.3.1** hid DMG folders. **v0.3.0** usage stats (ADR-013). **v0.2.2** Walkie-talkie. **v0.2.1** custom DMG window. **v0.2.0** Selection Transform (ADR-012).

Latest published artifact: `CarrotType-0.5.0.dmg` (SHA-256 `89eefeffc3eecf97614ffc91c2461a907ae2d3603d52980d37a6dfb0a99c863c`); signed ZIP/appcast hashes in `docs/github-release-notes-v0.5.0.md`.

**Release acceptance:** 0.5.0 (25) Debug delivered; the user explicitly instructed publication on 2026-11-10 and separately authorized public repository code/history. Release verification and remaining UI/TCC limits: [record](debug-review-v0.5.0.md). Previous 0.4.0 was published after its own manual Debug acceptance.

**Current focus:** 0.5.0 (25) GitHub updates is [published](https://github.com/kestgalax/carrottype/releases/tag/v0.5.0): opt-in Sparkle checks/downloads, signed feed/archive and deferred installation (ADR-017). Debug delivery, explicit publication authorization, clean Release packaging, native isolated A → B/negative checks and authenticated draft/anonymous public asset verification completed. Native Sparkle accepted the live public feed and reported no newer version as expected. Individual manual TCC results were not independently established. Next: setup/settings (`0.6.0`), then lifecycle/tests (`0.6.1`). [Execution plan](superpowers/plans/2026-11-09-product-improvements.md). Each future version still requires its own Debug build and explicit acceptance before publication.

Privacy / supply-chain governance: `.ai/constraints.md` + `docs/security/`. Full offline network audit (Little Snitch / airplane) remains deferred.

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
- [x] Smart idle footprint: MLX `Memory.clearCache()` on unload + unload when leaving Smart; formatting footer marks Smart as optional.
- [x] Storage: Active/Unused markers on installed packages (aligned with delete-unused).
- [x] Optional Whisper Turbo q5 (ggml) + SHA-256 verify for ggml packages.
- [x] Release `.dmg` build script (`macos/scripts/build-release-dmg.sh`) without notarization + Gatekeeper install docs (`ops/deploy.md`).
- [x] Custom Finder window for the Release `.dmg` (background + drag arrow) — `docs/superpowers/specs/2026-08-18-dmg-installer-design.md`.
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
- [x] Publish GitHub Release `v0.1.5` — Smart idle MLX cache clear + Storage Active/Unused + Smart+ RAM blurb + `docs/github-release-notes-v0.1.5.md`.
- [x] Out-of-process Smart cleanup helper (`CarrotTypeCleanupHelper`, ADR-009) — host no longer links MLX inference; helper exits after each Smart session.
- [x] Publish GitHub Release `v0.1.6` — OOP Smart cleanup + `docs/github-release-notes-v0.1.6.md`.
- [x] Publish GitHub Release `v0.1.7` — Status Capsule session chrome + `docs/github-release-notes-v0.1.7.md`.
- [x] Publish GitHub Release `v0.1.8` — idle menu bar icon `waveform.badge.microphone` + `docs/github-release-notes-v0.1.8.md`.
- [x] Optional Gemma 4 E2B cleanup package beside Qwen Smart/Smart+ (ADR-010).
- [x] Publish GitHub Release `v0.1.9` — optional Gemma cleanup + literal prompt + `docs/github-release-notes-v0.1.9.md`.
- [x] Public MIT distribution posture (ADR-011) — `LICENSE`, README branding/install notes; notarization not required for visibility.
- [x] Publish GitHub Release `v0.2.0` — Selection Transform bindings + bidirectional Translate (ADR-012) + `docs/github-release-notes-v0.2.0.md`.
- [x] Publish GitHub Release `v0.2.1` — custom DMG install window + `docs/github-release-notes-v0.2.1.md`.
- [x] Publish GitHub Release `v0.2.2` — Walkie-talkie dictation mode + `docs/github-release-notes-v0.2.2.md`.
- [x] Publish GitHub Release `v0.3.0` — local opt-in usage statistics (ADR-013) + `docs/github-release-notes-v0.3.0.md`.
- [x] Publish GitHub Release `v0.3.1` — hide DMG packaging folders (`.background` / `.fseventsd`) + `docs/github-release-notes-v0.3.1.md`.
- [x] Publish GitHub Release `v0.3.2` — Statistics character total + WPM above Bindings + `docs/github-release-notes-v0.3.2.md`.
- [x] Optional Parakeet Ultra STT beside v3 (ADR-006, FluidAudio 0.17.7). Catalog default stays v3.
- [x] Publish GitHub Release `v0.3.3` — optional Parakeet Ultra + `docs/github-release-notes-v0.3.3.md`.
- [x] Live dictation draft via offline re-transcribe preview (ADR-014) — Capsule adapts with full context; dynamic size; paste on stop via WAV; default off.
- [x] Publish GitHub Release `v0.3.4` — live draft + `docs/github-release-notes-v0.3.4.md`.
- [x] Live-draft Escape cancel → Copy capsule (non-empty preview, no paste; 5 s auto-dismiss; ADR-014 / F-004) — implemented on `feat/live-draft-cancel-copy`.
- [x] Settings → General: per-toggle caption hints (Walkie-talkie, clipboard retain, live draft + Escape Copy note).
- [x] Publish GitHub Release `v0.3.5` — live-draft cancel Copy + Settings hints + `docs/github-release-notes-v0.3.5.md`.
- [x] Live draft recorder-first session start (ADR-014 / F-004) — mic/WAV before Parakeet load; concurrent attach; cancel or a newer start invalidates the in-flight Parakeet `start` before it can publish (v0.3.6) — `feat/live-draft-recorder-first`.
- [x] Publish GitHub Release `v0.3.6` — recorder-first live draft + `docs/github-release-notes-v0.3.6.md`.
- [x] Secure Coding / OWASP Mobile Top 10 pass — checklist + supply-chain docs, helper path jail, MLX `hubRevision`, clipboard restore/copy, notarization prep (ADR-015) — `feat/secure-coding-hardening`.
- [x] Publish GitHub Release `v0.3.7` — security hardening + `docs/github-release-notes-v0.3.7.md`.
- [x] Storage UX — two-section pane + catalog-scoped HF download cache clear (`feat/storage-cache-ux`).
- [x] Publish GitHub Release `v0.3.8` — Storage cache UX + `docs/github-release-notes-v0.3.8.md`.
- [x] Parallel Wave Link unmute + live-draft language/silence fixes (ADR-007 / ADR-014) — `feat/unmute-live-draft-latency`.
- [x] Publish GitHub Release `v0.3.9` — unmute latency + live draft hygiene + `docs/github-release-notes-v0.3.9.md`.
- [x] Publish GitHub Release `v0.3.10` — last-result recovery, clipboard safety, persistent errors, helper transport hardening; all Debug manual checks accepted; verified Release DMG + `docs/github-release-notes-v0.3.10.md`.
- [x] Publish GitHub Release `v0.4.0` — Ultra-only STT, explicit preference migration, optional confirmed legacy-file cleanup; Debug manual checks accepted; clean Release DMG verified + `docs/github-release-notes-v0.4.0.md`.
- [ ] Optional: notarized GitHub Release (Apple Developer ID) — trust polish only, not a publish gate; prep scripts ready, credentials not yet available.

Status: **v0.5.0 self-signed/unnotarized DMG and signed update assets published** on GitHub Releases.

## Next focus (ordered)

The task breakdown, files, acceptance criteria, verification and ADR gates are in the [2026-11-09 improvement plan](superpowers/plans/2026-11-09-product-improvements.md).

Preserve existing useful features throughout these stages. Removing, hiding or reducing a feature requires specific user agreement; the agreed Ultra-only STT scope does not authorize removing other capabilities.

1. [x] **0.3.10 — Reliability:** clipboard ownership/restore, last-result recovery, visible session errors, robust cleanup helper IPC (R1–R4).
2. [x] **0.4.0 — Ultra-only dictation:** quality-note Result + catalog ADR, simplified model UI/runtime, explicit migration and optional legacy-weight removal (M1–M3). Qwen/Gemma remain for formatting/transform.
3. [x] **0.5.0 — GitHub app updates:** Sparkle ADR + explicit network sinks, signed update archives, appcast, update UI and staging upgrade verification (U1–U3). Published after Debug delivery, explicit publication authorization, clean Release and remote artifact/signature checks; independent manual TCC continuity remains unverified. First updater-enabled installation is manual; publishing is a separate instruction.
4. [ ] **0.6.0 — Setup/settings:** guided readiness and trial dictation, compact transform bindings, visible formatting fallback (X1–X3).
5. [ ] **0.6.1 — Maintainability:** session lifecycle coordinator and production-code regression tests/CI (C1–C2).
6. **Optional trust:** when Developer ID exists — sign + `notarytool` + staple (`ops/deploy.md` / `notarize-dmg.sh`); sign both host and helper. Not a prerequisite to begin updater integration; unsigned upgrade/TCC behavior must be tested.
7. Post-v1 spikes when useful (`docs/research-post-v1-spikes.md`): Sotto cleanup, Qwen3-ASR, etc.

## In progress / on branch

- 0.5.0 published from `feat/github-app-updates`; release closeout integrates this stage through PR #21. No 0.6.0 implementation has started.

## Near-term polish candidates (if release is blocked)

Small, user-visible fixes that do not expand scope:

- [x] Settings sidebar panes (General / Setup / Models / Storage) + Status header + chrome polish — `docs/superpowers/specs/2026-07-23-settings-sidebar-design.md` (shipped in v0.1.3).
- [x] Default hotkey ⌥/ (shipped in v0.1.3; Reset in Settings if an old chord was saved).
- [x] Status Capsule session chrome (Listening → Understanding → Writing → Inserted) — `docs/superpowers/specs/2026-07-24-status-capsule-design.md` (replaces notch REC/waveform island).
- Historical Whisper Small / Turbo download validation retired by ADR-016 in 0.4.0; no longer a current release task.
- Menu-bar remaining-hints refresh after language change (if any stale copy remains).
- [x] Recommended STT is Parakeet (first-run CTA targets Parakeet when not Ready).
- [x] Optional Gemma 4 E2B formatting package (ADR-010) — download / Make active / Delete beside Smart/Smart+.
- [x] Walkie-talkie / hold-to-talk dictation mode (Settings toggle, default off; same dictation hotkey).
- [x] Local opt-in time-saved statistics (ADR-013) — Settings → Statistics; month estimates; WPM default 50; per-binding transform counts (shipped in v0.3.0).
- Sparkle app updates shipped in `0.5.0` (U1–U3), with native check action replacing the old Releases link. Released with the maintainer’s explicit authorization. Developer ID/notarization remains separate.

## Post-v1 research spikes (no runtime yet)

- **Cleanup:** Sotto LFM2.5-350M MLX (EN dictation cleanup, low rewrite) vs Qwen3 1.7B for RU.
- **STT quality tier:** Qwen3-ASR 0.6B MLX beside Ultra (research only; new runtime/offerings require an ADR).
