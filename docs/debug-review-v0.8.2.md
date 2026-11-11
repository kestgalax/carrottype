# Debug review — CarrotType 0.8.2 (32)

Status: signed Debug accepted for publication; Release verification in progress, not published yet. Branch `feat/cumulative-release-notes-0.8.2` from main d4136d4. [Task](specs/tasks/cumulative-release-notes.md), ADR-017. Stable 0.8.1 remains unchanged.

App: `dist/.builds.noindex/CarrotType-0.8.2-Debug/CarrotType.app`; direct app, no ZIP required. No automatic installation, quit, real login-item registration or production preference edits. Previous build copies remain untouched.

## Короткая проверка

1. Откройте «Что нового»: после 0.8.1 должен быть только новый патч 0.8.2. Нажмите «Понятно», откройте повторно и перезапустите приложение — диапазон остаётся прежним.
2. При переходе с 0.6.1 должны быть разделы 0.8.2, 0.8.1, 0.8.0, 0.7.0, 0.6.2, без уже установленной 0.6.1. Этот случай проверен изолированными тестами и показан на `dist/.builds.noindex/CarrotType-0.8.2-Native-Review/notes-ru-dark.png`; менять реальные настройки ради теста не нужно.
3. Светлая/тёмная тема, русский/английский и «Полный журнал изменений» доступны как раньше. Публичного обновления 0.8.2 до согласования нет.

## Verification and limits

- Production Swift store/history tests and Python renderer/history/safe-markup tests: `/tmp/ct082-notes.log`. Five missed releases, one-step, persistent read/relaunch, fresh/unknown/downgrade/overflow, corrupt/missing history, incomplete coverage, duplicates/gaps/future/order and localization covered. History records equal original tagged resources, starting build 27; coverage before 0.6.1 not invented.
- arm64 Debug: `/tmp/ct082-debug-build.log`, final `/tmp/ct082-debug-final.log`; signed copy `/tmp/ct082-sign.log`, deep/strict verification. No notarization or identity/trust change.
- Actual AppState/theme/trial/exact-rule/fallback/cancellation regressions: `/tmp/ct082-native-checks.log`, no microphone/models/clipboard registration.
- Actual pinned Sparkle SUWKWebView.m compiled under a renamed fixture class to avoid duplicate runtime class; native content JS disabled, remote references blocked. Installed build 31 displays [32], 27 displays [32,31,30,29,28], 26/unknown displays available [32…27]. `/tmp/ct082-wk-check.log`; actual native snapshot `dist/.builds.noindex/CarrotType-0.8.2-notes/sparkle-ru.png`. Test-only native user script inspects computed display; no script included in authored feed.
- Production native SwiftUI sheet rendered offscreen with isolated defaults, RU/EN/light/dark, 540×560; images in `dist/.builds.noindex/CarrotType-0.8.2-Native-Review`. This checks layout, not interactive keyboard/VoiceOver/window behavior.
- Isolated signed A31→B32 staging plus offline/tampered-feed/corrupt-archive/no-new-version checks passed (`dist/.builds.noindex/updates-0.8.2/results.txt`, `/tmp/ct082-staging.log`). These bundles share candidate code; no claim of separately compiled historical app or TCC verification. Local governance validate/trace/review passed; hosted source CI follows push. No public feed/release/tag or user installation/profile/model/login-item change. First tracking launch/unknown baseline shows current notes; earlier untracked installations cannot be inferred. Existing Sparkle uses system language, native sheet respects app language.


## Publication authorization

After signed Debug delivery and the focused checklist, maintainer instructed «можно опубликовать». This accepts the candidate for 0.8.2 publication; individual manual results were not enumerated. Freeze application code at 4f85180, prepare clean Release/DMG and signed local/draft/public verification. Later versions retain separate acceptance; no user app/profile/login-item replacement authorized or required.


## Release preflight

Clean Release arm64 BUILD SUCCEEDED (`/tmp/ct082-release-build.log`), inside-out signing passed. Finder layout automation denied (-1743); checksum-verified 0.8.1 installer filesystem cloned with only app replaced. Final DMG integrity and read-only mounted metadata/components/current+history/strict signatures/no weights passed (`/tmp/ct082-package.log`, `/tmp/ct082-finalcheck.log`). Layout/background hashes retained from prior installer. Signed ZIP/feed passed; both RU/EN inline descriptions equal rendering of the archive’s full six-release history; archive executable matches mounted DMG. Native pinned Sparkle WK recheck on actual signed-feed HTML passed (`/tmp/ct082-release-wk.log`). No private key export. Hosted app CI 42995366888 and 42995404697 passed; local governance passed, private hosted AIDOS explicitly skipped. Draft/public verification pending. [Hashes/notes](github-release-notes-v0.8.2.md).
