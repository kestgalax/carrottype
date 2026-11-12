# CarrotType 0.11.1 — release review evidence

Date: 2026-11-12. Status: **published stable/latest as 0.11.1 (36) on 2026-11-12T00:10:38Z.** This
record extends the accepted Debug evidence; it is not a new manual acceptance of changed app
behavior.

## Acceptance and authorization

The maintainer authorized review of the locale/quit-install Debug fix and publication if it is
acceptable. The coordinator reviewed the Debug build on `kestgalax/update-locale-quit-fix-2`
(code `f0cff02`, evidence `7633120`) and accepted it for release. Published stable is already
**0.11.0 (35)**, so this release is **0.11.1 (36)**; 0.11.0/35 is not reused.

Accepted application behavior remains frozen at `f0cff02`:

- shared `AppLanguageCode` resolution for What's New and the Sparkle `AppleLanguages` bridge;
- the background-download toggle explains its dependency on automatic checks;
- quit drains active work instead of returning `.terminateCancel`;
- `willInstallUpdateOnQuit` stays `false` per ADR-017 (installer after exit, no forced relaunch).

No Swift/application-behavior changes were made after `f0cff02`. The release commit changes only
version/build metadata, bundled release notes/history and documentation.

## Source and release diff

- Branch base: `origin/main` `7c004cd` (published 0.11.0 closeout).
- Accepted application code and evidence: `f0cff02` / `7633120`.
- Release metadata commit: `d719170` — bumps **0.11.1 (36)**, archives the published 0.11.0
  `ReleaseNotes.json` unchanged at the top of `ReleaseNotesHistory.json`, and authors RU/EN
  bugfix notes from the same single source.
- Release diff after `f0cff02` is limited to `CFBundleShortVersionString`,
  `CFBundleVersion`, `ReleaseNotes.json`, `ReleaseNotesHistory.json` and documentation.
- No engine/runtime/dependency/network/catalog/model/preference/installation/login-item changes
  and no new saved values. AIDOS and CarrotType templates are untouched.

## Local release evidence

- `bash scripts/verify-release-notes.sh`: **PASS** — matching metadata, contiguous history
  36→27 (nine archived releases plus current build 36), RU/EN validation, rendering/escaping,
  language bridge ownership, fallback and corrupt/missing archive behavior.
- `bash scripts/verify-app-updates.sh`: **PASS** — queued start, busy install, nested teardown,
  final termination guard, atomic hand-off, abort/retry; quit install drains and then allows
  Sparkle install-on-quit; the application delegate always routes through `prepareForQuit` and
  never invents a cancel.
- Fresh clean arm64 Release build from the release commit: **BUILD SUCCEEDED**
  (`/tmp/build-0111.log`), signed `CarrotType Development`; app/helper deep-strict valid.
- Finder layout automation again failed with the documented `-1743` (no user permissions were
  changed). The checksum-verified published 0.11.0 DMG was reused as the installer filesystem
  template:
  `f231d29d906309ba5a42fd3f43d87f3c77a84c85d8e89294f012a13d3b3c2b9a`, 23,830,560 bytes.
  `.DS_Store` (`168249954ca4048d6c8970609563ddb655cc62c7c3ff2189ddc8fb4bce55ed84`) and
  `.background/background.tiff`
  (`80495495b97af5f0b3dd8312a15a72f7c849f7c16c81d71ad0a4a22b62f8d64c`) were byte-identical
  before/after app replacement; the Applications symlink and Finder layout were preserved.
- Final DMG: `dist/CarrotType-0.11.1.dmg`, length 23,827,857, SHA-256
  `11de7b60656b6f90773743e22f055ee3dfedc7dd7f8b4e8111e29a2f9e5df4bf`, `hdiutil verify`
  VALID. The mounted read-only app is arm64 0.11.1 (36), identifier `app.carrottype.macos`,
  `CarrotType Development`, deep-strict valid; helper and `mlx-swift_Cmlx.bundle` present,
  Applications link present, no model weights found. Executable SHA-256
  `13631feed8f344e8eebbd0174aafded19f99ed1a2d4f5c77856d3d10f6bbc9f0`; helper SHA-256
  `025b47ae62fa1ded5d3dcd3592c6644e6679a43ac56d42288535be15ea10d524`; app CDHash
  `fa4e3c049c4411991288f4220c18fce4473024cd`, helper CDHash
  `e78d432ba42e2a4c6f61096c07af52412d742771`.
- Signed update archive `dist/updates-0.11.1/CarrotType-0.11.1-36.zip`, length 23,894,862,
  SHA-256 `2c8d417b9ae794cb3e160c858e3c41cdec9abb9245445943d2bb0cc071af8e27`; the extracted app
  is deep-strict valid and its executable/helper hashes match the DMG app.
