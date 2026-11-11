# Dynamic Island — Codex review

## Metadata

- Review ID: dynamic-island-settings
- Outcome: Approve
- Scope: implementation through `0908750`, evidence through `d44e65c`, ready for maintainer Debug evaluation; this is not manual or release acceptance.
- Date: 2026-11-11

## Traceability Check

- Product Intent Link: `docs/product-intent.md`
- Roadmap Item: `docs/roadmap.md` — Dynamic Island D1–D3
- Feature Spec: `docs/specs/features/live-dictation-streaming.md`, `docs/specs/ux-setup-status.md`
- Task: `docs/specs/tasks/dynamic-island-settings.md`, maintainer-approved Codex design
- Related ADRs: ADR-012, ADR-014 (amended), ADR-016, ADR-017, ADR-018

## Review Summary

OpenCode implemented the agreed Full/default, Minimal and Menu-only modes. Codex inspected production policy, AppState/session capture, controller refresh paths, preview gating, result exceptions, fallback menu and tests. Initial requested changes R1–R3 are resolved: selected-mode synthetic previews share production visuals; vertical choices fit the actual detail column; full-shell minimum-size snapshots select Dynamic Island; RU/EN keep the approved untranslated name. No blocking findings remain for Debug delivery.

## Governance Checklist

- Product intent respected: final WAV dictation/paste and local processing retained; no model/network/runtime/catalog/trust change.
- Architecture respected: session-owned captured mode/effective preview; UI policy preserves domain phase and transform/recovery results. ADR-014 amendment records the opt-in modes and cancellation contract.
- Verification evidence present: worker report and actual test source/build log inspected; final images, signature, executable hash and diff whitespace checked independently by Codex.
- Documentation updated: spec, roadmap, architecture, product/UX docs, README, ADR and memory reflect the change and limits.

## ADR Impact

Follows accepted ADR-014 with the approved presentation/preview amendment; ADR-012 result delivery and ADR-017 install gate/trust remain. No new engine/runtime/network/dependency decision.

## Verification Evidence

- Evidence: `docs/debug-review-dynamic-island.md` contains worker-run policy, actual AppState/coordinator fake-adapter, lifecycle/setup/reliability/catalog/Ultra/launch/notes/governance results. Code for the assertions inspected; passing checks were not repeated without a new concern.
- Evidence: `/tmp/ct-build-final-r1r3.log` ends in BUILD SUCCEEDED. Codex independently ran `codesign --verify --deep --strict` on the final Debug and verified executable SHA-256 `5118fb744c9004f10fb6be982effae373302471902e7358cda399bb08646079e` matches the report.
- Evidence: inspected real whole-shell 720×520 RU Full/top and scrolled bottom, EN Dark Minimal, RU Menu-only PNGs under `dist/.builds.noindex/Dynamic-Island-Native-Review-R1R3/native/`. Mode choices and previews fit; bottom content is reachable. These are offscreen native fixtures, not live-device tests.
- Evidence: final app `dist/.builds.noindex/Dynamic-Island-Debug-R1R3-2026-11-11/CarrotType.app`; unchanged 0.8.2 (32) metadata identifies a development prototype, not a new published release.

## Remaining Manual Checks

- Check: actual recording, stop/paste and Escape in all modes on the maintainer Mac; restore Full and its saved live-draft preference; translate/recovery result accessibility.
- Check: notch glow visibility, external display/fullscreen, auto-hidden menu bar, VoiceOver and keyboard navigation in live Settings.
- Risk: these manual checks remain unverified. Existing worker evidence does not prove them; Debug/manual acceptance and publication require separate maintainer instruction. No installed app or user profile was replaced.

## Maintainer acceptance and release authorization — 2026-11-11

After the signed Debug delivery, the maintainer explicitly accepted it and authorized publication: «можно публиковать». Individual manual outcomes were not enumerated. Release preparation uses frozen application source `0908750` and metadata 0.9.0 (33); evidence is in `docs/debug-review-v0.9.0.md` and `docs/github-release-notes-v0.9.0.md`. The release remains a draft until the coordinator final gate; this authorization is not a claim that every device/TCC/VoiceOver/fullscreen check was individually repeated.
