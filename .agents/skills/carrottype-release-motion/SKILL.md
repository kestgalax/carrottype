---
name: carrottype-release-motion
description: >-
  Produces CarrotType silent release companion MP4s with private Motion OS and
  attaches them as GitHub Release assets. Use when preparing a GitHub Release,
  publication package, draft release assets, github-release-notes, or when the
  maintainer asks for a demo/film for a version with visible UI changes.
---

# CarrotType release motion

Shared project skill (canonical path: `.agents/skills/carrottype-release-motion/`). Cursor/Claude entrypoints are symlinks to this folder.

## Authority

Follow **`ops/release-motion.md`** (when required + locked filename/format) and **`ops/motion-tooling.md`** (`MOTION_OS_ROOT` pin). Do not invent a parallel process.

## Steps

1. Decide Yes / N/A / waiver per `ops/release-motion.md`.
2. If Yes: set `MOTION_OS_ROOT`, write/update `motion/briefs/<slug>.md`, run:
   - `npm run motion -- run motion/briefs/<slug>.md --no-capture`
   - `npm run motion -- check motion/out/<slug>.mp4`
3. Rename to `CarrotType-{version}-{slug}-demo.mp4` under `dist/` for upload.
4. Attach to the GitHub Release; add **Демо** link (+ optional SHA) in `docs/github-release-notes-v{version}.md`.
5. Never commit mp4s to `main`; never add `motion-os` as an npm dependency.

## House rules

Silent H.264, ≤60 s (target 15–30), 1920×1080, effect clicks only (no cursor).
