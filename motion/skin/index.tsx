/**
 * Active Motion OS skin for CarrotType (pin: `ops/motion-tooling.md`).
 *
 * motion-os composes exactly one `motion/skin/index.tsx` per consumer root, so
 * the skin stages the release film currently in preparation: **0.12.0 mic
 * priority** (`motion/briefs/mic-priority.md`). The shipped 0.8.0 theme film
 * wiring stays in `themeFilm.tsx`; swap the re-export to re-render
 * `motion/briefs/theme.md`.
 */
export { beats, copy, iris, scenes, tokens } from "./micPriorityFilm";
