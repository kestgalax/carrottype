# Roadmap

## Current Status

Milestone 0–2 vertical slice shipped; **GitHub Release `v0.8.2`**: cumulative release notes across skipped versions. **v0.8.1**: opt-in launch at macOS sign-in. **v0.8.0**: exact dictation rules including first-sentence lowercase, text trial, two offered cleanup models and System/Light/Dark. **v0.7.0**: native settings, accessibility/confirmation polish and selected carrot-microphone A brand. **v0.6.2**: coordinated dictation lifecycle, awaited teardown and generation-safe live draft; production regressions. **v0.6.1**: offline What’s New, structured localized signed update notes and persistent version access. **v0.6.0**: guided setup/local trial, compact bindings and formatting feedback. **v0.5.0**: signed in-app GitHub updates (ADR-017). **v0.4.0**: Ultra-only dictation, explicit migration and optional legacy-model cleanup (ADR-016). **v0.3.10**: dictation recovery, clipboard safety, visible errors and helper IPC reliability. **v0.3.9**: parallel Wave Link unmute + live-draft auto language / silence hygiene. **v0.3.8**: Storage UX — installed packages + catalog-scoped HF download cache clear. **v0.3.7**: Secure Coding hardening (ADR-015). **v0.3.6**: recorder-first live draft. **v0.3.5**: Escape cancel Copy capsule. **v0.3.4** live draft (ADR-014). **v0.3.3** Parakeet Ultra. **v0.3.2** Statistics characters + WPM. **v0.3.1** hid DMG folders. **v0.3.0** usage stats (ADR-013). **v0.2.2** Walkie-talkie. **v0.2.1** custom DMG window. **v0.2.0** Selection Transform (ADR-012).

Latest published artifact: `CarrotType-0.8.2.dmg` — SHA-256 `0d6bb879f769e94e7e157a59577377fb6768b8f126b9cc0862fd1012199ec3c7`; signed ZIP/feed hashes in [release notes](github-release-notes-v0.8.2.md).

**Release acceptance:** 0.8.2 (32) signed Debug accepted for publication («можно опубликовать»); stable published 2026-11-11 after clean Release and local/draft/public signature/digest/native-update verification. Individual manual results not enumerated. [Evidence/limits](debug-review-v0.8.2.md).

**Current focus:** Dynamic Island settings implemented on a fresh main-based Debug branch for Codex review (dedicated pane, Full/default + Minimal + Menu-bar-only dictation modes, preserved preferences, transform/recovery results). D1–D3 delivered; signed Debug and automated/native evidence prepared. Debug acceptance/publication and version selection remain separate. GigaAM deferred.

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

## 0.8.0 — post-dictation rules and theme (quality rework required)

Next focus: [R1–R4 completion proposal](superpowers/plans/2026-11-10-formatting-rework.md), requested after the real Gemma trial failed acceptance. Acceptance cases/ADR → deterministic word/case/final-period controls → separately assessed business style and stage outcomes → signed Debug/manual acceptance. Proposal only; no new implementation claimed. Safe Light fallback is not successful rule compliance. Preserve other 0.8 work/settings/functions; stable remains 0.7.0 and no publication is authorized.

Maintainer confirmed Qwen3 0.6B + Gemma, requested System/Light/Dark and authorized the nearest stage. P1–P3 implemented: catalog compatibility/ADR-018, shared rules/purpose-v3/budgeting/integrity checks and safer Light, General controls/text-only trial/theme. P4 local production/native regressions and installed-Gemma synthetic evaluation run; Debug 0.8.0 (30) prepared for manual review. Existing models/data/features retained. Qwen absent (no hidden download), full comparative latency/RAM/quality and interactive system-theme/VoiceOver/device/TCC checks remain unverified. Gemma still inconsistently follows self-correction/paragraph rules; observed protected-literal losses are rejected to visible Light fallback. [Task](specs/tasks/dictation-rules-and-theme.md), [evidence/limits](debug-review-v0.8.0.md). No 0.8 release authorization; 0.7.0 remains stable.

## Deferred — GigaAM v3 research (formerly proposed 0.9.0)

**Deferred at maintainer request on 2026-11-10; no target version/date.** Keep research/security findings for a future explicit resumption; do not proceed to downloads, runtime spike or integration automatically after 0.8.0. Near-term scope remains 0.8.0 postprocessing/rules/theme.

Historical proposal: Maintainer requested alternatives to Ultra as a separate stage/version after 0.8.0. [Current-source research and S1–S4 plan](2026-11-10-dictation-alternatives.md): maintainer subsequently narrowed the stage to **Ultra vs GigaAM v3 only**. Assess v3 E2E CTC/RNNT native feasibility, Russian quality/latency and mixed-language limitations; other ASR families and GigaAM Multilingual are outside active scope. No measured winner, runtime change, weight download or release yet. Ultra remains default; target at most one extra offered engine only after demonstrated benefit, user direction and Accepted ADR replacing the relevant ADR-016 constraint. Benchmark → discuss tradeoff/select → native integration → signed Debug/manual/explicit publication gate. 0.8.0 keeps postprocessing/rules/theme separate.

