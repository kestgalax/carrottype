# CarrotType 0.6.1

2026-11-10

Обновления стали понятнее, а список изменений всегда под рукой\.

## Новое

- «Что нового» — в любой момент\. Изменения установленной версии доступны в General и Details, даже без интернета\.

## Улучшено

- Список изменений, который удобно читать\. Короткие разделы и аккуратная типографика вместо сплошного абзаца в окне обновления\.
- Версия и обновления — рядом\. Настройки автоматической проверки и скачивания сохранены на прежнем месте\.


[Published release](https://github.com/kestgalax/carrottype/releases/tag/v0.6.1). Version **0.6.1 (27)**, macOS 14+, Apple Silicon. Maintainer accepted Debug and explicitly authorized publication on 2026-11-10. Self-signed; not Developer ID signed or notarized.

## Install / update

Use **Check for updates…** in CarrotType 0.5.0 or later. Alternatively quit all copies, open `CarrotType-0.6.1.dmg` and drag CarrotType to Applications. An already-running Debug at build 27 correctly reports no newer version.

If Gatekeeper blocks the manually downloaded app, attempt to open it in Finder, then choose **System Settings → Privacy & Security → Open Anyway** and confirm. Recheck Microphone/Accessibility if macOS requests them. Models, settings, bindings and local statistics keep their external locations; RAM-only dictation recovery ends at exit.

What’s New works offline for the installed version and follows the in-app language. Standard Sparkle labels and available-version notes follow system preferred localization. The first launch of version tracking establishes a quiet baseline; later observed version/build changes show Updated until viewed. No automatic popup or extra background check.

## Verified artifacts

| Asset | Bytes | SHA-256 |
| --- | ---: | --- |
| CarrotType-0.6.1.dmg | 23605585 | `868f6c83fca6bdc3c5efda2b7489f8c97f1811d633fb25cc85c06a3080ae2f63` |
| CarrotType-0.6.1-27.zip | 23639131 | `081a9e00fa81270a4edcdd795b8379f1807dcf079fbb32e6cc571225c9ca12ba` |
| appcast.xml | 6928 | `e81a48b7fb60f0ef5d48c8a161cad721b83d76cd94dea1f2e60315dff15dbb2b` |

## Verification and limits

- Debug arm64 delivered and accepted by the user before publication; individual manual checklist results were not enumerated. Native SwiftUI view rendered for RU/EN/light/dark; independent interactive GUI/TCC/VoiceOver continuity is not claimed.
- Fresh clean Release arm64 build, DMG integrity/layout preservation from checksum-verified 0.6.0 template, deep app/component signatures, bundled notes/locale identity, helper path jail, MLX shaders, Ultra-only catalog and no bundled weights verified.
- Production notes/schema/escaping/tracking and updater gate tests, setup/formatting/bindings/hotkeys and clipboard/selection/helper/protocol regressions passed. Governance validate/trace/review passed. Exact pinned Sparkle native isolated A → B and unavailable/tampered feed/corrupt archive/no-update checks passed with retained external fixtures; staging A/B share candidate code.
- Archive/feed signatures verified locally; RU/EN HTML descriptions and ZIP resource match the bundled source. Downloaded draft/public signatures/identity/length checks passed and all draft digests matched local files. Anonymous stable feed/archive matched verified bytes; native Sparkle using an isolated build-26 host found the published update (discovery only, not a post-release installation/TCC claim). No new engines, dependencies or network sink; standard Sparkle trust/install gates and all existing features preserved.
- Ed25519 does not replace Gatekeeper/notarization. Full network audit and independent permission continuity remain unverified; existing FluidAudio downloader and paste acknowledgement residuals remain documented. Private signing key stays in Keychain; no export.

[Debug acceptance and release evidence](debug-review-v0.6.1.md) · [Update trust](decisions/ADR-017-github-app-updates.md)
