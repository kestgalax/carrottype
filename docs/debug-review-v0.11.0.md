# CarrotType 0.11.0 — release review evidence

Date: 2026-11-12. Status: **release 0.11.0 (35) prepared as a verified draft/PR; not merged or
published at the time of writing.** Stable/latest remains 0.10.0 (34) until publication. This
record is release-preparation evidence, not a new manual acceptance of the frozen app.

## Acceptance and authorization

The maintainer accepted the delivered Settings organization Debug and explicitly authorized
publication: «все ок, можно публиковать», correcting the planned version because the published
stable is already 0.10.0 (34). This release is therefore **0.11.0 (35)**, not another 0.10.0.
Individual manual device/IME/VoiceOver/TCC results were not enumerated; this record does not
claim that those checks passed.

## Source and release diff

- Release base: `origin/main` `22536e7` (published 0.10.0 closeout).
- Accepted application behavior/source: `6cb6212` (settings panes split); no Swift/app behavior
  change after it. Subsequent commits are metadata and documentation only.
- Release metadata commit: `a78d549` bumps 0.11.0 (35), archives the published 0.10.0
  `ReleaseNotes.json` unchanged at the top of `ReleaseNotesHistory.json`, and authors RU/EN notes
  from the bundled single source.
- Release diff is limited to version/build, `ReleaseNotes.json`,
  `ReleaseNotesHistory.json`, generated project/Info metadata and release documentation.
- No engine/runtime/dependency/network/catalog/model/preference/installation/login-item
  changes and no new saved values. GigaAM is not part of this release. The Dynamic Island pane
  name remains untranslated.

## Local release evidence

- `bash scripts/verify-release-notes.sh`: PASS — matching metadata, contiguous history 34→27
  (eight archived releases plus current 35), RU/EN validation, rendering/escaping, fallback and
  corrupt/missing archive behavior.
- `python3 scripts/verify-settings-organization-app.py --build-log /tmp/debug-011-check.log`:
  PASS — actual AppState/pane unmount/hotkey/trial checks and 32 native whole-Settings states
  (eight panes × RU/EN × light/dark) with pinned footer and reachable Dictation bottom.
- `python3 scripts/verify-typing-speed-app.py`, `verify-formatting-app.py` and
  `verify-dynamic-island-app.py` on the same fresh Debug build: PASS, including the real mounted
  Start/focus regression and the Dynamic Island pane following the new sidebar.
- Relevant regressions: `verify-session-lifecycle.sh`, `verify-dictation-reliability.sh`,
  `verify-setup-formatting.sh`, `verify-typing-speed-test.sh`, `verify-formatting-rules.sh`,
  `verify-launch-at-login.sh`, `verify-ultra-models.sh`, `verify-app-updates.sh`,
  `verify-model-catalog-streaming.py`, `verify-brand.py` — PASS.
- Local AIDOS `validate`/`trace`/`review` — PASS (no missing links; Outcome: Approve).
- Fresh clean arm64 Release build: **BUILD SUCCEEDED** (`/tmp/build-011.log`). The normal DMG
  script reached the documented Finder automation failure (`-1743`); no user permissions were
  changed.
- The checksum-verified published 0.10.0 DMG was reused as the installer filesystem template:
  `0313202e7a523095ced62143698e776c1c297f341e6a78967874221aae3d0313`, 23,834,939 bytes.
  `.DS_Store` (`168249954ca4048d6c8970609563ddb655cc62c7c3ff2189ddc8fb4bce55ed84`)
  and `.background/background.tiff`
  (`80495495b97af5f0b3dd8312a15a72f7c849f7c16c81d71ad0a4a22b62f8d64c`) were unchanged
  before/after app replacement; the Applications symlink, layout and Finder window were
  preserved.
- Final DMG: `dist/CarrotType-0.11.0.dmg`, length 23,830,560, SHA-256
  `f231d29d906309ba5a42fd3f43d87f3c77a84c85d8e89294f012a13d3b3c2b9a`, `hdiutil verify`
  VALID. Mounted read-only app is arm64 0.11.0 (35), identifier `app.carrottype.macos`,
  `CarrotType Development`, deep-strict valid; helper and `mlx-swift_Cmlx.bundle` present,
  Applications link present, no model weights found. Executable SHA-256
  `b700cde8cfcf9b9ff3ac8500c8fdeac41184c6f56008f62ef89af3ae95f1b743`; helper SHA-256
  `167f4b70648d350487c14c35a15cbed4774a3dfefb2b9fa81f8ea274fe7f1c52`; app CDHash
  `522d1daa5a9e5f0be2da2a678a6ef697078f1da5`, helper CDHash
  `7ccad29c13292a714e408ac87d19c69b9f0fc999`.
- Signed update archive `dist/updates-0.11.0/CarrotType-0.11.0-35.zip` length 23,890,373,
  SHA-256 `4b9d8a1dd789d8acb1fcfa910974b449cf591eff7b856eecd7358b4bb07e3ac8`; extracted app
  deep-strict valid and executable hash matches the DMG app.
