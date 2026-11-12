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
3. Determine the previous stable **CFBundleVersion** from the actual prior app, not its marketing version. Latest stable is `0.10.0 (34)`, following `0.9.0 (33)`. Increase monotonically for every release. Starting in 0.6.1, edit the bundled `Resources/ReleaseNotes.json` (version/build/date plus RU/EN summary and sections); this is the single source for app, appcast and Markdown.

```bash
python3 macos/scripts/prepare-update.py \
  --app dist/dmg-stage/CarrotType.app \
  --output-dir dist/updates-0.6.1 \
  --sparkle-bin macos/.derivedData/SourcePackages/artifacts/sparkle/Sparkle/bin \
  --previous-build 26
```

The normal DMG script removes `dmg-stage` after packaging; preserve a signed copy in a separate dist directory before that cleanup, or mount the verified final DMG read-only and pass its app path. The script produces `CarrotType-0.6.1-27.zip` and signed `appcast.xml`, rejects prerelease versions, mismatched identities/keys or disabled signature settings, and refuses existing outputs. It signs and verifies both assets without publishing anything. SPM tools/pin must match the app's Sparkle version; CI signing remains deferred until secret custody is designed.

### Publish only after the user's approval

Create a draft release for the matching tag. Upload DMG and signed ZIP first, then the signed appcast. Download draft assets via authenticated GitHub API and compare hashes/signatures/length/version/URLs to the local prepared assets. Confirm release is neither prerelease nor an unintended older build; publish as stable/latest only after these checks. Draft/prerelease feeds must never become stable. Use `python3 macos/scripts/verify-update-release.py --tag v0.6.1 --previous-build 26 --sparkle-bin macos/.derivedData/SourcePackages/artifacts/sparkle/Sparkle/bin` as the read-only draft gate. After publication repeat with `--published` to verify the client-facing stable endpoint and public archive through HTTPS redirects. GitHub's latest-release asset endpoint keeps feed and archives within the same release; keep published assets immutable. A failed/missing feed leaves the installed app usable and manual DMG installation available. Never overwrite a signed archive or edit signed XML; regenerate and sign again before publication.

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

## Structured release notes — 0.6.1

Before building, update `macos/CarrotType/Resources/ReleaseNotes.json` alongside version/build. Required English fallback; RU translation; summary and nonempty New/Improved/Fixed sections; optional detail per item. Empty sections are omitted and counts derived. Validate/preview without publishing:

```bash
bash scripts/verify-release-notes.sh
python3 macos/scripts/release_notes.py macos/CarrotType/Resources/ReleaseNotes.json --output-dir dist/notes-preview
```

The preview produces RU/EN HTML and Markdown. Use generated Markdown as the content portion of GitHub notes, adding installation/checksum evidence without rewriting feature bullets separately. What’s New reads the same source from the bundle offline. A missing translation falls back to English; invalid or version-mismatched bundled notes degrade safely at runtime but are rejected for release packaging.

Prepare production archives from the final signed app **without `--notes`**; the script reads its bundled resource and embeds escaped localized inline HTML into the signed appcast. Production `--notes` is now rejected; the legacy plain-text path remains only for explicitly isolated staging. No extra HTML asset/hosting, network sink, JS or external CSS/fonts/images. Do not re-sign or edit published 0.6.0 assets. Ed25519 and install/termination gates are unchanged; full native Sparkle appearance must still be checked manually.

The staging harness now derives A/B builds from its input (26/27 for this candidate), uses a unique `update-test.<run-id>` identity and separate negative-scenario identities. Profile/preferences and installer-resume caches no longer collide with prior manual tests or production. `staging-identity.txt` records the run ID. Test bundles have matching fixture note builds; they share candidate code and are not a claim of testing separately compiled historical versions. Use a fresh output directory/loopback port, close the server after manual review, and never upload these feeds/assets. Final 0.6.1 test artifacts/checklist: `docs/debug-review-v0.6.1.md`. Production release/DMG were published after this version’s explicit Debug acceptance on 2026-11-10.

## v0.6.1 publication verification

2026-11-10: user accepted Debug (27) and explicitly authorized publication. Fresh clean Release arm64, SHA-verified 0.6.0 installer template with preserved layout/background, strict component signatures, localized notes/purpose metadata, helper path jail, MLX shaders, Ultra catalog and no bundled weights verified. ZIP and RU/EN inline appcast signed/verified; source data matched Release bundle and archive. Downloaded draft/public assets passed signatures/length/identity/URL checks, draft digests matched local files, anonymous stable feed/archive matched after stable/latest publication. Native Sparkle probe using isolated build-26 host metadata/key found the update; no user installation was launched/replaced. No key export. Source/tag 7207548, PR #23; artifacts: `docs/github-release-notes-v0.6.1.md`, acceptance/limits: `docs/debug-review-v0.6.1.md`.

