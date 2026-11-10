# UI/UX audit and CarrotType brand refresh

## Metadata

- Task ID: uiux-and-brand-refresh
- Title: Audit the product experience, discuss directions and implement the selected interface/logo
- Status: Planned, 2026-11-10; target 0.7.0 after 0.6.1/0.6.2

## Traceability

- Product Intent Link: `docs/product-intent.md` — dependable local hotkey-to-caret loop, explicit control
- Roadmap Item: `docs/roadmap.md` — 0.7.0 UI/UX and brand refresh
- Feature Spec: `docs/specs/ux-setup-status.md`
- Related ADRs: ADR-002, ADR-011, ADR-012, ADR-014, ADR-016, ADR-017
- Plan: `docs/superpowers/plans/2026-11-09-product-improvements.md`, D1–D3
- User request: dedicated UI/UX analysis/discussion and a modern minimal logo informed by existing CarrotType/name; OpenBot, GrogBot and modern services as references

## Scope

D1: audit actual screens and complete journeys, preserve strengths/features, prioritize findings by user effect and cost. D2: present 2–3 visual directions on comparable screens and 3 distinct logo concepts; discuss the preferred direction with the maintainer before replacement. D3: implement only the selected scope in small changes on a new main-based branch, with a Debug review before release. This planning task does not perform the audit, design the logo or change runtime/UI assets.

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
