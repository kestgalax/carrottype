# Debug 0.6.1 (27): обновления и «Что нового»

Статус 2026-11-10: N1–N3 реализованы в `feat/update-release-notes-ux` от main с сохранёнными планами 0.6.1/0.6.2/0.7.0. Debug собран и подписан локально. **Пользователь принял Debug 0.6.1 и явно разрешил публикацию: «все ок, публикуем» (2026-11-10)**. Результаты отдельных ручных пунктов не перечислялись; ниже сохранены ограничения автоматической проверки. Готовится чистый Release с проверкой production assets.

## Основная сборка

`dist/CarrotType-0.6.1-Debug/CarrotType.app` — обычный профиль с существующими настройками и моделями. `/Applications/CarrotType.app` не заменялся. Закрой установленную и другие копии перед открытием Debug; при необходимости повторно выдай Microphone/Accessibility этой копии.

1. General → App Updates: видна установленная 0.6.1, «Что нового», прежние автоматическая проверка/скачивание и Check for updates. Открой «Что нового»: версия 0.6.1, дата, резюме, разделы Новое/Улучшено с пунктами; пустой Исправлено скрыт. «Понятно»/Return и Escape закрывают окно. Кнопка остаётся доступной при повторном открытии.
2. Details: «Что нового» рядом с версией открывает тот же список. Проверь RU/EN через General и светлую/тёмную тему macOS; минимальное окно 720×520, прокрутку, выделение текста, Tab/Return/Escape и VoiceOver, если используешь. Нижние действия не должны исчезать при прокрутке.
3. Без сети список установленной версии по-прежнему открывается; его просмотр не запускает проверку/скачивание, не меняет opt-ins и не начинает запись. «Полный журнал» открывает GitHub Releases только по нажатию. После выхода из приложения все прежние настройки сохранены.
4. Проверь привычный hotkey → paste, hold-to-talk/Escape/live draft, пробу в Setup, Smart/Gemma/Translate/Custom, mic meter/Wave Link и статистику в используемых сценариях. Смена языка не должна выключать meter; открытие списка изменений не должно обрывать текущую обработку. Диктовочный runtime и install gate не менялись.
5. В этой Debug 27 проверка production feed с опубликованной 0.6.0 (26) корректно сообщает, что новой версии нет. Красивое описание будущего обновления проверяется отдельным staging ниже, а не изменением существующих public assets.

## Изолированная проверка интерфейса

`dist/CarrotType-0.6.1-UI-Review/CarrotType.app`: Debug identity `app.carrottype.macos.setup-test`, отдельные preferences/models/stats и отключённые глобальные hotkeys. Используй для экранов без риска менять обычные настройки. Если показывается Welcome — Continue, затем General. Для просмотра изменений не нужны разрешения или модели. Не скачивай cleanup-модели ради этого теста. Это существующий тестовый домен; он может сохранить настройки предыдущего UI-review.

## Настоящее окно Sparkle и отметка после замены

Каталог `dist/CarrotType-0.6.1-manual-update/` содержит изолированные **синтетические A 0.6.0 (26) и B 0.6.1 (27)**, подписанные копии текущего Debug-кода. Это проверка native installer/presentation, а не отдельно скомпилированного исторического 0.6.0. ID конкретного теста записан в `staging-identity.txt`; preferences/Application Support отличаются от production и предыдущих тестов. Весов моделей там нет. Проверка сохраняет внешние fixtures, но не доказывает сохранность реальных пользовательских данных/TCC.

