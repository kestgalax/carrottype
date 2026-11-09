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

Then grant **Microphone** + **Accessibility**, download **Parakeet Ultra** if not already installed (0.4.0 candidate, ADR-016). Older model files are preserved and can be removed explicitly in Storage.

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
