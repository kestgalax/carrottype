# Roadmap

## Current Status

Milestone 0–2 vertical slice shipped; **GitHub Release `v0.7.0`**: native settings, accessibility/confirmation polish and selected carrot-microphone A brand. **v0.6.2**: coordinated dictation lifecycle, awaited teardown and generation-safe live draft; production regressions. **v0.6.1**: offline What’s New, structured localized signed update notes and persistent version access. **v0.6.0**: guided setup/local trial, compact bindings and formatting feedback. **v0.5.0**: signed in-app GitHub updates (ADR-017). **v0.4.0**: Ultra-only dictation, explicit migration and optional legacy-model cleanup (ADR-016). **v0.3.10**: dictation recovery, clipboard safety, visible errors and helper IPC reliability. **v0.3.9**: parallel Wave Link unmute + live-draft auto language / silence hygiene. **v0.3.8**: Storage UX — installed packages + catalog-scoped HF download cache clear. **v0.3.7**: Secure Coding hardening (ADR-015). **v0.3.6**: recorder-first live draft. **v0.3.5**: Escape cancel Copy capsule. **v0.3.4** live draft (ADR-014). **v0.3.3** Parakeet Ultra. **v0.3.2** Statistics characters + WPM. **v0.3.1** hid DMG folders. **v0.3.0** usage stats (ADR-013). **v0.2.2** Walkie-talkie. **v0.2.1** custom DMG window. **v0.2.0** Selection Transform (ADR-012).

Latest published artifact: `CarrotType-0.7.0.dmg` (SHA-256 `4dc08cdda9958cf3438f3c55a72e39c513488dbceb99f17b6f3b7af6cbfe6a8d`); signed ZIP/appcast hashes in `docs/github-release-notes-v0.7.0.md`.

**Release acceptance:** after signed Debug 0.7.0 (29) review, the maintainer retained original carrot-microphone A and instructed «публикуй тогда версию» on 2026-11-10. Final icon Debug rebuilt and verified before Release. Individual device/TCC/manual results were not enumerated. Clean Release/DMG, local/downloaded draft/public signatures/digests passed; isolated updater and native build-28 discovery passed without user installation. [Acceptance/evidence/limits](debug-review-v0.7.0.md).

