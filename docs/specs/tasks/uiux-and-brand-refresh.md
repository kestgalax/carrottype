# UI/UX audit and CarrotType brand refresh

## Metadata

- Task ID: uiux-and-brand-refresh
- Title: Audit the product experience, discuss directions and implement the selected interface/logo
- Status: interface A + logo A explicitly selected; D3 implemented on `feat/native-ui-brand-0.7` from main after PR #24; Debug 0.7.0 (29) accepted; final carrot-microphone A selected and publication explicitly authorized; stable/latest released after clean Release and local/draft/public verification

## Traceability

- Product Intent Link: `docs/product-intent.md` — dependable local hotkey-to-caret loop, explicit control
- Roadmap Item: `docs/roadmap.md` — 0.7.0 UI/UX and brand refresh
- Feature Spec: `docs/specs/ux-setup-status.md`
- Related ADRs: ADR-002, ADR-011, ADR-012, ADR-014, ADR-016, ADR-017
- Plan: `docs/superpowers/plans/2026-11-09-product-improvements.md`, D1–D3
- User request: dedicated UI/UX analysis/discussion and a modern minimal logo informed by existing CarrotType/name; OpenBot, GrogBot and modern services as references

## Scope

D1: audit actual screens and complete journeys, preserve strengths/features, prioritize findings by user effect and cost. D2: present 2–3 visual directions on comparable screens and 3 distinct logo concepts; discuss the preferred direction with the maintainer before replacement. D3: implement only the selected scope in small changes on a new main-based branch, with a Debug review before release. Current progress: preliminary code/resource audit and comparable HTML/SVG concepts are available; native walkthrough is incomplete and no shipping UI/assets were changed.

Audit first-run/permissions/model download, everyday dictation/Capsule/cancel/recovery, trial, settings/navigation/formatting/bindings, Storage, stats and updates. Check terminology, density, hierarchy, feedback, keyboard/VoiceOver, RU/EN, light/dark and minimum window. Record evidence and distinguish hypotheses from observed failures.

Logo brief: recognizable connection to CarrotType and the current carrot, contemporary minimal geometry, clear silhouette and no dependence on tiny detail. Explore carrot-only, carrot/text-caret and abstract C/speech/text hypotheses without combining every metaphor. Compare app icon, wordmark and a simplified monochrome menu-bar mark. Preserve old asset sources/history. Final deliverables include editable vector masters and required native exports.

Use reference products for information hierarchy, typography, spacing and simplicity, with an original identity. Confirm the exact GrogBot/OpenBot references during the research phase; do not silently substitute similarly named products. No competitor logo/brand copying or speculative claims that reference analysis is complete.

Likely files: dated audit/design brief and decision in docs, selected SwiftUI Views and minimal shared style tokens, localization, app/menu icon assets, installer artwork and README-brand resources where needed. Determine concrete files/scope from audit and chosen direction, not a blanket rewrite.

## Acceptance Criteria

- Evidence-based audit lists preserved strengths, actionable findings, priority/cost and observation limits; code inspection alone is not presented as completed native visual QA.
- Comparable mockups/logo concepts show tradeoffs and are discussed with the user; chosen scope is recorded before implementation. This follows the user's request to think through changes together.
- The selected logo is recognizable at 16/18/32 px, works in app and monochrome menu-bar contexts on light/dark backgrounds, and has editable source and export/license provenance.
- No useful feature is removed, hidden or reduced without specific approval. Existing settings/data, permission prompts, hotkeys and recording/error semantics remain reliable. Audit ideas outside selected scope go to backlog.
- Keep native SwiftUI/macOS, bundle identity, local-first/network and signed-update policies. No engine/dependency/trust change through visual work.
- Review app icon, menu icon, Sparkle, packaged installer and documentation for consistent selected assets. Verify RU/EN, minimum size, keyboard/VoiceOver, contrast and existing mic-meter language-switch behavior.
- Deliver Debug 0.7.0 and checklist; publication requires this version’s own explicit acceptance.

## Verification