## v0.6.2 publication verification

2026-11-10: maintainer authorized publication after signed Debug (28) delivery and focused lifecycle checklist. Fresh clean Release arm64; checksum-verified 0.6.1 DMG filesystem template with unchanged layout/background; strict app/components, helper path-jail rejection, bundled notes, MLX shaders and no bundled weights verified. Signed ZIP/feed verified locally, downloaded draft bytes matched, then published stable/latest. Downloaded public signatures/length/identity/URLs and anonymous latest feed/archive matched; isolated build-27 native Sparkle probe found the update without installation. No private key export or user app/data replacement. Tag/source `14dacf3`, PR #24; hashes/evidence in `docs/github-release-notes-v0.6.2.md`, `docs/debug-review-v0.6.2.md`. Hosted app regressions passed; CI compilation is in progress. Private AIDOS checkout initially failed; CI-only follow-up explicitly skips hosted governance without read-only tooling access, while local governance passed. Independent TCC/GUI/network limits remain.

## 0.7.0 published — 2026-11-10

Maintainer accepted Debug UI and explicitly selected the original carrot-microphone A from the second comparison, then authorized publication: «оставляем изначальный / согласен / публикуй тогда версию». Stable/latest **0.7.0 (29)** published from tag/source `v0.7.0` / `2bb5555`, PR #25. Final signed Debug and fresh clean Release/DMG pass; signed ZIP/feed and downloaded draft/public assets pass signatures, metadata, lengths, URLs and exact local byte hashes. Anonymous stable feed/archive match. Native Sparkle probe using isolated build-28 host found the live update without installation. Isolated candidate-code A28→B29 installer and negative scenarios passed; not independent historical-binary/TCC proof. Final-source hosted app CI passed (runs `42828743848` and `42828835461`); private hosted AIDOS explicitly skipped, local validate/trace/review passed. No user installation/data replacement, key export, new engine/dependency/trust or feature removal. Full independent device/VoiceOver/TCC/network checks remain unverified. Artifact hashes: `docs/github-release-notes-v0.7.0.md`; acceptance/limits: `docs/debug-review-v0.7.0.md`. Next: collect feedback; no further implementation stage selected. Later releases retain their own Debug/manual/publication gate.

For 0.7.0 the verified 0.6.2 DMG filesystem template was reused; `.DS_Store`/Applications alias geometry retained. The installer accent background intentionally changed: write new TIFF bytes **in place** into the existing background file so the Finder alias inode remains valid. New background SHA-256 and unchanged layout hash are in the Debug/release evidence. Do not overwrite or re-sign published assets.


## 0.8.0 published — 2026-11-11

Maintainer accepted the signed first-sentence Debug and authorized release: «ок, пока остановимся, хорошо получилось, давай релизить». Stable/latest **0.8.0 (30)** published on 2026-11-11 from tag/source `v0.8.0` / `819286a` (application code `0edde77`), PR #27. Known business-tone failures remain disclosed/experimental/off by default; release acceptance is not a semantic quality pass. Fresh clean Release arm64, signed host/helper/Sparkle, mounted DMG/layout/background, no bundled weights and real installed-Gemma Release helper smoke passed. Local governance passed; hosted regressions/Debug/actual native checks passed ([42891053801](https://github.com/kestgalax/carrottype/actions/runs/42891053801), [42891040649](https://github.com/kestgalax/carrottype/actions/runs/42891040649)); private hosted AIDOS explicitly skipped. Signed ZIP/feed and downloaded draft/public artifacts passed digests, signatures, lengths, identity/URLs; anonymous latest feed/archive match. Isolated A29→B30 install and negative cases passed; public native Sparkle probe found 0.8.0 from isolated build-29 metadata without installation. No user app/profile/model replacement or private-key export. Full independent device/TCC/VoiceOver/network and Qwen comparison remain unverified. Hashes: `docs/github-release-notes-v0.8.0.md`. Stop feature iteration per maintainer; collect feedback, no next stage selected; GigaAM stays deferred.


## 0.8.1 published — 2026-11-11