0.9.0 architecture feasibility: [GigaAM static/API check](2026-11-10-gigaam-architecture-fit.md), upstream SDK `95bd42a` (29 sources) typechecks against current Debug dependencies, MLX 0.31.6/macOS 14 manifest compatible. Main pipeline/session/delivery architecture can remain; routing/catalog and helper/cancellation/live-draft/longform integration still required. No full resolve/link/inference or measured quality/memory claim.

0.9.0 provenance/security follow-up: [third-party GigaAM port assessment](2026-11-10-gigaam-provenance-safety.md), conversion not independently reproduced; SDK model path confinement missing in a synthetic fixture, parser bounds review required. Add pinned official-source/reproducible conversion, asset allowlist/hash/path/bounds verification and isolated offline checks to S1. No weights downloaded, no security acceptance; helper process is not a sandbox.

### 0.8.0 Debug feedback — System theme

Maintainer reported that returning from forced Light/Dark to System did not visually apply. Reproduced in an isolated native SwiftUI host: AppKit/window reset to inherited appearance while SwiftUI retained Light. Removed the duplicate preferredColorScheme override; NSApplication appearance now owns the full theme. Native Settings-host regression checks rendered environment across repeated Light/Dark → System without remount; rebuilt signed Debug supplied in `dist/.builds.noindex/CarrotType-0.8.0-Theme-Fix/CarrotType.app`. Initial source hosted CI passed ([42868789703](https://github.com/kestgalax/carrottype/actions/runs/42868789703)); fix-source CI/manual recheck pending. Stable still 0.7.0, publication not authorized.

### 0.8.0 Debug feedback — Settings scrollbar

At the maintainer's request, hide the outer window scrollbar in every Settings Form (including Welcome/Details), keeping scrolling and nested text-editor indicators. Use SwiftUI `.scrollIndicators(.never)` for the outer Forms; `.hidden` still shows the native track under the current system preference. Text editors explicitly use automatic visibility. Debug compiled; isolated native RU/EN/light/dark layouts and scroll-container inspection verify hidden outer indicators with a still-changing content offset. No global macOS preference or content/navigation change. Current signed app: `dist/.builds.noindex/CarrotType-0.8.0-UI-Review/CarrotType.app`. Theme-fix hosted CI passed ([42874592078](https://github.com/kestgalax/carrottype/actions/runs/42874592078)); scrollbar-source CI/manual review pending. No publication authorization.

### 0.8.0 Debug feedback — combined Gemma rules

Maintainer requested rechecking four free-text rules (remove ну, no last full stop, lowercase, business tone), then supplied a text for local testing. Actual AppState.runFormattingTrial with installed Gemma confirms rule delivery; short rules apply partially, while combined/style edits remain unreliable and may lose punctuation/intent. Corrected conflicting prompt priority and made explicit style intent possible under content guards; rejected few-shot variants that contaminated unrelated rules. Added conservative existing-question-mark loss rejection and actual-mode/prominent fallback UI. Local production/native/build checks and real model trials recorded in `docs/2026-11-10-formatting-quality-0.8.0.md`; no claim that the four-rule combination is fixed. Raw maintainer text is not committed.

Open quality decision before relying on arbitrary combined rules: consider explicit structured controls for word deletion/case/final punctuation, with model-based tone separately assessed; no ad-hoc parser of natural-language rules or new engine selected. Signed Debug/manual and separate release authorization remain pending.


### 0.8.0 R1–R4 progress — exact controls delivered for review

R1/R2: backward-compatible persisted word/lowercase/final-period controls, shared pre/post processing under Off/Light/model/fallback, protected fragments and empty output. Typed failures and separate tone/unchanged/generated statuses; original transform error contract retained. Added real-AppState synthetic opt-in Gemma diagnostic and production/native regressions. Signed Debug app: `dist/.builds.noindex/CarrotType-0.8.0-Rules-Fix/CarrotType.app`; archive SHA-256 `dd2abeccc9993fa91c0b82a66dde9178cdbbbd8f0ab5c2bec706639c4f85a31b`. Old app installation and potentially running earlier Debug copies untouched.

R3 evaluated two prompt candidates: held-out RU restyling improved, but unchanged wording and rejection persist; supplied maintainer message produced an invented extra question, now rejected specifically for tone. Exact controls survive its Light fallback. No four-rule/style acceptance claim, no private text committed. R4 local build/signatures/native/layout/regressions/governance passed; hosted CI/manual review pending. Next: review exact-control Debug and resolve business-tone quality before declaring 0.8 release-ready. No new models/runtime/download/network/trust or useful-feature removal.


### 0.8.0 Debug addition — first sentence starts lowercase

At maintainer request add independent first-letter lowercase, default off/backward-compatible. Changes only the first letter after word/model/base/fallback processing; other letters and later sentence initials retain case. Protected leading code/link/technical data is untouched. Full-prose lowercase has priority; UI explains/disables redundant control without clearing it. Production tests cover RU/EN/quotes/newlines/emoji/digits/protected starts/persistence/precedence and Off/Light/fallback; Debug compiled. New signed review app: `dist/.builds.noindex/CarrotType-0.8.0-First-Lowercase/CarrotType.app`, leaving potentially running earlier review app untouched. Previous source d02c1e4 hosted CI passed (42888614542 and 42888536100); this addition has separate checks. No publication or whole-version manual acceptance inferred; business-tone quality remains open.


### 0.8.0 manual acceptance and publication authorization

After testing the exact controls and first-sentence initial option, maintainer instructed «ок, пока остановимся, хорошо получилось, давай релизить». This accepts the current signed Debug 0.8.0 (30) and authorizes publication of its current scope. Known business-tone limitations were disclosed before acceptance; retain the experimental/off-by-default control and do not claim R3 semantic quality passed. Earlier release-readiness blocks describe the pre-acceptance state; the maintainer now accepts this scope/limitation for release. Freeze application source at 0edde77; only release evidence/docs follow. Clean Release, signed local/draft/public asset verification and final-source CI remain required before publication. No authorization for later versions inferred.


## 0.8.0 published — 2026-11-11

Maintainer accepted the signed first-sentence Debug and authorized release: «ок, пока остановимся, хорошо получилось, давай релизить». Stable/latest **0.8.0 (30)** published on 2026-11-11 from tag/source `v0.8.0` / `819286a` (application code `0edde77`), PR #27. Known business-tone failures remain disclosed/experimental/off by default; release acceptance is not a semantic quality pass. Fresh clean Release arm64, signed host/helper/Sparkle, mounted DMG/layout/background, no bundled weights and real installed-Gemma Release helper smoke passed. Local governance passed; hosted regressions/Debug/actual native checks passed ([42891053801](https://github.com/kestgalax/carrottype/actions/runs/42891053801), [42891040649](https://github.com/kestgalax/carrottype/actions/runs/42891040649)); private hosted AIDOS explicitly skipped. Signed ZIP/feed and downloaded draft/public artifacts passed digests, signatures, lengths, identity/URLs; anonymous latest feed/archive match. Isolated A29→B30 install and negative cases passed; public native Sparkle probe found 0.8.0 from isolated build-29 metadata without installation. No user app/profile/model replacement or private-key export. Full independent device/TCC/VoiceOver/network and Qwen comparison remain unverified. Hashes: `docs/github-release-notes-v0.8.0.md`. Stop feature iteration per maintainer; collect feedback, no next stage selected; GigaAM stays deferred.


## 0.8.1 — launch at login (Debug review)

Maintainer requested a small startup patch for restart/power-on. Implemented opt-in General switch via native SMAppService.mainApp (ADR-019), truthful macOS enabled/pending/error status, refresh on General appearance/app activation and native settings action. No shadow saved Boolean or automatic registration; installation guard prevents disposable/DMG review paths from being registered. Existing entries can still be explicitly removed after moving an app. No helper/LaunchAgent, recording on login, model/runtime/dependency/network/trust change or useful-feature removal. `verify-launch-at-login.sh` exercises injected system adapter/policy without modifying real login items; Debug compiled. [Task](specs/tasks/launch-at-login.md), [manual checks/evidence](debug-review-v0.8.1.md). Installed-app self-signed registration and actual relogin/restart remain unverified until maintainer checks. Revised signed Debug accepted for publication by maintainer («публикуй»); clean Release and artifact verification in progress. Stable remains 0.8.0 until publication.


## 0.8.1 publication closeout

Maintainer accepted the revised signed Debug and instructed «публикуй». Stable/latest **0.8.1 (31)** published on 2026-11-11, tag/source `v0.8.1` / `d8e166b` (application code `fe2e9bc`), PR #28. Opt-in native launch at macOS sign-in lives at the bottom of General without persistent hints. Clean Release arm64, signed host/helper/Sparkle, final mounted DMG/resources/metadata/no weights and ZIP/feed signatures passed. Initial DMG creation returned Resource busy; checksum-verified 0.8.0 filesystem template reused with unchanged layout/background. Local governance and hosted final-app regressions/Debug/native checks passed (42983616038, 42983623123); private hosted AIDOS explicitly skipped. Isolated candidate-code A30→B31 install and negative checks passed, not historical-binary or TCC proof. Downloaded draft/public files matched digests/signatures/length/identity/URLs; anonymous latest feed/archive matched. Native isolated build-30 Sparkle probe found the live update without installation. No user installation/profile/model/login-item replacement or private-key export. Individual actual reboot/system-approval results were not enumerated; independent device/TCC/VoiceOver/network checks remain unverified. Hashes: `docs/github-release-notes-v0.8.1.md`; evidence: `docs/debug-review-v0.8.1.md`. Next: collect startup feedback, no further stage selected; GigaAM remains deferred. Later releases retain their own Debug/manual/publication gate.


## 0.8.2 — cumulative release notes (Debug review)

Implemented immutable bundled 0.6.1–0.8.1 history, offline previous-installed-build range persisted through relaunch/read, grouped native notes and explicit incomplete coverage. Signed inline Sparkle HTML filters installed/older notes through its documented native build marker and CSS; existing clients supported, unknown builds see available history/start. Current JSON schema/GitHub Markdown retained; no new dependency/network/trust/installer or dictation changes. Swift/Python range/escaping/schema tests, actual AppState regressions and Debug passed. Native pinned Sparkle WK with content JS disabled verified builds 31/27/26/unknown; native RU/EN light/dark sheet images inspected. Signed Debug and focused checklist: [review](debug-review-v0.8.2.md); [task](specs/tasks/cumulative-release-notes.md). Isolated signed A31→B32 installer and offline/tampered-feed/corrupt-archive/no-new-version checks passed; local governance passed; interactive/VoiceOver/TCC manual review remains. No publication authorization for this patch; stable 0.8.1.


## 0.8.2 publication closeout

Maintainer accepted the signed Debug and instructed «можно опубликовать». Stable/latest **0.8.2 (32)** published on 2026-11-11, tag/source `v0.8.2` / `62082f6` (application code `4f85180`), PR #29. All skipped structured release notes (history since 0.6.1) are grouped by release offline and in signed inline Sparkle HTML, using its native installed-build CSS marker; unknown/incomplete coverage is explicit. Clean Release arm64, inside-out signed host/helper/Sparkle, final read-only mounted DMG/resources/current+history/no weights and signed ZIP/feed passed. Finder layout automation denied (-1743); checksum-verified 0.8.1 installer filesystem reused with unchanged layout/background. Signed archive and both feed locales contain the same six release records; actual native pinned WK on signed-feed HTML filters builds 31/27/26/unknown with content JS disabled. Local governance and hosted final-app regressions/Debug/native checks passed (42995366888, 42995404697); private hosted AIDOS explicitly skipped. Isolated candidate-code A31→B32 install and negative checks passed, not historical-binary or TCC proof. Downloaded draft/public assets match local digests/signatures/length/identity/URLs; anonymous latest feed/archive match. Native isolated build-31 Sparkle probe finds the live update without installation. No user installation/profile/model/login-item edits or private-key export. Temporary indexed packaging copies removed after verification; retained app is noindex. Individual manual results not enumerated; full independent interactive/device/TCC/VoiceOver/network verification remains limited. Hashes: `docs/github-release-notes-v0.8.2.md`; evidence: `docs/debug-review-v0.8.2.md`. Collect feedback; no next stage selected, GigaAM deferred. Later releases retain separate Debug/manual/publication acceptance.

## Dynamic Island settings — implementation for review (no version assigned)

Maintainer approved the Codex design («согласовываю, давай делать мне нравится») and OpenCode implemented D1–D3 on the fresh main-based `kestgalax/dynamic-island-implementation` Orca worktree from `d0a4058`, including the authoritative spec commit `0b3e27c`. A new Settings pane directly after General owns `carrottype.dynamicIslandMode` (Full default for absent/invalid, Minimal, Menu bar only). The live-draft switch moved with its exact key/value, stays visible but disabled outside Full, and restores its saved choice. Session mode and effective preview are captured at start; Minimal/Menu-only make zero preview calls and have no Escape draft Copy, while stop still uses the WAV → STT → formatting → paste path. Transform processing/results and paste-failure recovery stay full in every mode; suppressed panels expose the last Light fallback in the menu and Details. Shared production policy plus actual AppState/coordinator fake-adapter tests, existing lifecycle/setup/reliability/catalog checks, offscreen RU/EN light/dark/minimum native snapshots and a signed arm64 Debug app are delivered under `dist/.builds.noindex/Dynamic-Island-Debug`. No engine/model/network/catalog/storage/history change, no version bump and no publication authorization. Real notch/external display/fullscreen, VoiceOver and menu-bar-auto-hide checks remain manual; Codex review is the next gate.
