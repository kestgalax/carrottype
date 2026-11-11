# Workflow

```text
Idea -> Product Intent -> ADR Gate -> Feature/Tasks -> Implementation -> Review -> Release
```

## Current phase (after v0.8.0)

Self-signed/unnotarized DMG on GitHub Releases; source under MIT (ADR-011). Repository is **public**; preflight found private visibility on 2026-11-10, then the maintainer explicitly authorized public code/history and the change was applied/verified. v0.3.9 parallel unmute + live-draft hygiene; Storage download-cache clear in v0.3.8; security hardening (ADR-015) in v0.3.7; live draft (ADR-014) through v0.3.4–v0.3.6.

Next ordered focus:

1. Staged improvements: reliability → Ultra-only dictation → GitHub app updates → setup/settings → update presentation/What’s New → lifecycle/tests. Target versions and acceptance criteria: [`2026-11-09-product-improvements.md`](../docs/superpowers/plans/2026-11-09-product-improvements.md). Reliability `0.3.10 (23)` was published after the user accepted every Debug manual checklist item and clean Release DMG verification passed. Ultra-only dictation `0.4.0 (24)` was published after its own Debug manual acceptance and verified Release packaging (2026-11-10). 0.5.0 (25) GitHub updates is published (ADR-017), with isolated native installer A → B and signature-negative checks passed. The user explicitly authorized publication after Debug delivery on 2026-11-10; individual UI/TCC results were not enumerated. Clean Release packaging, draft/public asset signatures/hashes and anonymous native feed verification passed. The maintainer separately authorized public repository visibility; 0.6.0 (26) X1–X3 is published: setup/trial, compact bindings and formatting feedback. The user accepted Debug and authorized publication on 2026-11-10. Production checks, clean Release/DMG, signed local/draft/public assets and anonymous native feed probe from build 25 passed (`docs/debug-review-v0.6.0.md`, PR #22). Next is 0.6.1 update presentation/What’s New (N1–N3), added by the maintainer on 2026-11-10 from screenshots; lifecycle/tests is retained as 0.6.2. Task: `docs/specs/tasks/update-release-notes-ux.md`; now published from `feat/update-release-notes-ux` as 0.6.1 (27) after its own acceptance and verified Release/assets. See `docs/debug-review-v0.5.0.md`.
2. Optional later: Developer ID sign + notarize (`ops/deploy.md` / `notarize-dmg.sh`) when credentials exist. Updater integration has its own ADR/network gate and unsigned-upgrade verification; notarization is not a prerequisite to begin it.
3. Post-v1 research spikes when useful (`docs/research-post-v1-spikes.md`).

## Phase gates

### Product intent

- Changes to mission / non-goals update `docs/product-intent.md` and roadmap.

### ADR gate

- New STT/cleanup engine, catalog policy, or distribution trust model → ADR before code.
- New outbound network sink, telemetry/analytics, or direct SPM product dependency → ADR before code (closed sinks in `.ai/constraints.md`).
- Accepted ADRs: ADR-002 (stack), ADR-003 (catalog), ADR-004 (Whisper), ADR-005 (Qwen), ADR-006 (Parakeet), ADR-007 (Wave Link unmute), ADR-008 (Apple SpeechAnalyzer STT), ADR-009 (OOP cleanup), ADR-010 (Gemma cleanup), ADR-011 (public MIT distribution), ADR-012 (selection transform), ADR-013 (local usage stats), ADR-014 (live dictation streaming), ADR-015 (hub revision + helper path jail), ADR-016 (Ultra-only dictation, shipped in 0.4.0), ADR-017 (signed GitHub app updates, shipped 0.5.0).

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

## 0.7.0 published — 2026-11-10

Maintainer accepted Debug UI and explicitly selected the original carrot-microphone A from the second comparison, then authorized publication: «оставляем изначальный / согласен / публикуй тогда версию». Stable/latest **0.7.0 (29)** published from tag/source `v0.7.0` / `2bb5555`, PR #25. Final signed Debug and fresh clean Release/DMG pass; signed ZIP/feed and downloaded draft/public assets pass signatures, metadata, lengths, URLs and exact local byte hashes. Anonymous stable feed/archive match. Native Sparkle probe using isolated build-28 host found the live update without installation. Isolated candidate-code A28→B29 installer and negative scenarios passed; not independent historical-binary/TCC proof. Final-source hosted app CI passed (runs `42828743848` and `42828835461`); private hosted AIDOS explicitly skipped, local validate/trace/review passed. No user installation/data replacement, key export, new engine/dependency/trust or feature removal. Full independent device/VoiceOver/TCC/network checks remain unverified. Artifact hashes: `docs/github-release-notes-v0.7.0.md`; acceptance/limits: `docs/debug-review-v0.7.0.md`. Next: collect feedback; no further implementation stage selected. Later releases retain their own Debug/manual/publication gate.

## 0.8.0 implementation — 2026-11-10

User authorized nearest stage, GigaAM deferred without date/version. Fresh main-based branch `feat/formatting-rules-theme-0.8` retains planning history. ADR-018: offer Qwen3 0.6B/Gemma, preserve existing active ready Smart+/bindings/files/Storage without new recommendation/download. Shared captured DictationRules and helper v3 purpose separate from transforms; token/context/completion and protected-literal checks; safer Light/newlines/empty delivery. General rules/summary/reset/text-only gated trial; System(default)/Light/Dark independent persistence/live native/Capsule appearance. No new runtime/network/trust/default STT or user data deletion. Local production checks, actual isolated AppState/ModelManager/trial/theme integration, offscreen native RU/EN/light/dark layouts and installed-Gemma synthetic cases run. Qwen not installed; no implicit download or full comparative quality/RAM claim. Gemma self-corrections/paragraph compliance remains imperfect; detected numeric/quote/code/language losses fall back visibly. Signed Debug 0.8.0 (30) and focused manual checks: `docs/debug-review-v0.8.0.md`. Manual acceptance and separate publication authorization pending; stable 0.7.0. Build copies under `dist/.builds.noindex`, avoid indexed app proliferation.


## 0.8.0 published — 2026-11-11

Maintainer accepted the signed first-sentence Debug and authorized release: «ок, пока остановимся, хорошо получилось, давай релизить». Stable/latest **0.8.0 (30)** published on 2026-11-11 from tag/source `v0.8.0` / `819286a` (application code `0edde77`), PR #27. Known business-tone failures remain disclosed/experimental/off by default; release acceptance is not a semantic quality pass. Fresh clean Release arm64, signed host/helper/Sparkle, mounted DMG/layout/background, no bundled weights and real installed-Gemma Release helper smoke passed. Local governance passed; hosted regressions/Debug/actual native checks passed ([42891053801](https://github.com/kestgalax/carrottype/actions/runs/42891053801), [42891040649](https://github.com/kestgalax/carrottype/actions/runs/42891040649)); private hosted AIDOS explicitly skipped. Signed ZIP/feed and downloaded draft/public artifacts passed digests, signatures, lengths, identity/URLs; anonymous latest feed/archive match. Isolated A29→B30 install and negative cases passed; public native Sparkle probe found 0.8.0 from isolated build-29 metadata without installation. No user app/profile/model replacement or private-key export. Full independent device/TCC/VoiceOver/network and Qwen comparison remain unverified. Hashes: `docs/github-release-notes-v0.8.0.md`. Stop feature iteration per maintainer; collect feedback, no next stage selected; GigaAM stays deferred.


## 0.8.1 published — 2026-11-11

Maintainer accepted the revised signed Debug and instructed «публикуй». Stable/latest **0.8.1 (31)** published on 2026-11-11, tag/source `v0.8.1` / `d8e166b` (application code `fe2e9bc`), PR #28. Opt-in native launch at macOS sign-in lives at the bottom of General without persistent hints. Clean Release arm64, signed host/helper/Sparkle, final mounted DMG/resources/metadata/no weights and ZIP/feed signatures passed. Initial DMG creation returned Resource busy; checksum-verified 0.8.0 filesystem template reused with unchanged layout/background. Local governance and hosted final-app regressions/Debug/native checks passed (42983616038, 42983623123); private hosted AIDOS explicitly skipped. Isolated candidate-code A30→B31 install and negative checks passed, not historical-binary or TCC proof. Downloaded draft/public files matched digests/signatures/length/identity/URLs; anonymous latest feed/archive matched. Native isolated build-30 Sparkle probe found the live update without installation. No user installation/profile/model/login-item replacement or private-key export. Individual actual reboot/system-approval results were not enumerated; independent device/TCC/VoiceOver/network checks remain unverified. Hashes: `docs/github-release-notes-v0.8.1.md`; evidence: `docs/debug-review-v0.8.1.md`. Next: collect startup feedback, no further stage selected; GigaAM remains deferred. Later releases retain their own Debug/manual/publication gate.
