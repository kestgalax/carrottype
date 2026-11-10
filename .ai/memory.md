# Memory

Project memory lives in repository artifacts — not in chat transcripts.

## Canonical sources

- Product: `docs/product-intent.md`
- Status / next steps: `docs/roadmap.md`
- Staged improvement plan (2026-11-09): `docs/superpowers/plans/2026-11-09-product-improvements.md` — reliability `0.3.10 (23)` published after all Debug manual checks and verified Release DMG (`docs/debug-review-v0.3.10.md`); Ultra-only dictation `0.4.0 (24)` published after its own Debug acceptance and verified Release DMG (2026-11-10); GitHub updates 0.5.0 (25) is published with signed feed/archive, operation install gate and isolated real native A → B/negative checks passed (ADR-017, `docs/debug-review-v0.5.0.md`); The user explicitly authorized publication after Debug delivery, then separately authorized public code/history on 2026-11-10 after private visibility was found; visibility was changed and verified. Individual UI/TCC results were not enumerated; Clean Release, signed draft/public assets and anonymous native feed checks passed; release/DMG/ZIP/appcast published. 0.6.0 (26) X1–X3 is published after its own user Debug acceptance/authorization on 2026-11-10. Clean Release/DMG, local/draft/public signatures/digests and anonymous feed/archive checks passed; native Sparkle probe from isolated build 25 found the update (`docs/debug-review-v0.6.0.md`, PR #22). Next is 0.6.1 update presentation/What’s New (maintainer request 2026-11-10; `docs/specs/tasks/update-release-notes-ux.md`); retain lifecycle/tests as 0.6.2. Now published as 0.6.1 (27) after explicit Debug acceptance and verified Release/signed assets (see publication evidence below). Styled Sparkle notes plus offline installed-version window/button, no automatic popup or extra network sink.
- Architecture: `docs/architecture.md`
- Decisions: `docs/decisions/` (ADR-001 … ADR-017)
- Setup UX: `docs/specs/ux-setup-status.md`
- Security: `docs/security/secure-coding-checklist.md`, `docs/security/supply-chain.md`
- Release notes: `docs/github-release-notes-v0.6.0.md` (prior: `v0.5.0`, `v0.4.0`, `v0.3.10` … `v0.1.0`)
- License / public posture: `LICENSE`, ADR-011, `ops/deploy.md`
- Ops: `ops/deploy.md`, `ops/environments.md`, `ops/notarization.env.example`

## Rules

- Пользователь (2026-11-09): для каждой версии сначала подготовить Debug build для ручной проверки; публиковать только после его явного подтверждения результатов. Автоматические проверки не заменяют этот gate.
- Пользователь (2026-11-09): не удалять, не скрывать и не ухудшать существующие полезные функции без отдельного согласования. Согласованное сокращение моделей диктовки до Parakeet Ultra не разрешает удалять другие возможности; при рефакторинге и упрощении UI проверять их сохранность.
- Prefer updating these files over relying on conversation context.
- Do not delete ADRs, specs, reviews, or roadmap history unless a human maintainer explicitly instructs it.
- When correcting outdated status (e.g. public vs private distribution), update roadmap and deploy notes in the same change.

## Planned UI/UX and logo stage — 2026-11-10

Maintainer requested a separate 0.7.0 stage after 0.6.1 update presentation and 0.6.2 lifecycle: audit the real UI/UX, discuss improvements/visual directions and explore a modern minimal logo based on CarrotType/current carrot. References named: OpenBot and GrogBot (confirm exact products during research). Present comparable concepts and discuss before replacing UI/logo; preserve useful features. Task: `docs/specs/tasks/uiux-and-brand-refresh.md`, D1–D3 in staged plan. Planning only; no audit, designs or asset changes claimed. Existing per-version Debug/manual/publication gate remains.

## 0.6.1 implementation — 2026-11-10

N1–N3 implemented on `feat/update-release-notes-ux`, from main with planning commits retained. Debug 0.6.1 (27) delivered in dist, subsequently accepted and released (publication evidence below). Offline bundled What’s New/native buttons/read-version badge, single localized JSON → signed inline HTML/Markdown and unique per-run/scenario staging identities. No standard updater/gate/trust replacement. Production tests, Debug and isolated native installer/negative checks pass; offscreen production SwiftUI layout inspected, actual GUI observation still permission_denied. Manual checklist/evidence: `docs/debug-review-v0.6.1.md`. Latest stable 0.6.0. Next after acceptance/release: 0.6.2 lifecycle, then 0.7.0 UI/UX/logo discussion. This version’s explicit confirmation was received before publication; future releases retain their own gates.

## 0.6.1 release authorization — 2026-11-10

Maintainer accepted the delivered Debug: «все ок, публикуем». This version’s publication gate is satisfied; clean Release packaging and signed draft/public asset verification completed before stable/latest publication. Individual manual checklist results were not enumerated; preserve independent GUI/TCC/network limits. No authorization for later version releases is inferred.

## 0.6.1 published — 2026-11-10

User accepted Debug: «все ок, публикуем». Stable/latest 0.6.1 (27) published; clean Release/DMG, signed bundled/local/draft/public assets and anonymous feed/archive digests passed. Native Sparkle probe with isolated build-26 host found the update. Tag/source 7207548; PR #23; release notes/checksums and evidence in `docs/github-release-notes-v0.6.1.md`, `docs/debug-review-v0.6.1.md`. No independent post-release TCC/GUI/network audit claim; no key export. Next: 0.6.2 lifecycle, then separate 0.7.0 UI/UX/logo discussion; new branches and per-version Debug acceptance remain required.

## 0.6.2 implementation — 2026-11-10

C1–C2 on `refactor/dictation-session-lifecycle` from main after PR #23. Debug 0.6.2 (28): single session owner, snapshotted model/formatting/device/mode, joined preview/unmute/teardown and awaited model unload; model maintenance shares the install gate. Streaming pass/feed/recorder peak/fanout are epoch-bound; actual actor tested with test-only SDK. Normal Quit drains cleanup; Sparkle trust/gates preserved. Production helpers replace mirrors; local checks/mutations and Debug pass, Actions workflow added with pinned tooling and no distribution keys. Manual acceptance and publication pending; details: `docs/debug-review-v0.6.2.md`, `docs/specs/tasks/dictation-session-lifecycle.md`. No user models or data removed. Next after this version’s approval/release: separate 0.7.0 UI/UX/logo exploration, options discussed before replacement.

0.6.2 delivery closeout: signed Debug verified against the final successful arm64 build; all local regression suites passed. GitHub refused workflow push (OAuth missing `workflow`); connector writes returned 403. No remote branch/PR/CI run created; commits and workflow remain local. Do not report CI success. Manual checklist at `docs/debug-review-v0.6.2.md`; no publication authorization for 0.6.2 yet.

## 0.6.2 release authorization — 2026-11-10

After signed Debug delivery and the focused lifecycle checklist, maintainer instructed «публикуй». This satisfies this version’s publication authorization; individual manual results were not enumerated. Prepare clean Release/DMG and verify signed local/draft/public assets before stable publication. Remote CI remains unexecuted until GitHub workflow access is restored. No authorization for later versions is inferred.

GitHub authorization restored (`workflow`), source branch/tag pushed and PR #24 created. First hosted run 42815277135 failed before tests because AIDOS is private. CI-only correction separates app regression/build from optional private-tooling checkout: no new secret installed, explicit skip/warning for hosted AIDOS without a narrowly scoped read token. Local governance passed. Release app source/accepted Debug and signed artifacts are unchanged; tag 14dacf3 retains the original workflow. Draft asset verification in progress.

## 0.6.2 published — 2026-11-10

After Debug delivery/focused checklist, maintainer instructed «публикуй». 0.6.2 (28) stable/latest published from tag/source `14dacf3`, PR #24. Clean Release/DMG and signed local/downloaded draft/public assets passed; anonymous latest feed/archive matched, native isolated build-27 discovery found the update. No installation/TCC continuity claim or key export. Workflow access restored. First hosted CI failed on private AIDOS checkout; CI-only fix allows app checks/build independently and explicitly skips hosted governance without a narrow read-only secret. Local governance passed, hosted regressions and Debug compilation passed (run `42815581126`, commit `0e69d52`). Next: separate 0.7.0 UI/UX/logo options/discussion before replacement; later releases retain their own Debug/publication gate.

## 0.7.0 D1/D2 exploration — 2026-11-10

User requested next stage after 0.6.2. New branch `design/uiux-and-brand-0.7` from merged main `a68123a`. Confirmed references: https://openbot.run/ and https://x.ai/bot (Grok Bot, correcting earlier GrogBot spelling). Preliminary evidence-labelled code/resource audit at `docs/2026-11-10-uiux-audit.md`; comparable HTML directions and original editable SVG logo concepts at `docs/design/0.7.0/`. Native GUI acquisition timed out, no full native/VoiceOver/cold model walkthrough claimed. Recommendation: native interface A, logo A/B small-size comparison; not a selected decision. Discuss directions/scope before D3, as explicitly requested by user. Preserve all useful functions; no runtime/assets/version change, Debug or publication at this design-review point.

## 0.7.0 A/A selection and implementation — 2026-11-10

Maintainer explicitly selected interface A + logo A. New main-based `feat/native-ui-brand-0.7` retains exploration. Native headings/sidebar/style, same five destinations, shared General formatting source, accessible language/navigation/motion/contrast, deletion/stat confirmations and original vector/PNG/template logo implemented. No useful feature/runtime/trust/identity change; old icon archived/history kept. Local Debug/regressions and actual offscreen SwiftUI RU/EN/light/dark/minimum fixture rendering pass; full native/VoiceOver/device/dialog walkthrough remains unverified. Final signed Debug 0.7.0 (29) delivery/manual/publication gate pending; no permission to publish inferred from design acceptance. Details: `docs/debug-review-v0.7.0.md`, selected decision and `macos/Brand/README.md`.

0.7.0 Debug delivery: final arm64 build and production regressions passed; signed real-identity Debug in `dist/CarrotType-0.7.0-Debug/CarrotType.app`, deep/resource/metadata checks passed. Native template verified 18×18pt/isTemplate, deterministic exports and archived old master verified. Offscreen RU/EN/light/dark/minimum screenshots retained under `dist/CarrotType-0.7.0-Native-Review`; not interactive/VoiceOver/device/TCC QA. Hosted CI follows source push; separate manual acceptance and publication authorization still required.

0.7.0 hosted app verification passed: https://github.com/kestgalax/carrottype/actions/runs/42824162527, source `122afdb` (production regressions, brand assets, Debug arm64). Hosted AIDOS explicitly skipped; local governance passed. Final signed Debug delivered; manual approval/publication remain pending. Follow-up closeout edits are documentation only.

## 0.7.0 final logo and release authorization

Maintainer selected original carrot-microphone A (second comparison, not the earlier plain carrot) and explicitly said «оставляем изначальный / согласен / публикуй тогда версию». Final icon assets/notes are rebuilt in Debug before clean Release. User approval/publication gate satisfied for 0.7.0; preserve all prior UI and useful functions. No new runtime/trust decision.

## 0.7.0 published — 2026-11-10

Maintainer accepted Debug UI and explicitly selected the original carrot-microphone A from the second comparison, then authorized publication: «оставляем изначальный / согласен / публикуй тогда версию». Stable/latest **0.7.0 (29)** published from tag/source `v0.7.0` / `2bb5555`, PR #25. Final signed Debug and fresh clean Release/DMG pass; signed ZIP/feed and downloaded draft/public assets pass signatures, metadata, lengths, URLs and exact local byte hashes. Anonymous stable feed/archive match. Native Sparkle probe using isolated build-28 host found the live update without installation. Isolated candidate-code A28→B29 installer and negative scenarios passed; not independent historical-binary/TCC proof. Final-source hosted app CI passed (runs `42828743848` and `42828835461`); private hosted AIDOS explicitly skipped, local validate/trace/review passed. No user installation/data replacement, key export, new engine/dependency/trust or feature removal. Full independent device/VoiceOver/TCC/network checks remain unverified. Artifact hashes: `docs/github-release-notes-v0.7.0.md`; acceptance/limits: `docs/debug-review-v0.7.0.md`. Next: collect feedback; no further implementation stage selected. Later releases retain their own Debug/manual/publication gate.

## Post-dictation audit and proposed 0.8.0 — 2026-11-10

User confirmed «Да, Qwen3 0.6B + Gemma» instead of offered Smart+ and requested prompt analysis/user-rule proposal. Audit/plan: `docs/2026-11-10-post-dictation-formatting-audit.md` on new main-based `plan/post-dictation-formatting-0.8`. No app/weights/settings changes. Generic helper instructions replace the literal prompt for transforms: do not wire dictation preferences into that replacement slot. Preserve all unrelated functions and installed Smart+/bindings via explicit compatibility design. Light context-loss confirmed on real source; output-length/empty/wrapper issues identified, no model eval claim. HF pinned Gemma metadata says license gemma, unlike current catalog Apache; investigate/correct metadata without silently changing model revision. Detailed UI/migration proposal not yet chosen; future per-version signed Debug/manual/release gate persists.

Local build hygiene: on user request old generated dist artifacts moved reversibly to Trash; latest Debug preserved as `dist/CarrotType-0.7.0-29-Debug.zip`, production DMG/ZIP/feed retained. Do not recreate many indexed .app copies indefinitely: remove/archive test bundles after evidence capture. Installed /Applications app and user model/settings roots were untouched.

0.8.0 plan addition: maintainer explicitly requested System/Light/Dark theme selection, System default, like language. Added to P3/P4 in the audit/plan and roadmap. Theme is independent of language, locally persisted, immediate and system-reactive; cover native windows/sheets and fixed-color Capsule, system menu template contrast, no Settings remount/active-operation interruption. Planning only; no app/theme implementation or new Debug claimed.

## Separate alternative STT stage — 2026-11-10

Maintainer requested current alternatives to Parakeet Ultra and possible extra choice as a separate version after 0.8.0. New main-based `plan/stt-alternative-0.9` retains prior 0.8 planning commits; research/plan at `docs/2026-11-10-dictation-alternatives.md`. Target 0.9.0 S1 benchmark feasibility → S2 same-WAV Ultra/Qwen3-ASR 0.6/1.7/Turbo comparison and user decision → S3 Accepted ADR/native integration of at most one demonstrated useful alternative → S4 signed Debug/manual/separate release permission. No new runtime/default selected, no weights downloaded/model run. Qwen3-ASR is separate from cleanup Qwen3; latest model/runtime docs do not prove app integration or Mac latency. Preserve Ultra default/current features; ADR-016 only changes via new decision. User's existing untracked GigaAM HTML untouched, historical not rerun evidence. Old post-v1 private/notarization gates explicitly marked historical.

0.9.0 scope correction: after the overview maintainer explicitly chose **GigaAM v3 only** («Я бы тогда только этот посмотрел вариант»). Active comparison is Ultra vs GigaAM v3, native feasibility/CTC-RNNT variant and RU quality/latency first, EN/mixed as limitation checks. Do not benchmark/integrate Qwen ASR, Whisper, Redux, Voxtral or GigaAM Multilingual for this stage; old overview remains history only. Ultra default and useful functions retained; no checkpoint/runtime selection, download, model run or release yet.

GigaAM architecture follow-up requested: main loop fits STTEngine/Coordinator boundaries, but current pipeline/model policy hardcode Ultra. Inspected current upstream `95bd42a4b9a65450a24e1898c7d84b85e0e88509`; all 29 SDK Swift sources typecheck PASS against existing app Debug MLX modules (0.31.6), no weights/inference/app dependency changes. SDK batch recognizer lacks cooperative cancellation/session preview, chunkDuration is declared but unused. Prefer existing helper process pattern to preserve idle-memory goal and enforce stop; exact helper role/target in ADR. Static/API feasibility is not full resolve/link/runtime proof. Report: `docs/2026-11-10-gigaam-architecture-fit.md`.

GigaAM safety question: distinguished original ai-sage/salute GigaAM from Kruatech Swift port + converted weights. Model snapshot `2478743c1c449a468ee163bc3030170d1a2e81fb`, manifest source_revision named e2e_rnnt resolves today to official `7655ad717f8122257385bb4b2f373db3697e8680`; this does not prove conversion ancestry. No weights downloaded/equivalence checked. Foundation-only SDK fixture accepts `weights_file: ../outside.bin` in own temp files: path confinement needed; parser bounds/alloc review also needed. No RCE finding/dynamic full audit claimed. Existing helper unsandboxed; typecheck is API compatibility only. Add reproducible official-source conversion/pinning and loader/network verification to S1. Report `docs/2026-11-10-gigaam-provenance-safety.md`.

## GigaAM deferred by maintainer — 2026-11-10

User explicitly instructed «модельку отложим на какой-то другой этап реализации, потом к ней вернемся». GigaAM v3/additional STT is now deferred without version/date, not automatically next after 0.8.0. Preserve research/architecture/security evidence, do not continue downloads, benchmarks or integration until a new request. Earlier 0.9.0 is a historical proposed number, available for future planning. Current near-term work remains 0.8.0 postprocessing/rules and System/Light/Dark theme. Ultra remains the only shipping/default STT.

## 0.8.0 implementation — 2026-11-10

User authorized nearest stage, GigaAM deferred without date/version. Fresh main-based branch `feat/formatting-rules-theme-0.8` retains planning history. ADR-018: offer Qwen3 0.6B/Gemma, preserve existing active ready Smart+/bindings/files/Storage without new recommendation/download. Shared captured DictationRules and helper v3 purpose separate from transforms; token/context/completion and protected-literal checks; safer Light/newlines/empty delivery. General rules/summary/reset/text-only gated trial; System(default)/Light/Dark independent persistence/live native/Capsule appearance. No new runtime/network/trust/default STT or user data deletion. Local production checks, actual isolated AppState/ModelManager/trial/theme integration, offscreen native RU/EN/light/dark layouts and installed-Gemma synthetic cases run. Qwen not installed; no implicit download or full comparative quality/RAM claim. Gemma self-corrections/paragraph compliance remains imperfect; detected numeric/quote/code/language losses fall back visibly. Signed Debug 0.8.0 (30) and focused manual checks: `docs/debug-review-v0.8.0.md`. Manual acceptance and separate publication authorization pending; stable 0.7.0. Build copies under `dist/.builds.noindex`, avoid indexed app proliferation.
