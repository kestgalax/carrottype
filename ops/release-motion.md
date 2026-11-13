# Release motion companion (locked format)

Short silent product films that accompany a GitHub Release when the version ships a **visible UI / Settings / Capsule** change. Produced with private Motion OS (`ops/motion-tooling.md`). Not part of the macOS app binary or Sparkle feed.

## When required

During **release preparation** (after maintainer publication authorization, before or while attaching draft assets), the agent **must** decide:

| Release content | Motion companion |
| --- | --- |
| Visible UI / Settings / Capsule / sheet / What’s New UX | **Yes** — at least one short film for the hero change |
| Metadata-only, docs-only, CI-only, invisible bugfix | **No** — record “N/A” in the release notes verification section |
| Maintainer explicitly waives | **No** — quote the waiver in notes |

If unsure, prefer **one** Remotion-only film over skipping a visible feature.

## Locked asset format (next release onward)

| Field | Value |
| --- | --- |
| Container | H.264 MP4, **no audio stream** (silent) |
| Duration | target **15–30 s**, hard max **60 s** |
| Resolution | **1920×1080**, 30 fps |
| Click language | effect clicks only (**no mouse cursor**) |
| Git | **do not** commit the mp4 into `main`; keep under `motion/out/` (gitignored) or `dist/` |
| GitHub | attach as a **Release asset** next to DMG/ZIP |
| Filename | `CarrotType-{version}-{slug}-demo.mp4` (example: `CarrotType-0.12.0-theme-demo.mp4`) |
| Notes link | in `docs/github-release-notes-v{version}.md`, under a **«Демо» / Demo** subsection: one markdown link to the release asset URL (filled after upload) |
| SHA-256 | optional row in the notes SHA table for the mp4 |

## How to produce

1. Ensure `MOTION_OS_ROOT` points at pinned `kestgalax/motion-os` (`ops/motion-tooling.md`).
2. Brief under `motion/briefs/` (or extend an existing skin) for the **hero** change of this version.
3. `npm run motion -- run motion/briefs/<slug>.md --no-capture` (Remotion-only is Pass for release companions unless hybrid is explicitly needed).
4. `npm run motion -- check motion/out/<slug>.mp4`
5. Copy/rename to `dist/CarrotType-{version}-{slug}-demo.mp4` for upload with the draft release.
6. After the asset exists on the GitHub Release, add the Demo link + optional hash in the notes file.

## Out of scope

- Embedding video inside the in-app What’s New / Sparkle HTML (separate decision).
- Ambient audio / voiceover unless the maintainer supplies a bed and asks to mux.
- Making Motion OS public or adding it as an npm dependency of CarrotType.
