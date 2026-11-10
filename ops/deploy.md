# Deploy / GitHub Release

CarrotType ships as a **macOS `.dmg`** from GitHub Releases. Model weights are **not** bundled (ADR-003); users download STT/cleanup packages in Settings.

## Repository visibility

The GitHub repository **may be public** (MIT, [ADR-011](../docs/decisions/ADR-011-public-mit-distribution.md)). GitHub Releases are a valid public download channel for unsigned `.dmg` builds. Notarization is **not** required to open the repo or attach Release assets.

To flip visibility after documentation is merged:

```bash
gh repo edit kestgalax/carrottype --visibility public
```

## v1 path (current): no Apple Developer notarization

Unsigned Release builds are intentional for personal / portfolio distribution until (optionally) a Developer ID certificate is used.

### Build the DMG

By default the script **reuses** `macos/.derivedData-release` for incremental Release builds. For a tagged GitHub Release (or when debugging stale/crashy frameworks), wipe the cache first:

```bash
cd /path/to/carrottype
chmod +x macos/scripts/build-release-dmg.sh
CLEAN=1 ./macos/scripts/build-release-dmg.sh
```

Everyday local DMG iteration can omit `CLEAN` (faster):

```bash
./macos/scripts/build-release-dmg.sh
```

Output: `dist/CarrotType-<version>.dmg` (version from `macos/project.yml` → `CFBundleShortVersionString`).

The disk image uses a custom Finder window (English “To install, *drag*…” plus a straight carrot-coloured arrow). Layout lives in [`macos/packaging/dmg/layout.sh`](../macos/packaging/dmg/layout.sh). Rebuild the committed background with:

```bash
swift macos/scripts/render-dmg-background.swift
```

Then run `build-release-dmg.sh` as usual. The script mounts a read-write image, applies Finder icon positions via AppleScript, and converts to UDZO. This does **not** notarize the app.

Optional:

```bash
VERSION=0.1.1 SIGN_IDENTITY="CarrotType Development" ./macos/scripts/build-release-dmg.sh
# or ad-hoc:
SIGN_IDENTITY="-" ./macos/scripts/build-release-dmg.sh
# full rebuild:
CLEAN=1 ./macos/scripts/build-release-dmg.sh
```

Local self-signed identity (`macos/scripts/ensure-dev-codesign.sh`) helps **dev TCC**, not Gatekeeper for downloads from the internet.

**Launch crash note:** Hardened Runtime rejects embedded `whisper.framework` when Team IDs differ (typical with self-signed SPM builds). The release script resigns frameworks inside-out **without** `--options runtime`, and embeds `com.apple.security.cs.disable-library-validation`. `xattr -dr com.apple.quarantine` does **not** fix this crash — that only helps Gatekeeper “unidentified developer” prompts. If an old install still crash-loops, replace `/Applications/CarrotType.app` from a freshly built DMG (or re-run the resign path in `build-release-dmg.sh`).

**Smart cleanup helper (ADR-009):** the DMG `.app` must include `Contents/MacOS/CarrotTypeCleanupHelper` and `Contents/Resources/mlx-swift_Cmlx.bundle`. The release script resigns the helper before the outer app and fails if either is missing.

### Publish on GitHub

1. Tag: `v0.1.1` (match version).
2. Create a Release; attach `dist/CarrotType-0.1.1.dmg`.
3. Paste install notes from [docs/github-release-notes-v0.1.1.md](../docs/github-release-notes-v0.1.1.md) (or the template below).

### Install UX without notarization (Gatekeeper)

Anyone who downloads the DMG from GitHub Releases will still see “Apple cannot check for malicious software” until the app is notarized.

**Recommended:**

1. Open the `.dmg`, drag **CarrotType** to **Applications**.
2. First launch is usually **blocked** by Gatekeeper (double “Open” alone is often not enough on current macOS):
   1. In Finder → **Applications**, open CarrotType (or **Right-click → Open**).
   2. Dismiss / acknowledge the blocked-app warning if shown.
   3. Open **System Settings → Privacy & Security** and under the blocked-app notice choose **Open Anyway**.
   4. Confirm the final Open prompt for CarrotType.
3. Alternatively clear quarantine (still may need Privacy & Security on some macOS versions):

```bash
xattr -dr com.apple.quarantine /Applications/CarrotType.app
```

Then grant **Microphone** + **Accessibility**, download **Parakeet Ultra** if not already installed (0.4.0, ADR-016). Older model files are preserved and can be removed explicitly in Storage.

### What not to ship in the DMG

- Parakeet / Qwen / Gemma weights (nor retired Whisper files)
- DerivedData, `.env`, signing private keys

## Follow-up: Developer ID + notarization (after $99 Apple Developer)

Unsigned Releases remain valid (ADR-011). When a **Developer ID Application** certificate is available, use this checklist. Placeholders only: [`notarization.env.example`](notarization.env.example). Do **not** commit real Apple ID passwords or `.p12` files.