Maintainer accepted the revised signed Debug and instructed «публикуй». Stable/latest **0.8.1 (31)** published on 2026-11-11, tag/source `v0.8.1` / `d8e166b` (application code `fe2e9bc`), PR #28. Opt-in native launch at macOS sign-in lives at the bottom of General without persistent hints. Clean Release arm64, signed host/helper/Sparkle, final mounted DMG/resources/metadata/no weights and ZIP/feed signatures passed. Initial DMG creation returned Resource busy; checksum-verified 0.8.0 filesystem template reused with unchanged layout/background. Local governance and hosted final-app regressions/Debug/native checks passed (42983616038, 42983623123); private hosted AIDOS explicitly skipped. Isolated candidate-code A30→B31 install and negative checks passed, not historical-binary or TCC proof. Downloaded draft/public files matched digests/signatures/length/identity/URLs; anonymous latest feed/archive matched. Native isolated build-30 Sparkle probe found the live update without installation. No user installation/profile/model/login-item replacement or private-key export. Individual actual reboot/system-approval results were not enumerated; independent device/TCC/VoiceOver/network checks remain unverified. Hashes: `docs/github-release-notes-v0.8.1.md`; evidence: `docs/debug-review-v0.8.1.md`. Next: collect startup feedback, no further stage selected; GigaAM remains deferred. Later releases retain their own Debug/manual/publication gate.


## Cumulative release notes — 0.8.2 onward

Before bumping version/build, prepend the previous shipped `ReleaseNotes.json` record to `ReleaseNotesHistory.json` without modifying past notes. History is newest first, contiguous and complete from build 27 (0.6.1) through current build minus one. Then author current notes normally. Both resources are bundled; `prepare-update.py` rejects incomplete/missing history for production build 32 onward. The single-release schema stays unchanged; GitHub Markdown remains current-only.

The signed appcast embeds current + history per locale. Sparkle 2.10.1 annotates the element whose `data-sparkle-version` matches installed CFBundleVersion; template CSS hides that release and older siblings, without author-provided JavaScript or a network service. Unknown markers display available history and its earliest version. Existing 2.10.1 clients support this feature; published feeds/archives remain immutable. Native What's New uses the previously observed installed identity, persists that baseline through read/relaunch, and never fetches history. A first untracked install cannot infer a previous version and shows current notes.