- Signed `dist/updates-0.11.0/appcast.xml` length 36,309, SHA-256
  `93ae489310bbf096e545fb06c39f0a631ef7bf0d0b24deaa1dfd59e6ba7ca928`; `sign_update --verify`
  passes archive/feed. Build 35/0.11.0, versioned archive URL, matching length, RU/EN inline
  notes and nine release articles (current + history 34→27) verified.
- Isolated native staging `dist/settings-organization-0.11.0-update-test/results.txt` (fresh
  identity `app.carrottype.macos.update-test.5c8e01b96f714e0eae3b809796b4e342`): offline,
  tampered-feed and corrupt-archive rejected with the expected errors; available probe found 35;
  native A34→B35 installed build 35; no-new-version returned exit 4; external fixture files
  preserved; no `/Applications`, production profile or TCC changes.

## Debug and candidate-code boundaries

- Accepted Settings organization Debug remains preserved under
  `dist/.builds.noindex/Settings-Organization-Debug-2026-11-12` (executable SHA-256
  `bdbcfe75af6ed9f333af3a639378d9b670f17f2e0554afc3a233ff1c0f72e5df`); the prior native
  review snapshots remain under `.../Settings-Organization-Native-Review`.
- The fresh Debug build used for the release checks lives in
  `macos/.derivedData-011-check/Build/Products/Debug/CarrotType.app`; it is a check build, not a
  new accepted candidate.
- Staging A/B apps are candidate-code fixtures with synthetic identities, not separately
  compiled historical binaries. They prove the native installer path, not historical-binary
  behavior or independent TCC continuity.

## Limitations (retained)

- Physical live-window keyboard traversal, actual third-party IME/dead-key composition,
  VoiceOver reading order/announcements, real app deactivation/sleep, real-device recording and
  independent TCC/network checks remain manual/unverified unless separately performed.
- Offscreen/native fixtures and candidate-code staging are not interactive acceptance.
- Self-signed/unnotarized posture is unchanged. No private updater key was exported; no installed
  app, user preferences, models, login items or published assets were changed.

## Draft, PR and CI

- PR [#32](https://github.com/kestgalax/carrottype/pull/32) targets `main` from
  `kestgalax/settings-organization`; checked head `3b561d9`.
- Tag `v0.11.0` is created on publication; application behavior remains `6cb6212` with metadata
  `a78d549`.
- Draft release ID `442261291` (`https://github.com/kestgalax/carrottype/releases/tag/v0.11.0`,
  drafts render as an untagged placeholder) contains `CarrotType-0.11.0.dmg`
  (asset `RA_kwDOThgsOs4r7-V1`), `CarrotType-0.11.0-35.zip`
  (asset `RA_kwDOThgsOs4r7-V2`) and `appcast.xml` (asset `RA_kwDOThgsOs4r7-V3`).
- `python3 macos/scripts/verify-update-release.py --tag v0.11.0 --previous-build 34
  --sparkle-bin macos/.derivedData/SourcePackages/artifacts/sparkle/Sparkle/bin` passed
  authenticated draft signatures, identity, version, lengths, URLs and GitHub asset digests.
- Downloaded draft assets are byte-equal to the local files above (DMG 23,830,560;
  ZIP 23,890,373; appcast 36,309 bytes) with identical SHA-256 values.
- Hosted `macOS checks` run [43112615078](https://github.com/kestgalax/carrottype/actions/runs/43112615078)
  passed for PR head `3b561d9` (7m49s); private hosted AIDOS was explicitly skipped because the
  read token is unavailable, while local validate/trace/review passed.

## 0.11.0 publication closeout — 2026-11-12 (Moscow)

Maintainer accepted the delivered Debug and explicitly authorized publication («все ок, можно
публиковать»), correcting the version to 0.11.0 (35) because 0.10.0 (34) is already stable.
Stable/latest **0.11.0 (35)** published at 2026-11-11T22:41:15Z (01:41 Moscow, November 12).
Accepted application code `6cb6212`, release metadata `a78d549`, tag `v0.11.0` /
`791603eaf4596c2fcac18781c2f1b3e52bf4e9ea`; PR [#32](https://github.com/kestgalax/carrottype/pull/32)
merged as `b1ba27e`. Hosted `macOS checks` **43112615078 passed** on the checked head `3b561d9`
(7m49s); private hosted AIDOS explicitly skipped, local validate/trace/review passed. The
post-CI closeout commit `791603e` is documentation-only and was pushed with `[skip ci]`; it does
not change application code, metadata or release assets.

Published draft assets were byte-identical to the local files. Post-publication
`verify-update-release.py --published` passed public latest/archive signatures, metadata, URLs and
asset digests. Native resolved Sparkle CLI with the isolated `manual-A` build-34 identity and
production public key probed the live HTTPS latest feed: exit0, “Update available!”; probe only, no
installation (log `dist/public-native-0.11.0.log`). DMG/ZIP/feed hashes remain those recorded
above. Self-signed/unnotarized posture, candidate-code fixture and independent
device/IME/VoiceOver/TCC limitations remain. No installed app, user preferences/models/login items
or private keys were changed/exported.
