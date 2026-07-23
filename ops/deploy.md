# Deploy / GitHub Release

CarrotType ships as a **macOS `.dmg`** from GitHub Releases. Model weights are **not** bundled (ADR-003); users download STT/cleanup packages in Settings.

## Repository visibility

The GitHub repository is **private**. Release assets (including `CarrotType-0.1.0.dmg`) are available only to users with access to the repo (owner / collaborators / invitees). Do not treat the Release URL as a public download page until visibility and notarization are intentionally opened.

## v1 path (current): no Apple Developer notarization

Chosen while the paid Apple Developer Program is not yet purchased.

### Build the DMG

```bash
cd /path/to/carrottype
chmod +x macos/scripts/build-release-dmg.sh
./macos/scripts/build-release-dmg.sh
```

Output: `dist/CarrotType-<version>.dmg` (version from `macos/project.yml` → `CFBundleShortVersionString`, currently `0.1.0`).

Optional:

```bash
VERSION=0.1.0 SIGN_IDENTITY="CarrotType Development" ./macos/scripts/build-release-dmg.sh
# or ad-hoc:
SIGN_IDENTITY="-" ./macos/scripts/build-release-dmg.sh
```

Local self-signed identity (`macos/scripts/ensure-dev-codesign.sh`) helps **dev TCC**, not Gatekeeper for downloads from the internet.

**Launch crash note:** Hardened Runtime rejects embedded `whisper.framework` when Team IDs differ (typical with self-signed SPM builds). The release script resigns frameworks inside-out **without** `--options runtime`, and embeds `com.apple.security.cs.disable-library-validation`. `xattr -dr com.apple.quarantine` does **not** fix this crash — that only helps Gatekeeper “unidentified developer” prompts. If an old install still crash-loops, replace `/Applications/CarrotType.app` from a freshly built DMG (or re-run the resign path in `build-release-dmg.sh`).

### Publish on GitHub

1. Tag: `v0.1.0` (match version).
2. Create a Release; attach `dist/CarrotType-0.1.0.dmg`.
3. Paste install notes from [docs/github-release-notes-v0.1.0.md](../docs/github-release-notes-v0.1.0.md) (or the template below).

### Install UX without notarization (Gatekeeper)

Collaborators who download the DMG from the private Release will still see “Apple cannot check for malicious software”.

**Recommended:**

1. Open the `.dmg`, drag **CarrotType** to **Applications**.
2. In Finder → Applications: **Right-click CarrotType → Open** → Open.
3. Or clear quarantine:

```bash
xattr -dr com.apple.quarantine /Applications/CarrotType.app
```

Then grant **Microphone** + **Accessibility**, download an STT model (Whisper Base recommended until the RU quality note is filled).

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
