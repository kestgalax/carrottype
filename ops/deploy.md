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

Then grant **Microphone** + **Accessibility**, download an STT model (**Parakeet TDT 0.6B v3** recommended; Whisper packages remain optional).

### What not to ship in the DMG

- Whisper / Parakeet / Qwen weights
- DerivedData, `.env`, signing private keys

## Follow-up: Developer ID + notarization (after $99 Apple Developer)

When a **Developer ID Application** certificate is available:

1. Install the cert in Keychain (Xcode → Settings → Accounts → Manage Certificates → Developer ID Application).
2. Rebuild:

```bash
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" ./macos/scripts/build-release-dmg.sh
```

Prefer signing the `.app` with hardened runtime before packaging; then notarize:

```bash
# Store credentials once (Apple ID + app-specific password + team id):
xcrun notarytool store-credentials "carrottype-notary" \
  --apple-id "you@example.com" \
  --team-id "TEAMID" \
  --password "app-specific-password"

APP="dist/dmg-extract/CarrotType.app"   # or resign the staged app before hdiutil
# Submit the DMG:
xcrun notarytool submit dist/CarrotType-0.1.0.dmg \
  --keychain-profile "carrottype-notary" \
  --wait

xcrun stapler staple dist/CarrotType-0.1.0.dmg
spctl --assess --type open --verbose dist/CarrotType-0.1.0.dmg
```

3. Verify on a clean Mac: double-click opens without Right-click → Open.
4. Update Release notes to remove the Gatekeeper workaround section.

Until then, keep documenting the quarantine / Right-click path in every Release.
