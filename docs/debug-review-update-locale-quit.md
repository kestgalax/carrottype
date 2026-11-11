# Debug review — update language and quit-install fix

Date: 2026-11-12
Branch: `kestgalax/update-locale-quit-fix-2`
Base: `origin/main` `7c004cdf7e972a6ed64d2aed5a32096c40dbb36e` (published 0.11.0)
Code commit: `f0cff02` (documentation/metadata commits follow on the same branch)
Spec: [`docs/specs/tasks/update-locale-and-quit-install.md`](specs/tasks/update-locale-and-quit-install.md)
Scope: Debug-only bugfix. No publication, no version bump, no DMG/GitHub release, no user
installation/profile/model/Keychain changes.

## Reported symptoms

1. The changelog/version description stayed English even when the app interface was Russian.
2. “Download updates and install on quit” appeared broken: the toggle could not be enabled.

## Root causes

### 1. Release notes used a different language lookup than the UI

`ReleaseNotes.content(locale:)` was:

```swift
localizations[locale.language.languageCode?.identifier ?? "en"] ?? localizations["en"]
```

`L10n.t` had a second, more defensive rule (`ru*` → `ru`, otherwise `en`, with
`AppLanguage.preferredLanguageCode` as fallback). A locale without a usable identifier therefore
resolved notes to English even when the in-app language was Russian, and the two code paths could
drift.

Fix: one normalizer, `AppLanguageCode` (`Models/LanguageResolution.swift`), is now shared by `L10n`
and `ReleaseNotes.content(locale:preferredLanguageCode:)`. Explicit `ru*` wins; a missing identifier
falls back to the explicit in-app preference; the final fallback remains English. What’s New already
received `AppState.effectiveLocale`; regression checks now cover RU, EN, unknown and missing codes.

### 2. Sparkle selected notes from the process preferred localizations

Sparkle 2.10.1 `SUAppcast.bestNodeInNodes` chooses among the `xml:lang` descriptions with
`[NSBundle preferredLocalizationsFromArray:]`. That reads the app-domain `AppleLanguages` key when
the process starts. It does not know CarrotType’s `AppLanguage` UserDefault. With system English and
in-app Russian, the standard update window stayed English even though the signed appcast contained
both descriptions.

Fix: `AppLanguage.synchronizeUpdaterPresentationLanguage()` mirrors an explicit in-app language into
the app’s own `AppleLanguages` array (`["ru"]` or `["en"]`) and records that CarrotType wrote it.
Selecting **System** removes only a CarrotType-owned override, preserving a user’s manual per-app
language choice. The appcast still carries both RU and EN HTML descriptions; no JS, external
resources, or new network sink. Sparkle’s own labels follow the same key.

Verified mechanism with a standalone app-bundle probe compiled from the production
`LanguageResolution.swift` + `AppLanguage.swift`:

```
-- baseline       preferred: ["en"]
-- set russian    set russian: ["ru"]
-- next process   preferred: ["ru"]
-- set system     set system: ["en-RU", "ru-RU", "ru"]   (CarrotType-owned key removed)
-- next process   preferred: ["en"]
```

Limitation: Foundation caches process preferred localizations, so the Sparkle window follows the new
language on the **next launch**. For someone who selected Russian before installing this fix, the
first launch after the upgrade can still show the previous system choice while the bridge is written;
the following launch is correct. What’s New follows `effectiveLocale` immediately. This is documented
in `docs/architecture.md`; there is no undocumented restart or CLI trick.

### 3. Download toggle was disabled by a Sparkle dependency, not by self-signing

`SPUUpdaterSettings.allowsAutomaticUpdates` is:

```objc
return (_allowsAutomaticUpdatesOption == nil) ? _automaticallyChecksForUpdates
                                              : _allowsAutomaticUpdatesOption.boolValue;
```

CarrotType has `SUEnableAutomaticChecks=false` (ADR-017) and no `SUAllowsAutomaticUpdates` Info.plist
override, so `allowsAutomaticUpdates == false` while automatic checks are off. The Settings toggle
was bound to that property and disabled with no explanation. This is the actual root cause; the
self-signed distribution is not involved.

Fix: keep the dependency and opt-in defaults, but explain it. The disabled toggle now shows
“Turn on automatic checks first: Sparkle downloads an update only during a scheduled check” (RU/EN).
The footer distinguishes manual checks, automatic checks, background download, and install-on-quit.
Manual “Check for updates…” and the standard install/relaunch path are unchanged.

### 4. A busy quit cancelled itself before Sparkle could install

Old delegate order:

```swift
let reply = updates?.shouldTerminate() ?? .terminateNow
guard reply == .terminateNow else { return reply }   // .terminateCancel stopped here
return prepareForQuit?() ?? .terminateNow
```

With a staged install-on-quit and an active dictation/transform, `shouldTerminate()` returned
`.terminateCancel` and showed an alert. `prepareForQuit` never ran, so nothing drained and the quit
did not reach Sparkle’s install-on-quit handoff. The installer also never got a clean termination
opportunity.

Fix:

- `CarrotTypeApplicationDelegate` has exactly one route: `prepareForQuit` (or `.terminateNow` when no
  handler is installed). It never returns `.terminateCancel`.
- `AppState.prepareForQuit` stops intake and drains session/transform/formatting with
  `.terminateLater`, then replies once with the final gate decision.
- `UpdateInstallationGate` tracks `hasPendingInstallOnQuit`; `prepareForTermination` refuses while
  operations are busy (the caller drains), then allows termination. It clears a postponed relaunch
  because a quit is not a relaunch request, and it locks new operations only when an install is
  actually staged.