### Checklist

1. **Certificate:** Xcode → Settings → Accounts → Manage Certificates → **Developer ID Application** (install in Keychain).
2. **Build signed DMG** (host + helper + embedded frameworks via release script):

```bash
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" CLEAN=1 ./macos/scripts/build-release-dmg.sh
```

3. **Store notary credentials once** (Keychain profile; prefer over env passwords):

```bash
xcrun notarytool store-credentials "carrottype-notary" \
  --apple-id "you@example.com" \
  --team-id "TEAMID" \
  --password "app-specific-password"
```

4. **Submit + staple** (or use the helper script):

```bash
# Helper (fails closed if the Keychain profile is missing):
./macos/scripts/notarize-dmg.sh dist/CarrotType-<version>.dmg

# Or manually:
xcrun notarytool submit dist/CarrotType-<version>.dmg \
  --keychain-profile "carrottype-notary" \
  --wait
xcrun stapler staple dist/CarrotType-<version>.dmg
spctl --assess --type open --verbose dist/CarrotType-<version>.dmg
```

5. **Clean Mac check:** double-click opens without Privacy & Security → Open Anyway.
6. **Release notes:** remove the Gatekeeper workaround section only after staple succeeds; never claim notarized without evidence.

Until credentials exist, keep documenting the quarantine / Right-click / Open Anyway path in every Release.

## Finder automation unavailable: preserve the existing installer template

For v0.3.10, the clean Release app build and inside-out signing succeeded, but Finder layout AppleScript failed with `-1743` (Apple Events not authorized). No user permissions were changed. The verified v0.3.9 DMG was reused as an installer filesystem template:

1. Verify the old DMG SHA-256 against its release notes before use.
2. `hdiutil convert <old.dmg> -format UDRW -o <temporary-template.dmg>`; attach read-write with `-noautoopen -nobrowse -mountpoint <temporary-mount>`.
3. Replace only `CarrotType.app` with the freshly built/signed `dist/dmg-stage/CarrotType.app` using `ditto`. Preserve `.DS_Store`, `.background` and the Applications symlink. Cloning the filesystem retains the background alias/file identity. Compare `.DS_Store` and background hashes before/after.
4. Verify the new app version, deep signature, embedded helper and metallib; remove only the template's transient `.fseventsd`, sync and detach the temporary device.
5. Convert the template to final UDZO DMG, run `hdiutil verify`, mount read-only to inspect the final app, record its SHA-256, then publish.

Use a temporary directory and always detach the specific device created for the operation. This preserves installer appearance without dropping the custom window or requesting Finder automation access. It does not notarize the app. Keep the normal build script as the default when Finder automation is available.

## Signed application updates — 0.5.0 (ADR-017)

Release preflight on 2026-11-10 found the repository private, which prevents unauthenticated updater access. The maintainer explicitly authorized making its code/history public; repository visibility was changed to public and verified before release. Keep release assets anonymously accessible; do not embed a GitHub token. Changing visibility in future requires its own explicit instruction.

First install remains a DMG. Stable feed: `https://github.com/kestgalax/carrottype/releases/latest/download/appcast.xml`. The signed feed is live since v0.5.0; it returned 404 before that publication. Do not publish a dummy release to make Debug checks appear successful. Never attach a staging feed to production.

### Signing key

Sparkle tools are in `macos/.derivedData/SourcePackages/artifacts/sparkle/Sparkle/bin` after dependency resolution. A persistent production key has been generated in login Keychain account `app.carrottype.macos.updates`; the committed `SUPublicEDKey` is public. To print **only the public key**:

```bash
macos/.derivedData/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_keys --account app.carrottype.macos.updates -p
```

The maintainer should make an encrypted offline backup **outside the repository** with Sparkle's `generate_keys --account … -x <protected-external-path>` and import with `-f` only for recovery. Do not place an export in `dist`, temporary logs, CI or chat. `prepare-update.py` checks the public key matches before signing and never exports it. Without the key or its backup, current self-signed clients need a manual reinstall containing a new key. No unsigned/feed-expiry fallback. EdDSA does not replace Gatekeeper/notarization.

### Prepare release assets locally

1. Run the relevant tests and build Debug, provide it for manual review, and obtain explicit acceptance before publication. Read-only/DMG/translocation, native UI and actual microphone/Accessibility after replacement must be checked manually.
2. Clean Release build and DMG as above. `sign-app.sh` signs Sparkle's nested installer/app/XPC components, cleanup helper and outer app inside-out, preserving nested entitlements and clearing Hardened Runtime for our local self-signed posture. Verify `codesign --verify --deep --strict`. Keep the signed app copy used for the DMG for the ZIP; do not re-sign it after archiving.
3. Determine the previous stable **CFBundleVersion** from the actual prior app, not its marketing version. This release is `0.5.0 (25)` following `0.4.0 (24)`; increase monotonically for every future release. Short inline plain-text update notes go in a local file.

