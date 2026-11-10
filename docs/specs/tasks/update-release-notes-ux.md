# Update release notes and What’s New

## Metadata

- Task ID: update-release-notes-ux
- Title: Readable update notes and persistent access to installed-version changes
- Status: Published as 0.6.1 (27), 2026-11-10, after its own user Debug acceptance/authorization and verified Release/local/draft/public assets
- Target: 0.6.1; lifecycle work moves from 0.6.1 to 0.6.2

## Traceability

- Product Intent Link: `docs/product-intent.md` — explicit controls, local-first, reliable primary loop
- Roadmap Item: `docs/roadmap.md` — 0.6.1 release notes/What’s New
- Feature Spec: `docs/specs/ux-setup-status.md`
- Related ADRs: ADR-011, ADR-017
- Plan: `docs/superpowers/plans/2026-11-09-product-improvements.md`, N1–N3
- User request: screenshots of CarrotType 0.6.0 update and OpenBot; use information hierarchy with an independent CarrotType style, add access to changes next to version/updater

## Scope and design direction

Prefer a compact App Updates block in existing General and a What’s New link by the installed version in Status Details. Keep existing checks and opt-ins; a separate sidebar pane is unnecessary for this scope. The native CarrotType sheet/window shows installed-version notes offline. Sparkle continues to own update discovery, downloads, verification, installation, standard buttons/errors and deferred restart; improve its notes body with inline HTML/CSS. Do not promise the entire standard Sparkle window can be restyled.

Use CarrotType’s icon and carrot accent with restrained typography/spacing. Show version/date, brief summary and nonempty New/Improved/Fixed sections with short bullets and optional supporting text. Scrolling content has persistent Close/Got it and Full changelog controls. Support light/dark and RU/EN; do not copy OpenBot branding/layout verbatim. No need for AI-generated imagery or a new visual dependency.

N1: add a validated per-release localized structured source, render bundled current notes, safe appcast HTML and GitHub text from it. N2: add current-version What’s New view, existing-pane buttons and seen-version badge. N3: verify real Sparkle presentation/localization and signed staging/native install behavior. Likely files: new resource/schema/model/view/renderer; `AppUpdateViews.swift`, General/Status Details, `AppUpdateService.swift` only if needed, `prepare-update.py`, verification scripts and release workflow docs.

## Acceptance Criteria

- Installed-version notes work offline from the app bundle. Version/build/date agree with shipped metadata; never label latest remote notes as the installed version’s changes. No parsing remote GitHub Markdown in-app or extra background HTTP for this feature.
- What’s New remains accessible after dismissal. Only an observed installed-version change causes an unread Updated badge; first launch is initialized without claiming an update. Viewing marks it read; compare build and version. No automatic popup, microphone start or interruption of active sessions. Separate Debug/test preferences as today.
- A single localized release source produces all presentations, with supported fallback language and schema validation. Missing/invalid bundled notes degrade to a useful message/version and explicit full-changelog link; do not break application launch or updater.
- Appcast notes are embedded within the signed feed and use supported HTML/CSS. Escape user-authored text, allow only the release template’s safe markup and explicit project links. No JS, external fonts/images/styles, iframe or unsigned remote notes. Link opens only on user action.
- Keep all updater settings/actions and existing application features. Signatures, stable URL/channel, install reservation/termination guard and error handling remain intact. Published 0.6.0 assets are immutable; a future feed is generated and signed normally.
- Existing 0.5.0/0.6.0 clients render the next release notes usefully. Verify stock Sparkle language behavior separately from our RU/EN strings; app-language override must not remount Settings or stop the meter.
- Deliver Debug and manual checklist for 0.6.1; publish only after its own explicit user confirmation.

## Verification

- Check: production renderer/schema tests for section omission, escaping, version/build mismatch, missing translation/content, long strings and matching outputs. Avoid tests that duplicate rendering logic.
- Check: Debug arm64 build; native installed-notes window and real Sparkle screenshots in light/dark/RU/EN/minimum size, keyboard/VoiceOver and long notes. Browser preview alone is insufficient.
- Check: fresh install, upgrade, relaunch, read/unread badge, same marketing version/new build, isolated profile and offline What’s New. No surprise network/check/download from opening the window.
- Check: signed staging discovery/install A → B with retained external data and existing bad-feed/archive/install-gate scenarios, plus manual microphone/Accessibility after replacement. Offline dictation remains independent of updates.
- Check: governance validate/trace/review and diff checks. Full network audit remains separate; explicitly record skipped native/TCC checks.

## Documentation Updates

- Update: Setup UX before implementation; release source/template, `ops/deploy.md`, roadmap, workflow/memory and Debug checklist during implementation.
- Update: original staged plan with 0.6.1 N1–N3 and retained 0.6.2 C1–C2. Historical version numbers in prior release evidence remain unchanged.

## ADR Impact

No ADR impact. Follows accepted ADR-017.

No new engine, dependency, network sink or trust model is proposed. ADR-017’s standard updater UI remains, with a styled inline notes body; installed-version sheet reads bundled resources. Before code, document the presentation/data contract in UX spec and clarify ADR-017 only if needed. Replacing Sparkle’s standard user driver, adding remote note hosting or changing installation/trust would require a separate ADR/scope decision.

## Technical evidence

Current `prepare-update.py` emits one plain-text description; `AppUpdateService` uses `SPUStandardUpdaterController`, while `AppUpdateViews` exposes checks/opt-ins only. Sparkle 2.10.1 resolved source (`SUAppcastItem.h/.m`) supports inline descriptions and HTML; the actual renderer/attributes must be verified in staging. Official publishing documentation checked 2026-11-10: https://sparkle-project.org/documentation/publishing/ — embedded notes share appcast signature, avoiding a new separately hosted resource. This is feasibility evidence, not completed UI validation.

## Planning verification — 2026-11-10

AIDOS validate passed; trace reports Missing Links: None; deterministic review Approve (existing advisory notes retained). Plan local links and `git diff --check` passed. Manual architecture/scope review: standard Sparkle driver, signed inline notes and offline bundled current-version content preserve ADR-017. No app code or release asset changed; Debug/native UI tests are deferred to implementation, not claimed complete.

## Implementation evidence — 2026-11-10

N1–N3 implementation is on `feat/update-release-notes-ux`: versioned bundled source, production Swift validation/store and native sheet/buttons, localized HTML/Markdown renderer and signed feed integration. Standard Sparkle/installation code is preserved. English is a required content fallback; stock Sparkle uses system localization, explicit app override applies to our sheet only. First tracking launch quietly initializes; unread badge is only for observed version/build changes.

Debug arm64 build, release-notes/schema/escaping/localization/metadata/tracking checks and existing updater/clipboard/selection/helper/setup regressions passed. Real isolated native installer 26 → 27 plus offline/tampered-feed/corrupt-archive/no-new-version passed; staging profiles now isolate resume state per run/scenario. Native sheet rendered programmatically in RU/EN light/dark for layout inspection; this is not interactive native UI/TCC verification. Orca observation still returns permission_denied despite inventory granted. Detailed Debug checklist/evidence in `docs/debug-review-v0.6.1.md`; user Debug acceptance and publication authorization received on 2026-11-10; clean Release/DMG and local/draft/public signed assets verified, then published stable/latest. Native public probe using isolated build 26 found the update.
