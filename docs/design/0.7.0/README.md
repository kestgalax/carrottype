# CarrotType 0.7.0 design exploration

D1/D2 review materials, not shipping UI. Open `directions.html` locally: three directions applied to the same Settings/Capsule/What's New examples, light/dark toggle, a minimum-window approximation and three logo concepts at app/wordmark/16/18/32 px sizes. All values/state/text are illustrative. Only the design selectors, preview theme/width and example checkboxes work; app-like buttons are illustrations, not links to real preferences or updates.

## Sources and provenance

- `concepts/a-mark.svg`: geometric carrot, direct continuity with existing CarrotType.
- `concepts/b-mark.svg`: diagonal carrot with negative-space text caret; small monochrome version will need simplification if chosen.
- `concepts/c-mark.svg`: C and sprout; weaker carrot recognition, stronger change to identity.

These are original editable SVG sketches authored for this repository on 2026-11-10; repository MIT terms apply. No competitor vectors, fonts, logos, illustrations or code were copied. Existing production icon and source/history remain untouched. This is not a trademark clearance claim. SVG masters use `currentColor`; preview app-icon leaf coloring is applied by CSS, monochrome examples preserve a single color. Final app-icon container/layers, optical sizing, native template exports and installer assets are deliberately not finalized before selection. No raster generation was needed for these geometric vector sketches.

## Reference boundary

The maintainer confirmed [OpenBot](https://openbot.run/) and [Grok Bot](https://x.ai/bot), resolving the earlier “GrogBot” spelling. Study hierarchy, spacing, restrained typography and clear action priority; do not copy their specific marks, chatbot/workspace navigation or business model. The supplied OpenBot What's New screenshot is the strongest direct native reference. Landing pages and previews are not evidence of every state in their installed apps.

Apple references: [Settings](https://developer.apple.com/design/human-interface-guidelines/settings), [App icons](https://developer.apple.com/design/human-interface-guidelines/app-icons), [Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility), read on 2026-11-10 (official Markdown endpoints for full content). They inform native controls, simple recognizable marks, labels/contrast and system preference support. Web mockups are layout hypotheses, not native SwiftUI or official Apple materials.

## Selection required for D3

Choose interface A/B/C, logo A/B/C (independently) and the actual changes to implement. Recommended starting point: interface A; test logo A against B in native small-icon rendering. Keep familiar five-pane navigation; bring a formatting-mode shortcut near dictation settings; retain full model controls in Models; improve accessibility and destructive-action clarity. No feature removals. A selected scope will be recorded before runtime/assets change. Debug and publication acceptance remain separate.

## Preview verification

WebKit/Playwright: 36 direction/screen/theme/width combinations passed, no JS errors or horizontal content overflow; notes footer stays visible. Screenshots inspected for light/minimum, dark notes/Capsule and mobile rendering. Browser-only evidence retained under ignored `dist/CarrotType-0.7.0-Design-Review/`; no native app QA claim.