```bash
python3 macos/scripts/prepare-update.py \
  --app dist/dmg-stage/CarrotType.app \
  --output-dir dist/updates-0.5.0 \
  --sparkle-bin macos/.derivedData/SourcePackages/artifacts/sparkle/Sparkle/bin \
  --previous-build 24 --notes /path/to/short-update-notes.txt
```

The normal DMG script removes `dmg-stage` after packaging; preserve a signed copy in a separate dist directory before that cleanup, or mount the verified final DMG read-only and pass its app path. The script produces `CarrotType-0.5.0-25.zip` and signed `appcast.xml`, rejects prerelease versions, mismatched identities/keys or disabled signature settings, and refuses existing outputs. It signs and verifies both assets without publishing anything. SPM tools/pin must match the app's Sparkle version; CI signing remains deferred until secret custody is designed.

### Publish only after the user's approval

Create a draft release for the matching tag. Upload DMG and signed ZIP first, then the signed appcast. Download draft assets via authenticated GitHub API and compare hashes/signatures/length/version/URLs to the local prepared assets. Confirm release is neither prerelease nor an unintended older build; publish as stable/latest only after these checks. Draft/prerelease feeds must never become stable. Use `python3 macos/scripts/verify-update-release.py --tag v0.5.0 --previous-build 24 --sparkle-bin macos/.derivedData/SourcePackages/artifacts/sparkle/Sparkle/bin` as the read-only draft gate. After publication repeat with `--published` to verify the client-facing stable endpoint and public archive through HTTPS redirects. GitHub's latest-release asset endpoint keeps feed and archives within the same release; keep published assets immutable. A failed/missing feed leaves the installed app usable and manual DMG installation available. Never overwrite a signed archive or edit signed XML; regenerate and sign again before publication.

### Isolated native installer test

```bash
bash scripts/verify-app-updates.sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
python3 scripts/verify-update-staging.py \
  --app dist/CarrotType-0.5.0-Debug/CarrotType.app \
  --output-dir dist/CarrotType-0.5.0-update-test
```

Use a fresh output directory. This compiles the exact resolved Sparkle source's official command-line driver against its checksum-verified SPM framework. It uses two signed real app bundles with build numbers 25/26 and isolated `app.carrottype.macos.update-test` identity, loopback feed and no public release. Negative checks: unavailable feed, modified signed feed, corrupted archive. Positive checks: available update, native install A → B, no newer version, preserved external fixture files, deep app/helper/metallib verification. Logs and a fresh manual A are retained in the test directory. It never launches the app, touches /Applications or claims TCC acceptance. Fixture preservation is not a test of the user's actual model/statistics data.

For standard native UI testing, run `start-server.command` in that directory, quit other CarrotType copies and open `manual-A/CarrotType.app`. Debug-only staging uses `~/Library/Application Support/carrottype-update-test` and its own preferences; there are no production model weights there unless an independent copy is deliberately prepared. For the current manual candidate, Ultra has been APFS-cloned into the separate test root (original untouched) so the busy-recording and microphone/TCC tests can run offline; cleanup packages are not copied. Check microphone meter/Accessibility before and after the replacement and confirm build 26 in its Info.plist. Test actual dictation, hold/Escape, transforms and update opt-ins separately in the normal Debug candidate; only that copy uses the real profile. Stop the terminal server afterwards. Do not ship the staging identity/feed or add a production HTTP exception.

## v0.5.0 publication verification

2026-11-10: clean Release built in fresh temporary DerivedData. Existing 0.4.0 installer filesystem/template was checksum-verified; new app/components signed inside-out; final DMG integrity, unchanged installer layout/background, helper path jail, MLX shaders and Ultra catalog verified. Artifacts and signed feed were verified locally, downloaded from the draft and verified again, then published stable/latest. The public feed/archive were fetched anonymously and matched the verified assets; Sparkle’s native CLI accepted the live feed and reported no newer version for build 25. SHA-256 records: `docs/github-release-notes-v0.5.0.md`. Private key remained in Keychain; no export performed. Independent TCC continuity and full network audit remain unverified.

If a temporary mounted image refuses detach, detach the whole image device with bounded retries before cleanup. Never recursively remove a temporary workspace while its image is still mounted; preserve it on failure. Only detach the image created for the operation.

## v0.6.0 publication verification

2026-11-10: maintainer accepted Debug 0.6.0 (26) and explicitly authorized publication. Fresh temporary DerivedData Release build; checksum-verified 0.5.0 DMG template with unchanged background/layout; deep/strict app/component signatures, localized microphone purpose, helper path jail, MLX shaders, Ultra catalog and no bundled weights passed. Signed ZIP/appcast and DMG digests/lengths matched downloaded draft assets, then anonymous public feed/archive verification passed after stable/latest publication. Native Sparkle probe from isolated build 25 found the update (no installation or TCC claim). No private key export. Hashes: `docs/github-release-notes-v0.6.0.md`; acceptance/limits: `docs/debug-review-v0.6.0.md`.