Run `bash scripts/verify-release-notes.sh` and inspect native light/dark localized notes plus installed-build filtering before publishing. Local preview CLI automatically includes adjacent history. Source contract: [Sparkle publishing](https://sparkle-project.org/documentation/publishing/#adapting-release-notes-based-on-currently-installed-version), checked against pinned SUWKWebView.m. Staging copies prune history below their synthetic build; no production app/preferences modified.


## 0.8.2 published — 2026-11-11

Maintainer accepted the signed Debug and instructed «можно опубликовать». Stable/latest **0.8.2 (32)** published on 2026-11-11, tag/source `v0.8.2` / `62082f6` (application code `4f85180`), PR #29. All skipped structured release notes (history since 0.6.1) are grouped by release offline and in signed inline Sparkle HTML, using its native installed-build CSS marker; unknown/incomplete coverage is explicit. Clean Release arm64, inside-out signed host/helper/Sparkle, final read-only mounted DMG/resources/current+history/no weights and signed ZIP/feed passed. Finder layout automation denied (-1743); checksum-verified 0.8.1 installer filesystem reused with unchanged layout/background. Signed archive and both feed locales contain the same six release records; actual native pinned WK on signed-feed HTML filters builds 31/27/26/unknown with content JS disabled. Local governance and hosted final-app regressions/Debug/native checks passed (42995366888, 42995404697); private hosted AIDOS explicitly skipped. Isolated candidate-code A31→B32 install and negative checks passed, not historical-binary or TCC proof. Downloaded draft/public assets match local digests/signatures/length/identity/URLs; anonymous latest feed/archive match. Native isolated build-31 Sparkle probe finds the live update without installation. No user installation/profile/model/login-item edits or private-key export. Temporary indexed packaging copies removed after verification; retained app is noindex. Individual manual results not enumerated; full independent interactive/device/TCC/VoiceOver/network verification remains limited. Hashes: `docs/github-release-notes-v0.8.2.md`; evidence: `docs/debug-review-v0.8.2.md`. Collect feedback; no next stage selected, GigaAM deferred. Later releases retain separate Debug/manual/publication acceptance.


## v0.9.0 publication verification

2026-11-11: accepted Dynamic Island Debug and explicit publication authorization. Clean Release and verified 0.8.2 filesystem-template DMG (Finder -1743 fallback) preserve installer layout/background; signatures/resources/helper/MLX/no weights verified. Signed ZIP/feed and immutable 0.8.2 note archive passed local/draft/public signatures/digests/lengths/identity/URLs. Isolated candidate-code A32→B33 and negative staging passed; native public probe from isolated build32 found the update without installing. PR #30 merged, final-source CI 43052628002 passed. Tag v0.9.0 / d97f6c2; no published asset changes or user app/data replacement/key export. Public verification Python required SSL_CERT_FILE=/etc/ssl/cert.pem because its local default chain was absent; TLS verification stayed enabled. Evidence: docs/debug-review-v0.9.0.md, hashes docs/github-release-notes-v0.9.0.md. Device/TCC/VoiceOver/network limits remain.


## 0.10.0 publication closeout — 2026-11-12 (Moscow)

Maintainer accepted the delivered Debug and explicitly authorized publication: «мне нравится, можем публиковать». Stable/latest **0.10.0 (34)** published at 2026-11-11T21:09:29Z (00:09 Moscow, November 12). Accepted application code `1736262`, metadata `7c1dfdc`, immutable tag/source `v0.10.0` / `3b14844`; final premerge head `99a7bbc` differs from the tag only in documentation. PR #31 merged as `bd387d8`. Final-head hosted macOS checks **43099456972 passed** (5m46s); private hosted AIDOS explicitly skipped, local validate/trace/review passed.

Correction to preparation-era statements: the docs-only `99a7bbc` push automatically created a second CI run; earlier run 43096217758 was superseded. Thus the prior “no duplicate run” statement is incorrect. GitHub Actions major outage delayed scheduling; final-head CI subsequently succeeded. No workflow/runner bypass or unverified CI success was used.

Coordinator independently checked PR/head/tag/application-source freeze and successful final-head CI, reran authenticated draft signature/identity/version/length/URL gate, merged the exact checked head, and published the already verified draft. Post-publication `verify-update-release.py --published` passed public latest/archive signatures, metadata, URLs and asset digests. Native resolved Sparkle CLI with isolated manual-A build33 identity and production public key probed the live HTTPS latest feed: exit0, update available; probe only, no installation (log `dist/public-native-0.10.0.log`). DMG/ZIP/feed hashes remain those recorded above. Self-signed/unnotarized posture, candidate-code fixture and independent device/IME/VoiceOver/TCC limitations remain. No installed app, user preferences/models/login items or private keys were changed/exported.

Next authorized work: settings reorganization (General, Dictation including formatting, Text actions) on a new branch/worktree from updated main, via **OpenCode 2** under the maintainer’s latest instruction «давай тогда через opencode продолжим». Codex retains design/review. Direct ZCode readiness did not work; do not claim it is executing. No publication authorization for that future version is inferred.


## 0.11.1 publication closeout — 2026-11-12 (Moscow)

Maintainer asked to review the locale/quit-install Debug fix and publish if acceptable. Coordinator reviewed and accepted Debug `f0cff02` (evidence `7633120`) on `kestgalax/update-locale-quit-fix-2`, authorized **0.11.1 (36)** because stable was already 0.11.0 (35). Application behavior remained frozen; release metadata `d719170` and release evidence `5bc877b` change only version/build, release notes/history and documentation. Stable/latest **0.11.1 (36)** published 2026-11-12T00:10:38Z; tag `v0.11.1` / `5bc877b`, PR [#33](https://github.com/kestgalax/carrottype/pull/33) merged as `17ab70d`. Hosted `macOS checks` **43124371738 passed** on the checked head `5bc877b`; private hosted AIDOS was explicitly skipped, no hosted governance success claimed.

Clean arm64 Release build; Finder layout again returned `-1743`, so the checksum-verified published 0.11.0 DMG (`f231d29d…`, 23,830,560 bytes) was reused as the installer filesystem template with unchanged `.DS_Store`/background/layout/Applications link. Final DMG `hdiutil verify` VALID; mounted app 0.11.1 (36), deep-strict valid, helper/MLX present, no weights. Signed ZIP/appcast and downloaded draft/public assets passed signatures, identity, version, lengths, URLs and digests. Isolated candidate-code A35→B36 install and negative scenarios passed; native public probe (isolated build-35 identity, production key) found the update without installing. Draft gate `/tmp/verify-draft-0111.log`, public gate `/tmp/verify-published-0111.log`, probe `dist/public-native-0.11.1.log`. Published assets are immutable. Self-signed/unnotarized posture and independent device/IME/VoiceOver/TCC/network limits remain; no installed app, user preferences/models/login items or private keys were changed or exported. Next: collect feedback on update-language and install-on-quit behavior; no further stage selected.