- Signed `dist/updates-0.11.1/appcast.xml`, length 41,074, SHA-256
  `2063ac0f5a1151b2f213f8e9a826eb1c34969fa1aa61f82e634107a21fde8adb`; `sign_update --verify`
  passes archive/feed. Build 36/0.11.1, versioned archive URL
  `.../releases/download/v0.11.1/CarrotType-0.11.1-36.zip`, matching length, RU/EN inline
  notes and ten release articles (current + history 35→27) verified.
- Isolated native staging `dist/update-locale-quit-fix-0.11.1-update-test/results.txt` (fresh
  identity `app.carrottype.macos.update-test.cfb790be74bd4d889135a3640d7a04d5`): offline,
  tampered-feed and corrupt-archive rejected with the expected errors; available probe found 36;
  native **A35→B36** installed build 36; no-new-version returned exit 4; external fixture files
  preserved; no `/Applications`, production profile or TCC changes.

## Debug and candidate-code boundaries

- Accepted Debug remains preserved under
  `dist/.builds.noindex/Update-Locale-Quit-Fix-Debug-2026-11-12/CarrotType.app`
  (version 0.11.0 (35), executable SHA-256
  `8ee6ca8276881896ce722595e5683e63be1511c4cc67cfa8dfd03d9c2d19acb5`, debug dylib
  `19bac9d285557d7607151f1f54893b4e27438b46e0cc562aa925c1f3f5d6ac44`, helper
  `781644732b82e7ae1e8e012ffdede84a6019826cb32a5de1eafd555892c2186b`, CDHash
  `7a21cfe6ba3785ce39782f7ee55d9e7d2482d8e8`). It was not replaced or re-signed.
- The staging A/B fixtures are signed copies of a fresh Debug build carrying build 36 and the
  new notes; they are candidate-code fixtures, not separately compiled historical binaries.
  They prove the native installer path, not historical-binary behavior or TCC continuity.

## Limitations (retained)

- The installed user app was not replaced, launched against the user profile, or used for an
  interactive screenshot of the Sparkle alert. The native bridge is proven by Foundation's
  app-bundle selection and the production bridge code; next-launch timing is a Foundation cache
  property, not a UI claim.
- A full interactive "download on schedule → quit → confirm installed version" walkthrough with
  a real staged download was not performed; the quit drain is covered by the production gate/
  termination checks and Sparkle's documented install-on-quit path.
- Physical device recording, third-party IME/dead keys, VoiceOver, real TCC continuity and a full
  network audit remain manual/unverified.
- Self-signed/unnotarized posture is unchanged. No private updater key was exported; no
  installed app, user preferences, models, Keychain items, login items or published assets were
  changed.

## Draft, PR and CI

- PR [#33](https://github.com/kestgalax/carrottype/pull/33) targets `main` from
  `kestgalax/update-locale-quit-fix-2`; checked head `5bc877b`.
- Hosted `macOS checks` run
  [43124371738](https://github.com/kestgalax/carrottype/actions/runs/43124371738) passed for the
  exact checked head `5bc877b` (production regressions, Debug arm64 compile and isolated app
  checks). Private hosted AIDOS was explicitly skipped because the read token is unavailable; no
  hosted governance success is claimed.
- Draft release (`v0.11.1`, tag created on publication) contained `CarrotType-0.11.1.dmg`
  (asset `RA_kwDOThgsOs4r81Le`), `CarrotType-0.11.1-36.zip` (`RA_kwDOThgsOs4r81Lb`) and
  `appcast.xml` (`RA_kwDOThgsOs4r81LZ`).
- `python3 macos/scripts/verify-update-release.py --tag v0.11.1 --previous-build 35
  --sparkle-bin macos/.derivedData-release/SourcePackages/artifacts/sparkle/Sparkle/bin` passed
  authenticated draft signatures, identity, version, lengths, URLs and GitHub asset digests
  (`/tmp/verify-draft-0111.log`). Uploaded asset digests matched the local SHA-256 values above.

## Publication closeout — 2026-11-12

- Stable/latest **0.11.1 (36)** published at 2026-11-12T00:10:38Z; tag `v0.11.1` /
  `5bc877b97fea7d624860a022288d326b1adc5595`. PR #33 merged as
  `17ab70d1b19364e163557b4a6224669636bc3725`.
- Post-publication `verify-update-release.py --published` passed public latest/feed/archive
  signatures, metadata, URLs and digests (`/tmp/verify-published-0111.log`).
- Native resolved Sparkle CLI with the isolated `manual-A` build-35 update-test identity and the
  production public key probed the live HTTPS latest feed: **exit 0, “Update available!”**, probe
  only, no installation (`dist/public-native-0.11.1.log`).
- Published assets are immutable and remain the byte-identical files recorded above. No installed
  app, user preferences/models/login items or private keys were changed or exported.
