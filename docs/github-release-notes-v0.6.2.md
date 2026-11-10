# CarrotType 0.6.2

2026-11-10

Более надёжные сессии с привычным сценарием диктовки\.

## Улучшено

- Единое управление каждой записью\. Запуск, остановка и отмена завершаются одной очисткой: восстановлением mute и удалением временного аудио\.
- Настройки согласованы на протяжении записи\. Модель, форматирование и микрофон фиксируются при старте\. Изменения применяются к следующей сессии\.

## Исправлено

- Очистка моделей ждёт завершения операции\. Выгрузка предыдущей сессии не прерывает новую\. При занятом конвейере удаление пакетов предлагает повторить попытку позже\.

[Release](https://github.com/kestgalax/carrottype/releases/tag/v0.6.2). Version **0.6.2 (28)**, macOS 14+, Apple Silicon. Maintainer authorized publication after Debug delivery on 2026-11-10. Self-signed; not Developer ID signed or notarized.

## Install / update

Use **Check for updates…** in CarrotType 0.5.0 or later. Alternatively quit all copies, open `CarrotType-0.6.2.dmg` and drag CarrotType to Applications. An already-running Debug at build 28 correctly reports no newer version.

If Gatekeeper blocks the manually downloaded app, attempt to open it in Finder, then choose **System Settings → Privacy & Security → Open Anyway** and confirm. Recheck Microphone/Accessibility if macOS requests them. Models, settings, bindings and local statistics retain their external locations; RAM-only dictation recovery ends at exit.

## Verification and limits

- Signed Debug delivered before explicit publication authorization; individual manual results were not enumerated. Production lifecycle/streaming epoch checks and existing reliability/setup/Ultra/update/notes/catalog regressions passed locally, including targeted mutations in temporary source copies.
- Exact pinned Sparkle native isolated A 27 → B 28, unavailable/tampered feed/corrupt archive/no-update and external fixture/signature/helper/metallib checks passed. Staging A/B share candidate code. No user app/models/settings were replaced.
- GitHub workflow authorization is restored. The first hosted run failed because AIDOS is private; the PR corrects this CI configuration without changing app source. App regressions/build run independently; hosted AIDOS checks require a separate read-only secret and are explicitly skipped without it. Local governance passed. Hosted app verification is in progress.
- Ed25519 does not replace Gatekeeper/notarization. Real cold model/microphone/Wave Link and independent permission continuity/network audit retain the manual limitations documented in the checklist. No new engines, dependencies, network sink or feature removals; private signing key stays in Keychain.

[Debug acceptance and release evidence](debug-review-v0.6.2.md) · [Update trust](decisions/ADR-017-github-app-updates.md)

## Verified local artifacts

| Asset | Bytes | SHA-256 |
| --- | ---: | --- |
| CarrotType-0.6.2.dmg | 23772408 | `3cf92252805f5706ca1ea98bddae4917540200bb3c5c87a90d17831f9bf51431` |
| CarrotType-0.6.2-28.zip | 23658152 | `5520e6e928d27a15446d30055d6a41a1094a04a40caf3850dcca3c31c8cfd592` |
| appcast.xml | 7274 | `f25ec686077eb4ba2ff1fe33a6a773f4d1adf7f3fe47bb3904f95cec9bcb4c2b` |

Fresh clean Release arm64, strict nested code signatures, helper path-jail rejection, bundled notes, MLX shaders and no bundled model weights verified. DMG integrity and unchanged installer layout/background from checksum-verified 0.6.1 template passed. ZIP/feed signatures verified locally. Draft/public verification follows before publication.