1. Закрой другие CarrotType-копии. Открой `start-server.command` из этого каталога (или запусти его через `bash`); оставь локальный сервер 127.0.0.1:39189 работающим.
2. Открой `manual-A/CarrotType.app` оттуда. Welcome → Continue → General при необходимости. Открой «Что нового», закрой. Выполни Check for updates: предложена 0.6.1 вместо 0.6.0, описание разбито на разделы и пункты, морковный акцент, без сплошного абзаца. Проверь обе темы и доступность штатных Skip/Install/Close. Стандартные кнопки и выбор языка описания Sparkle следуют **системному предпочитаемому языку**; override CarrotType действует на наше окно. Для второй системной локализации потребуется отдельный ручной запуск/настройка предпочтений пользователя — она автоматически не менялась.
3. Нажми Install Update и дождись замены/перезапуска. В этой изолированной копии теперь build 27; «Что нового» относится к установленной 0.6.1. У кнопки появилась отметка «Обновлено»; открытие снимает её. После перезапуска она не возвращается, кнопка остаётся. Проверка обновлений сообщает, что новой версии нет.
4. При первой установке нового механизма tracking отметка не появляется: сначала устанавливается спокойная baseline. Она возникает только при **наблюдаемой** смене версии/build; отсутствие отметки при первом переходе с клиента 0.6.0 без tracking ожидаемо.
5. Закрой тестовое приложение и сервер (Ctrl+C в его терминале), затем вернись к обычной копии. Не копируй staging-приложение в /Applications и не используй его для обычной диктовки: это отдельный профиль без моделей. Микрофон/Accessibility и реальную диктовку после обновления проверяй отдельно в основном Debug; автоматического TCC-подтверждения нет.

## Автоматические проверки и ограничения

- Debug arm64 `BUILD SUCCEEDED`. Основная и UI-review копии подписаны `CarrotType Development`; deep/strict signatures, bundle version/build, RU/EN resources и совпадение debug dylib с финальной сборкой проверены. Self-signed, не Developer ID и не notarized.
- `verify-release-notes.sh`: production Swift decoder/store (metadata/date/language fallback, empty sections, first launch/upgrade/same-version new-build/relaunch/read, corrupt resource); production Python schema/escaping/HTML+Markdown/localized appcast metadata. `verify-app-updates.sh`: actual installation gate + trust/feed tests. Все прошли.
- `verify-setup-formatting.sh`, `verify-dictation-reliability.sh` прошли: setup/trial/formatting/delivery/bindings/hotkeys, clipboard/selection/helper/protocol regressions. Новые движки/зависимости/внешние запросы не добавлены.
- Настоящий Sparkle из pinned SPM: unavailable feed, tampered signed feed и corrupt archive отклонены с ожидаемыми кодами; valid feed/HTML accepted, native A → B, no newer version, external fixtures, signatures/helper/metallib проверены. Первоначальный общий staging ID выявил загрязнение resume-state после негативного сценария; harness исправлен на уникальные IDs запуска/сценариев. Production trust/gate не обходились.
- Для layout программно отрисован **сам production SwiftUI view** RU/EN light/dark в отдельном render-host; это offscreen view snapshots, не скриншоты интерактивного Settings/Sparkle и не VoiceOver/TCC acceptance. Полный интерактивный UI smoke остаётся ручным: Orca get-app-state возвращает `permission_denied` при inventory `granted`. Разрешения не обходились, основное приложение не закрывалось/заменялось. Тестовая UI-копия закрыта.
- Полный network audit, native VoiceOver/minimum-window/реальная запись после замены остаются отдельными ручными проверками. Никакого заявления о полной офлайн-сетевой проверке или гарантированной преемственности TCC.

## Источник и выпуск

`macos/CarrotType/Resources/ReleaseNotes.json` → native offline sheet / safe inline HTML signed appcast / generated Markdown. Empty sections omitted, text escaped, external assets/JS absent. Runtime при плохих данных показывает полезный fallback, release packaging отвергает несовпадение metadata. Стандартный Sparkle updater и отсрочка установки сохранены. Принятие этой Debug-версии и разрешение публикации получены 2026-11-10. Release-проверки записываются ниже; 0.6.2 lifecycle и 0.7.0 UI/UX/logo ещё не начаты.

## Release preparation — 2026-11-10

After explicit user Debug acceptance, clean Release arm64 built in fresh temporary DerivedData. Deep/strict component signatures, production identity/notes/build/RU+EN resources, helper path jail, MLX shaders, Ultra catalog/no bundled weights and DMG integrity passed. Installer filesystem/layout/background retained from SHA-verified 0.6.0. Production ZIP/appcast signed and verified; both localized HTML descriptions and archived JSON matched the signed Release bundle. Hashes recorded in `github-release-notes-v0.6.1.md`. Remote draft/public gates follow before release closeout; private key not exported.
