# CarrotType v0.6.0 — setup and settings

Version **0.6.0 (26)**, macOS 14+, Apple Silicon. The maintainer accepted Debug and explicitly authorized publication on 2026-11-10. Self-signed; not Developer ID signed or notarized.

- Four-step setup guidance and an explicit local dictation trial. The result stays in Settings; no automatic external paste, clipboard change or usage count. Only the trial-completion Boolean persists.
- Compact expandable transform bindings with all existing editors, honest unavailable-model/fallback labels and a working Models link. A saved empty list stays empty after relaunch.
- Hotkey capture does not trigger dictation; conflicting assignments preserve the previous configuration.
- Actual formatting outcome in Details and a brief Capsule notice when Smart/Gemma falls back to Light, keeping the transcription and normal paste path.

Parakeet Ultra, live draft, toggle/hold-to-talk, Escape, Wave Link, microphone/meter, formatting modes, Translate/Custom, RU/EN, recovery/clipboard options, local statistics and signed updater remain. No new engine, dependency or network sink. Current distribution remains self-signed/unnotarized.

[Debug manual checklist and verification limits](debug-review-v0.6.0.md).

## Install / update

Use **Check for updates…** in CarrotType 0.5.0 or later, or quit CarrotType, open `CarrotType-0.6.0.dmg` and drag the app to Applications. Quit Debug/test copies before replacement. A Debug copy already at build 26 correctly reports no newer version.

If Gatekeeper blocks the manually downloaded app, attempt to open it in Finder, then use **System Settings → Privacy & Security → Open Anyway** and confirm. Recheck Microphone/Accessibility if macOS requests them. Models, settings, bindings and local statistics retain their existing external storage; RAM-only dictation recovery ends at exit.

## Verified artifacts

| Asset | Bytes | SHA-256 |
| --- | ---: | --- |
| CarrotType-0.6.0.dmg | 23710472 | `93d2b6e543099910d56e5aa0716531cc23b7e7162210b79e13bccd6edccf690a` |
| CarrotType-0.6.0-26.zip | 23586993 | `d86419c0fd26cf8100d5ad48a31752ce0cb404e26d769b3b1e89603e8e7d4ebe` |
| appcast.xml | 2088 | `39a6204272c910393143814de2ce6b9cf6665d812420b5815e4432768f48c069` |

## Verification and limits

- Debug arm64 was delivered first and accepted by the user; individual manual checklist results were not enumerated. Automated native UI observation was permission-blocked; no independent claim of TCC continuity.
- Fresh clean Release arm64 build; deep/strict component signatures; DMG integrity; preserved installer layout/background from checksum-verified 0.5.0; helper path jail, localized microphone descriptions, Ultra-only catalog, MLX shaders and no bundled weights verified.
- Production setup/formatting/delivery/binding/hotkey checks and existing clipboard/selection/helper/protocol, Ultra migration/storage and updater gate regressions passed. Governance validate/trace/review passed. Signed archive/feed verified locally; draft/public remote verification is recorded in the Debug review after publication.
- Existing isolated Sparkle native A → B/signature-negative evidence is from 0.5.0; this release does not change update code. Ed25519 signatures do not replace Gatekeeper/notarization. Full network audit and independent TCC continuity remain deferred; existing FluidAudio downloader and paste acknowledgement residuals remain documented. No private key export.

[Update trust decision](decisions/ADR-017-github-app-updates.md) · [Debug verification record](debug-review-v0.6.0.md)