- Check: actual scenario walkthrough and native before/after screenshots; state permission limitations and separate code findings when GUI is unavailable.
- Check: 2–3 design directions and 3 logo concepts on the same representative Settings/Capsule/What’s New screens and small-icon grid; user discussion and recorded decision.
- Check: Debug arm64, relevant production regressions and manual hotkey/paste/hold/Escape/live draft/trial/transform/meter/Wave Link/storage/stats/update smoke. Inspect packaged icons/DMG and stock Sparkle presentation when assets change.
- Check: AIDOS validate/trace/review, local document links and diff checks. No runtime build is necessary for this documentation-only addition.

## Documentation Updates

- Update: staged plan, roadmap, workflow/memory now; audit, UX spec, design decision, brand sources/export notes and release checklist during the stage.

## ADR Impact

No ADR impact. Follows accepted ADR-002 and ADR-011; existing product/runtime/update decisions remain. A later proposal changing runtime, architecture, network or update trust requires its own ADR before implementation.

## D1/D2 deliverables — 2026-11-10

- `docs/2026-11-10-uiux-audit.md`: evidence-labelled strengths/findings, preservation matrix, priorities/cost and native observation limits.
- `docs/design/0.7.0/directions.html`: same Settings/Capsule/What’s New content in three directions, light/dark and minimum-size approximation; three editable logo concepts with 16/18/32 px monochrome previews.
- `docs/design/0.7.0/README.md` and `decision.md`: provenance, confirmed OpenBot/Grok Bot links, recommendation and unresolved selection.
- Current native GUI acquisition timed out; no complete native/VoiceOver/scenario QA claim. Runtime, installed app, icons and version metadata remain unchanged; no new Debug/release at this design-review point. D3 waits for the requested design discussion/selection.

## D3 selected implementation — 2026-11-10

Maintainer chose A for both interface and logo. Decision: `docs/design/0.7.0/decision.md`. Implemented limited native shell/style, same five destinations, shared General/Models formatting selector, A1–A5 accessibility/confirmation improvements, concise localized hints and original vector/native icon exports. All useful functions and runtime/trust policy retained. Sources: `macos/Brand/`, `AppStyle.swift`, affected Views/localizations; existing icon preserved in archive/history. Actual production SwiftUI rendered offscreen in isolated fixture profile, not a full native walkthrough. Debug/evidence/limits: `docs/debug-review-v0.7.0.md`. Separate manual/publication gate remains.

D3 verification closeout: signed real-identity Debug 0.7.0 (29), local regressions/native offscreen/resource/signature checks and [hosted app CI](https://github.com/kestgalax/carrottype/actions/runs/42824162527) passed (source `122afdb`). Hosted private-tooling governance explicitly skipped, local governance passed. Await this version’s manual acceptance; no release published.

Final selection after Debug review: original carrot-microphone A from `microphone-concepts/comparison-round2.html`, not the earlier plain carrot. Maintainer explicitly authorized publication. Final source/tag `2bb5555` / `v0.7.0`, PR #25; updated notes/assets, signed Debug, refreshed offscreen fixture rendering, local governance and isolated native A28→B29 update acceptance passed. Full manual/device/TCC limits remain. Release/draft/public checks are recorded in the release evidence before closeout.

## 0.7.0 published — 2026-11-10

Maintainer accepted Debug UI and explicitly selected the original carrot-microphone A from the second comparison, then authorized publication: «оставляем изначальный / согласен / публикуй тогда версию». Stable/latest **0.7.0 (29)** published from tag/source `v0.7.0` / `2bb5555`, PR #25. Final signed Debug and fresh clean Release/DMG pass; signed ZIP/feed and downloaded draft/public assets pass signatures, metadata, lengths, URLs and exact local byte hashes. Anonymous stable feed/archive match. Native Sparkle probe using isolated build-28 host found the live update without installation. Isolated candidate-code A28→B29 installer and negative scenarios passed; not independent historical-binary/TCC proof. Final-source hosted app CI passed (runs `42828743848` and `42828835461`); private hosted AIDOS explicitly skipped, local validate/trace/review passed. No user installation/data replacement, key export, new engine/dependency/trust or feature removal. Full independent device/VoiceOver/TCC/network checks remain unverified. Artifact hashes: `docs/github-release-notes-v0.7.0.md`; acceptance/limits: `docs/debug-review-v0.7.0.md`. Next: collect feedback; no further implementation stage selected. Later releases retain their own Debug/manual/publication gate.
