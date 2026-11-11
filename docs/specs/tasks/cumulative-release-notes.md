# 0.8.2 — changes across skipped releases

## Metadata

- Task ID: cumulative-release-notes
- Status: implementation / signed Debug review required

## Traceability

- Product Intent Link: `docs/product-intent.md`
- Roadmap Item: `docs/roadmap.md` — 0.8.2 cumulative changes
- Feature Spec: `docs/specs/ux-setup-status.md`
- Related ADRs: ADR-017

## Scope

Small patch 0.8.2 (32): preserve immutable localized per-release notes as bundled history, recover published 0.6.1–0.8.1 structured records verbatim from tags. Native What's New shows all releases with previous observed installed build < build <= current build, newest first. Save the upgrade baseline across relaunches/dismissal, replace on next actual version change. Fresh tracking/missing or invalid baseline/downgrade shows current only; corrupt history safely falls back to current. History starts 0.6.1; explicitly report limited coverage for older baselines. Existing unread behavior stays quiet on fresh install, no auto popup or network.

Signed inline HTML includes current + bundled history newest first. Use Sparkle 2.10.1's documented data-sparkle-version/class CSS to hide installed release and older siblings (CFBundleVersion, not marketing version). Unknown/older builds see available history with its starting version; no claim to filter an unknown baseline. No authored JavaScript, remote notes, new dependencies, custom updater or trust/network/install-gate change. Markdown GitHub notes remain current-release-only. Published files stay immutable.

## Acceptance Criteria

- Same single-release JSON schema retained; history validates unique builds, descending contiguous range through current, metadata and content; no future notes accepted.
- Upgrade skipping five versions shows each missed release once and excludes the installed/older releases; normal one-version upgrade, relaunch and read/dismiss preserve range.
- Swift and Python history/coverage/order/invalid input and safe escaping checks; native Sparkle WK rendering with installed marker and JS disabled; Debug build/signatures and native sheet rendering.
- Debug delivered before manual confirmation and separate publication instruction. Do not replace user app/preferences or mutate real login items.

## Verification

- Check: production Swift history/store tests in verify-release-notes.sh; Python renderer/archive validation and escaping tests.
- Check: arm64 Debug and signed bundle; native offscreen sheet/light/dark/RU/EN and actual Sparkle WK view marker/CSS visibility for several baseline builds. Full interactive/VoiceOver/TCC manual checks reported separately.
- Check: local governance and final diff; signed feed/staging verification before eventual publication.

## Documentation Updates

- Update: UX/architecture/deploy notes, roadmap, memory and focused Debug review.

## ADR Impact

No ADR impact. Uses accepted ADR-017's signed inline notes and standard Sparkle driver with no new runtime/network/trust. [Official contract](https://sparkle-project.org/documentation/publishing/#adapting-release-notes-based-on-currently-installed-version); pinned source SUWKWebView.m injects installed CFBundleVersion even with content JavaScript disabled.