**Current focus:** [0.7.0 published](https://github.com/kestgalax/carrottype/releases/tag/v0.7.0), source/tag `2bb5555` / `v0.7.0`, PR #25. Reviewed native interface A and final carrot-microphone A shipped after signed Debug and explicit publication authorization. Fresh clean Release/DMG, isolated updater, downloaded draft/public signatures/digests and native stable-feed discovery passed. [Final-source hosted app CI](https://github.com/kestgalax/carrottype/actions/runs/42828835461) passed; hosted AIDOS explicitly skipped, local governance passed. [Evidence/limits](debug-review-v0.7.0.md). All planned stages through D3 are shipped; collect feedback before selecting further scope. Independent full native/VoiceOver/device/TCC/network coverage remains unverified.

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
4. [x] **0.6.0 — Setup/settings:** X1–X3 published (26) after user Debug acceptance, clean Release and signed local/draft/public asset verification. Guided readiness/local trial, compact bindings, visible formatting fallback; all existing functions retained.
5. [x] **0.6.1 — Update presentation:** structured CarrotType release notes, styled signed inline Sparkle notes and offline installed-version What’s New with a persistent button/unread badge (N1–N3). [Task](specs/tasks/update-release-notes-ux.md). Published (27) after its own user Debug acceptance and clean Release/local/draft/public signature/digest verification. Independent interactive/TCC limits remain recorded.
6. [x] **0.6.2 — Maintainability:** C1–C2 released as (28) after explicit Debug/publication authorization and verified clean Release/DMG/signed draft/public assets. Hosted app checks and Debug CI compilation passed; hosted AIDOS explicitly skipped without private tooling access, local governance passed. [Task](specs/tasks/dictation-session-lifecycle.md), [checklist/evidence](debug-review-v0.6.2.md).
7. [x] **0.7.0 — UI/UX and brand:** D1/D2 discussion and D3 native UI, accessibility/confirmation, shared formatting and final carrot-microphone A delivered. Published (29) after signed Debug acceptance/explicit authorization, clean Release and local/draft/public signed-asset verification. Final-source hosted app checks/build pass; useful functions retained. [Task](specs/tasks/uiux-and-brand-refresh.md), [evidence](debug-review-v0.7.0.md).
8. **Optional trust:** when Developer ID exists — sign + `notarytool` + staple (`ops/deploy.md` / `notarize-dmg.sh`); sign both host and helper. Not a prerequisite to begin updater integration; unsigned upgrade/TCC behavior must be tested.
9. Post-v1 spikes when useful (`docs/research-post-v1-spikes.md`): Sotto cleanup, Qwen3-ASR, etc.

## In progress / on branch

- `feat/native-ui-brand-0.7`, PR #25: 0.7.0 (29) published from `v0.7.0` / `2bb5555`; reviewed native interface A and final carrot-microphone A. Source CI passed; final documentation-only closeout leaves app/workflow unchanged. Initial exploration and subsequent alternatives retained.

- `refactor/dictation-session-lifecycle`, PR #24 merged: 0.6.2 (28) published from tag `14dacf3` after authorized Debug and verified Release/assets. CI-only correction handles private AIDOS without publishing tooling or installing broad credentials; hosted app checks and Debug compile passed (run `42815581126`). Next: 0.7.0 UI/UX/logo discussion.

- `feat/update-release-notes-ux`, PR #23: 0.6.1 (27) published after accepted Debug and verified Release/assets (`docs/debug-review-v0.6.1.md`). Planning commits retained. Next: 0.6.2 lifecycle, then 0.7.0 UI/UX/logo.
- Previous `feat/setup-and-settings-polish`, PR #22 merged: X1–X3 released as v0.6.0; acceptance/release evidence in `docs/debug-review-v0.6.0.md`. Unrelated local research/cache files remain untouched.

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

### 0.7.0 final brand/release authorization

Maintainer accepted the UI and selected the original carrot-microphone A after a second icon comparison, explicitly instructing «публикуй тогда версию». Plain geometric carrot superseded; concept history retained. Final icon Debug rebuild and clean Release, signed update/DMG verification are in progress before publication. No authorization is inferred for future versions.

## 0.7.0 published — 2026-11-10

Maintainer accepted Debug UI and explicitly selected the original carrot-microphone A from the second comparison, then authorized publication: «оставляем изначальный / согласен / публикуй тогда версию». Stable/latest **0.7.0 (29)** published from tag/source `v0.7.0` / `2bb5555`, PR #25. Final signed Debug and fresh clean Release/DMG pass; signed ZIP/feed and downloaded draft/public assets pass signatures, metadata, lengths, URLs and exact local byte hashes. Anonymous stable feed/archive match. Native Sparkle probe using isolated build-28 host found the live update without installation. Isolated candidate-code A28→B29 installer and negative scenarios passed; not independent historical-binary/TCC proof. Final-source hosted app CI passed (runs `42828743848` and `42828835461`); private hosted AIDOS explicitly skipped, local validate/trace/review passed. No user installation/data replacement, key export, new engine/dependency/trust or feature removal. Full independent device/VoiceOver/TCC/network checks remain unverified. Artifact hashes: `docs/github-release-notes-v0.7.0.md`; acceptance/limits: `docs/debug-review-v0.7.0.md`. Next: collect feedback; no further implementation stage selected. Later releases retain their own Debug/manual/publication gate.

## Proposed 0.8.0 — post-dictation models and rules (2026-11-10)

Maintainer explicitly confirmed Qwen3 0.6B + Gemma and removing Smart+ from the offered choice. [Code/prompt audit and staged proposal](2026-11-10-post-dictation-formatting-audit.md): preserve Off/Light and existing Smart+ weights/bindings via compatibility; add bounded dictation preferences without replacing transform instructions, repair unsafe Light cleanup/truncation/empty handling and correct Gemma metadata. P1 catalog ADR → P2 prompt/runtime integrity → P3 settings/text trial + independent System/Light/Dark theme preference (System by default) → P4 quality/theme evaluation/signed Debug. Model choice and theme selector/default are explicitly requested; detailed rules UI/migration are proposed. No runtime change or new release yet; full LLM quality/latency evaluation not run.

## Proposed 0.9.0 — one additional dictation engine (2026-11-10)

Maintainer requested alternatives to Ultra as a separate stage/version after 0.8.0. [Current-source research and S1–S4 plan](2026-11-10-dictation-alternatives.md): maintainer subsequently narrowed the stage to **Ultra vs GigaAM v3 only**. Assess v3 E2E CTC/RNNT native feasibility, Russian quality/latency and mixed-language limitations; other ASR families and GigaAM Multilingual are outside active scope. No measured winner, runtime change, weight download or release yet. Ultra remains default; target at most one extra offered engine only after demonstrated benefit, user direction and Accepted ADR replacing the relevant ADR-016 constraint. Benchmark → discuss tradeoff/select → native integration → signed Debug/manual/explicit publication gate. 0.8.0 keeps postprocessing/rules/theme separate.

0.9.0 architecture feasibility: [GigaAM static/API check](2026-11-10-gigaam-architecture-fit.md), upstream SDK `95bd42a` (29 sources) typechecks against current Debug dependencies, MLX 0.31.6/macOS 14 manifest compatible. Main pipeline/session/delivery architecture can remain; routing/catalog and helper/cancellation/live-draft/longform integration still required. No full resolve/link/inference or measured quality/memory claim.
