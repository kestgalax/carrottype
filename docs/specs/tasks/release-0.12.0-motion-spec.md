# Worker spec — Motion companion for 0.12.0 mic priority

## Goal

Produce the required silent release companion MP4 for **visible UI** change (Dictation/Setup mic priority sheet) per `ops/release-motion.md` and `.agents/skills/carrottype-release-motion/SKILL.md`.

## Decision

**Yes** — motion required (Settings sheet / priority UI).

## Locked format

- Silent H.264 MP4, no audio
- 1920×1080, 30 fps, target 15–30 s (max 60)
- Effect clicks only, **no mouse cursor**
- Filename: `CarrotType-0.12.0-mic-priority-demo.mp4`
- Do **not** commit mp4 to git

## Steps

1. Read `ops/release-motion.md`, `ops/motion-tooling.md`. Set `MOTION_OS_ROOT` to pinned motion-os checkout (`557ec2c88a4f4db5a3cb43a189c383001a2e5a37` or current pin in motion-tooling.md).
2. Author `motion/briefs/mic-priority.md` (hero: Dictation compact row → Configure sheet → drag reorder → Done; optional Setup active-mic row). Reuse patterns from `motion/briefs/theme.md`.
3. From CarrotType root:
   - `npm run motion -- run motion/briefs/mic-priority.md --no-capture`
   - `npm run motion -- check motion/out/mic-priority.mp4`
4. Copy/rename to `dist/CarrotType-0.12.0-mic-priority-demo.mp4`.
5. Report: brief path, mp4 path, duration, check result, SHA-256 of dist file. If motion-os missing/pin fails, stop with exact blocker (do not invent a substitute film).

## Depends on

Can start after finalize worker has version **0.12.0** locked in notes/filename; if finalize not merged yet, still use 0.12.0 naming as authorized for this prep run.
