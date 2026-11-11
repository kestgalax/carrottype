# CarrotType 0.10.0 — release review evidence

Date: 2026-11-11. Status: **release 0.10.0 (34) prepared as a verified draft/PR; not merged or
published.** Stable/latest remains 0.9.0 (33). This record is release-preparation evidence, not
manual acceptance.

## Acceptance and authorization

After the delivered signed Debug and Codex R1/R2 re-review, the maintainer explicitly authorized
publication: «мне нравится, можем публиковать». Individual manual device/IME/VoiceOver/TCC
results were not enumerated; this record does not claim that those checks passed.

## Source and release diff

- Release base: `origin/main` `58bdca2` (published 0.9.0).
- Accepted application behavior/source: `1736262` (typing-speed implementation plus approved
  R1/R2 focus/accessibility fixes). No Swift/app behavior change after it.
- Release metadata commit: `7c1dfdc` bumps 0.10.0 (34), archives the published 0.9.0
  `ReleaseNotes.json` unchanged at the top of `ReleaseNotesHistory.json`, and authors RU/EN
  notes from the bundled single source.
- Release diff is limited to version/build, `ReleaseNotes.json`,
  `ReleaseNotesHistory.json`, generated project/Info metadata and release documentation.
- No engine/runtime/dependency/network/catalog/model/preference/installation/login-item
  changes. No scoring/feature/settings reorganization; GigaAM is not part of this release.
  The Dynamic Island pane name remains untranslated.

## Local release evidence

- `bash scripts/verify-release-notes.sh`: PASS (contiguous history 33→27, RU/EN validation,
  rendering/escaping, fallback, corrupt/missing archive behavior).
- `bash scripts/verify-typing-speed-test.sh`: PASS (3×2 prompts, seeded variation,
  metric/deadline/NFC/IME/refill/range fixtures, empty/low-accuracy policy).
- `python3 scripts/verify-typing-speed-app.py --build-log /tmp/debug-010-clean.log`: PASS
  (actual AppState/gate/hotkey fakes, native input adapter, real mounted-sheet Start/focus
  regression, 20-cycle cleanup, 36 native whole-Settings+sheet snapshots).
- Relevant regressions: `verify-dynamic-island.sh`, `verify-session-lifecycle.sh`,
  `verify-setup-formatting.sh`, `verify-app-updates.sh`, `verify-formatting-rules.sh`,
  `verify-dictation-reliability.sh` — PASS.
- Local AIDOS `validate`/`trace`/`review` — PASS (no missing links; Outcome: Approve).
- Clean arm64 Release build: **BUILD SUCCEEDED** (`/tmp/build-010.log`). The normal DMG script
  reached the documented Finder automation failure (`-1743`); no user permissions were changed.
- The checksum-verified published 0.9.0 DMG was reused as the installer filesystem template:
  `2c51717d4294f41671a554f5e754f2bf76e0ec07166aac2b5671fe5882e2a595`, 23,892,094 bytes.
  `.DS_Store` (`168249954ca4048d6c8970609563ddb655cc62c7c3ff2189ddc8fb4bce55ed84`)
  and `.background/background.tiff`
  (`80495495b97af5f0b3dd8312a15a72f7c849f7c16c81d71ad0a4a22b62f8d64c`) were unchanged
  before/after app replacement; the Applications symlink, layout and Finder window were
  preserved.
- Final DMG: `dist/CarrotType-0.10.0.dmg`, length 23,834,939, SHA-256
  `0313202e7a523095ced62143698e776c1c297f341e6a78967874221aae3d0313`, `hdiutil verify`
  VALID. Mounted read-only app is arm64 0.10.0 (34), identifier `app.carrottype.macos`,
  `CarrotType Development`, deep-strict valid; helper and `mlx-swift_Cmlx.bundle` present,
  Applications link present, no model weights found. Executable SHA-256
  `9ad1f609dee2327c340a99c36a84718f892bfd7dc0e835266e75e992eb295beb`; helper SHA-256
  `0021f77aa5046236afdb06b7fbc306b5be3fb54b7288a3eeb8625f7a94223574`; app CDHash
  `60f3843e97fdb08674f26f2bff1a9b57f757cd19`, helper CDHash
  `c949895fa1c22d964b137b2902ffac1cdbcf3edd`.
- Signed update archive `dist/updates-0.10.0/CarrotType-0.10.0-34.zip` length 23,879,143,
  SHA-256 `70191cdc5370d0bcecae188026bd044571a9a9a5bc11c41ce2bcf45082d323e7`; extracted app
  deep-strict valid and executable hash matches the DMG app.
- Signed `dist/updates-0.10.0/appcast.xml` length 30,611, SHA-256
  `d295a82beb2cc971c1dbe2c87c2bfe9a97e4eb176155344017907905ae4bfd63`; `sign_update --verify`
  passes archive/feed. Build 34/0.10.0, versioned archive URL, matching length, RU/EN inline
  notes and eight release articles (current + history 33→27) verified.
- Isolated native staging `dist/typing-speed-0.10.0-update-test/results.txt` (fresh identity
  `app.carrottype.macos.update-test.6b3e9d93c4bb41ecb75ee4253721acc5`): offline, tampered feed
  and corrupt archive rejected with the expected errors; available probe found 34; native
  A33→B34 installed build 34; no-new-version returned exit 4; external fixture files
  preserved; no `/Applications`, production profile or TCC changes.

## Debug and candidate-code boundaries

- Accepted Debug apps remain preserved under
  `dist/.builds.noindex/Typing-Speed-Debug-2026-11-11` and
  `dist/.builds.noindex/Typing-Speed-Debug-R1R2-2026-11-11`.
- A separate signed Debug candidate at 0.10.0 (34) was built for staging:
  `dist/.builds.noindex/Typing-Speed-Release-0.10.0-Candidate-Debug-2026-11-11/CarrotType.app`
  (executable SHA-256 `25997e0e7e0322e10f6b9a19c7bf165e9448e2ca9cf5ecbeeea424e1e0d4beca`,
  `CarrotType.debug.dylib` `0a0b92ead734bf18e7b1fa9eedf0fa99c74700fdf694665bcfd5780d08cda780`).
- Staging A/B apps are candidate-code fixtures with synthetic identities, not separately
  compiled historical binaries. They prove the native installer path, not historical-binary
  behavior or independent TCC continuity.

## Limitations (retained)

- Physical live-sheet typing, actual third-party IME/dead-key composition, VoiceOver reading
  order/announcements, real app deactivation/sleep, real-device recording and independent
  TCC/network checks remain manual/unverified unless separately performed.
- Offscreen/native fixtures and candidate-code staging are not interactive acceptance.
- No private updater key was exported; no installed app, user preferences, models, login items
  or published assets were changed.

## Draft, PR and CI

Pending at documentation commit; final IDs/heads are recorded by the closeout commit.