- `willInstallUpdateOnQuit` keeps returning `false`. This is Sparkle’s documented install-on-quit
  path: the installer tool stays alive and applies the staged update after the process exits.
  Returning `true` and invoking the immediate handler would call
  `installWithToolAndRelaunch:YES`, forcing a relaunch on quit, which ADR-017 explicitly avoids.
  The coordinator’s preference for `true` was not adopted for that reason; the handler is still
  observed through Sparkle’s standard path, and pending state is tracked for status/tests.
- Aborting an update clears the pending state through `resetInstallation`.

## Verification

Build:

```
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
cd macos
xcodebuild -project CarrotType.xcodeproj -scheme CarrotType -configuration Debug \
  -destination 'platform=macOS,arch=arm64' -skipPackagePluginValidation -skipMacroValidation \
  COMPILER_INDEX_STORE_ENABLE=NO -derivedDataPath .derivedData-final build
```

Result: `** BUILD SUCCEEDED **`, arm64.

Automated checks (all passed):

| Command | Result |
| --- | --- |
| `./scripts/verify-release-notes.sh` | PASS: RU/EN/shared language resolution, AppleLanguages bridge ownership, cumulative history, corrupt fallback |
| `./scripts/verify-app-updates.sh` | PASS: gate busy-drain/install-on-quit/abort, single termination route, update asset tests |
| `./scripts/verify-formatting-rules.sh` | PASS |
| `./scripts/verify-setup-formatting.sh` | PASS |
| `./scripts/verify-session-lifecycle.sh` | PASS |
| `./scripts/verify-dynamic-island.sh` | PASS |
| `./scripts/verify-typing-speed-test.sh` | PASS |
| `bash scripts/verify-ultra-models.sh` | PASS |
| `bash scripts/verify-dictation-reliability.sh` | PASS |
| `python3 scripts/verify-settings-organization-app.py --build-log /tmp/update-locale-build.log --products macos/.derivedData-final/Build/Products/Debug` | PASS: 32 pane/language/theme states |
| `python3 scripts/verify-typing-speed-app.py --build-log /tmp/update-locale-build.log --products macos/.derivedData-final/Build/Products/Debug` | PASS: lifecycle/quit/install gate integration |
| `python3 scripts/verify-update-staging.py --app macos/.derivedData-final/Build/Products/Debug/CarrotType.app --output-dir /tmp/update-locale-staging --derived-data macos/.derivedData-final` | PASS: real native A34→B35, offline/tampered-feed/corrupt-archive/no-new-version |

Staging feed inspection: `web/good/appcast.xml` contains both descriptions,
`xml:lang="en"` (11,819 bytes) and `xml:lang="ru"` (12,064 bytes, includes the RU summary). The
native installer rendered the structured release notes during A→B installation.

New/updated checks:

- `scripts/tests/ReleaseNotesChecks.swift` — `ru`, `ru_RU`, `ru-RU`, `en_GB`, unknown and empty
  locales; RU/EN notes; bridge write/remove/ownership.
- `scripts/tests/UpdateInstallationGateChecks.swift` — busy quit defers, then allows install-on-quit;
  ordinary quit does not leave the gate locked; abort clears pending.
- `scripts/tests/ApplicationTerminationChecks.swift` — the delegate always routes through
  `prepareForQuit`, returns the handler’s reply and never invents a cancel.

## Debug artifact

Path:
`dist/.builds.noindex/Update-Locale-Quit-Fix-Debug-2026-11-12/CarrotType.app`

- Bundle: `app.carrottype.macos`; version **0.11.0 (35)**; arm64 Debug.
- Identity: `CarrotType Development` (self-signed development identity; not notarized).
- `codesign --verify --deep --strict`: valid.
- CDHash: `7a21cfe6ba3785ce39782f7ee55d9e7d2482d8e8`
- Executable SHA-256:
  `8ee6ca8276881896ce722595e5683e63be1511c4cc67cfa8dfd03d9c2d19acb5`
- `CarrotType.debug.dylib` SHA-256:
  `19bac9d285557d7607151f1f54893b4e27438b46e0cc562aa925c1f3f5d6ac44`
- Helper SHA-256:
  `781644732b82e7ae1e8e012ffdede84a6019826cb32a5de1eafd555892c2186b`

## Limits / not claimed

- The installed app was not replaced, launched against the user profile, or used for an interactive
  Sparkle alert screenshot. The native staging run used isolated identities and copies.
- The Sparkle-window language bridge is proven with Foundation’s app-bundle selection and the
  production bridge code, but the actual alert was not visually inspected; the next-launch timing is
  a Foundation cache property, not a UI claim.
- The legacy install-on-quit hand-off was validated through the production gate/termination checks
  and Sparkle’s documented `return false` path; a full interactive “enable auto-download → quit →
  relaunch/confirm installed version” walkthrough with a real staged download was not performed
  because it requires launching a user-visible app and waiting for Sparkle’s scheduled check.
- No publication, version bump, DMG, GitHub release, AIDOS change, notarization, model/profile/
  Keychain mutation, or dependency rewrite.
- Individual TCC, VoiceOver, IME and full network-audit results are not enumerated.

## Next gate

Maintainer review of the signed Debug and the two behaviors, then an explicit publication decision.
If approved, a separate metadata/release task can decide whether 0.11.1 (36) is needed for Sparkle
identity; this branch keeps 0.11.0 (35).
