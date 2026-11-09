# CarrotType v0.5.0 — signed in-app updates

Version **0.5.0 (25)**, macOS 14+, Apple Silicon. Self-signed; not Developer ID signed or notarized.

- Check for updates directly from the menu, Status Details or General settings using the native Sparkle UI.
- Optional automatic checks and background downloads/install-on-quit, both off by default. Updates require valid feed and archive signatures; no profiling, audio, text or statistics upload.
- Installation waits for active dictation, transcription, formatting, transforms, paste and mute restoration. Background downloading does not block dictation or force a restart.
- Models, settings and local statistics remain outside the replaced app. Dictation, live draft, formatting, transforms and microphone controls remain available.

## Install / update

1. Quit CarrotType, including Debug and isolated test copies.
2. Open `CarrotType-0.5.0.dmg` and drag CarrotType to Applications, replacing the previous app. This first updater-enabled version is installed manually; future versions can use the in-app updater.
3. If Gatekeeper blocks launch, attempt to open it in Finder, then choose **System Settings → Privacy & Security → Open Anyway** and confirm. Current builds are not notarized.
4. Recheck Microphone and Accessibility if macOS requests them; remove/re-add the app in Accessibility if its status is stuck. Installed Ultra, formatting models, settings, bindings and statistics remain. Last dictation recovery is still RAM-only and ends at exit.

Automatic checks and downloads can be enabled independently in General → App Updates. With models installed, dictation remains local and independent of update availability.

## Verified artifacts

| Asset | Bytes | SHA-256 |
| --- | ---: | --- |
| CarrotType-0.5.0.dmg | 23396088 | `89eefeffc3eecf97614ffc91c2461a907ae2d3603d52980d37a6dfb0a99c863c` |
| CarrotType-0.5.0-25.zip | 23531227 | `9373992a936cb9d3a29f289538b290b005fb56b42a902816cfdb64aae5a31d06` |
| appcast.xml | 2019 | `826ac865fbadfcb1e11c5d1a560335d9149fd4068a2a8dbd9b47164120f3b323` |

## Verification and limits

- Debug arm64 delivered before publication; the maintainer explicitly authorized release on 2026-11-10. Individual native GUI/TCC results were not enumerated; no claim of independently verified permission continuity.
- Clean Release arm64 build, DMG integrity, deep app/component signatures, helper path-jail smoke, MLX shaders, Ultra-only catalog and absence of bundled model weights verified. Installer background/layout were preserved from the checksum-verified 0.4.0 DMG.
- Real isolated Sparkle A → B native installation, no-update case and unavailable/tampered feed/corrupt archive rejection passed. Production install-gate and clipboard/selection/helper/protocol/Ultra migration/storage tests passed.
- Signed archive and feed verified locally; remote draft/public asset verification is part of publication. Ed25519 signatures do not replace Gatekeeper/notarization. Key backup remains maintainer-controlled outside the repository; no private keys are exported or included in assets.
- Full independent network audit remains deferred. Existing paste-acknowledgement, clipboard-copy ambiguity and FluidAudio downloader residuals remain documented.

[Update trust decision](decisions/ADR-017-github-app-updates.md) · [Debug verification record](debug-review-v0.5.0.md)
