# CarrotType 0.9.0 — release review evidence

Date: 2026-11-11. Status: **release candidate prepared as a verified draft; not published.**
Stable/latest remains 0.8.2 (32). Publication is the coordinator's final gate.

## Acceptance and authorization

The maintainer explicitly accepted the delivered signed Debug and authorized
publication: «можно публиковать». Individual manual results were not enumerated; this
record does not claim that every device/TCC/VoiceOver/fullscreen check passed.

## Source and release diff

- Accepted application behavior/source: `0908750` (Dynamic Island implementation + R1–R3).
- Release metadata commit: `c6f801e` bumps 0.9.0 (33), archives the published 0.8.2
  `ReleaseNotes.json` unchanged at the top of `ReleaseNotesHistory.json`, and authors RU/EN
  0.9.0 notes.
- Release diff is limited to version/build, `ReleaseNotes.json`,
  `ReleaseNotesHistory.json`, generated project/Info metadata and release documentation.
- No engine/runtime/dependency/network/catalog/model/preference/installation/login-item
  changes. GigaAM remains deferred; 0.9.0 does not deliver it.

## Local release evidence

- `bash scripts/verify-release-notes.sh`: PASS (cumulative history from build 27 through 32,
  RU/EN validation, rendering/escaping, fallback, corrupt/missing archive behavior).
- Clean arm64 Release build: **BUILD SUCCEEDED** (`/tmp/ct-release-0.9.0.log`).
- The normal DMG script reached the documented Finder automation failure (`-1743`). The
  checksum-verified 0.8.2 DMG was used as the filesystem template
  (`0d6bb879f769e94e7e157a59577377fb6768b8f126b9cc0862fd1012199ec3c7`); `.DS_Store` and
  `.background/background.tiff` hashes were unchanged before/after app replacement.
- Final DMG: `dist/CarrotType-0.9.0.dmg`, length 23,892,094, SHA-256
  `2c51717d4294f41671a554f5e754f2bf76e0ec07166aac2b5671fe5882e2a595`, `hdiutil verify`
  VALID. Mounted read-only app is arm64 0.9.0 (33), `CarrotType Development`, deep-strict
  valid, helper and `mlx-swift_Cmlx.bundle` present, Applications link present, no model
  weights found. Executable SHA-256:
  `7f3d9d3a3591cdf8582757ca485c298489424d3b844c50318417575318b082a6`.
- Signed update archive `dist/updates-0.9.0/CarrotType-0.9.0-33.zip` length 23,753,722,
  SHA-256 `4c1a0f7945d3e87fc11312d12fa68ab7d9e8fcc3e3c2d34074cde672cdec757a`; extracted app
  deep-strict valid and executable hash matches the DMG app.
- Signed `dist/updates-0.9.0/appcast.xml` length 25,523, SHA-256
  `bd382832fe95d601fde9015325522009384f00bde708e56d9522e13de95c588a`; `sign_update --verify`
  passes archive/feed. Build 33/0.9.0, versioned archive URL, matching length, RU/EN inline
  notes and seven release articles (current + six history) verified.
- Isolated native staging `dist/staging-0.9.0/results.txt`: offline, tampered feed and
  corrupt archive rejected; available probe found 33; native A32→B33 installed build 33;
  no-new-version returned exit 4; external fixture files preserved; no `/Applications` or
  TCC changes. Candidate-code fixtures, not a historical-binary/TCC proof.

## Limitations

- Real-device recording/notch/fullscreen/VoiceOver and independent TCC/network checks remain
  manual/unverified unless separately performed.
- Offscreen/native fixture evidence and candidate-code staging are not interactive
  acceptance.
- The draft release, PR/CI links and hosted verification are recorded in the coordinator
  report when available; no public latest/live release was mutated by this preparation.
- No private updater key was exported; no published artifact/release history was rewritten.
