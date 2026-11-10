# Debug 0.6.0 (26): проверка перед публикацией

Статус 2026-11-10: пользователь принял Debug 0.6.0 (26): «Все отлично, можно публиковать». Собственное подтверждение этой версии получено; готовится Release. Ветка `feat/setup-and-settings-polish` от main после v0.5.0. Отдельные результаты ручного чеклиста пользователь не перечислял; ограничения автоматической проверки ниже сохранены.

## Что изменилось

- Welcome/Setup: общий прогресс микрофон → Accessibility → Ultra → проба. Ready по-прежнему означает разрешения + установленную Ultra; закрытие welcome не делает приложение готовым. Установленная модель переиспользуется, загрузка только по действию пользователя.
- Пробная диктовка: явные кнопки начала/завершения/отмены; финальный текст в поле Setup. Нет автоматической вставки во внешнее приложение, изменений clipboard, Last Dictation или счётчиков. В память настроек сохраняется только Boolean завершённой пробы, текст остаётся в RAM до выхода. Повторная отменённая проба не сбрасывает прежнюю успешную.
- General: сворачиваемые действия с горячей клавишей, языковой парой и моделью. Все прежние редакторы остаются внутри; новые действия раскрываются. Недоступная сохранённая модель видна, fallback объясняется; кнопка Models ведёт в Models. Пустой список больше не восстанавливает действие по умолчанию после перезапуска.
- Назначение hotkey временно снимает глобальные сочетания приложения, чтобы конфликтующий chord попадал в редактор и не запускал диктовку; старые назначения восстанавливаются при отмене/конфликте. При закрытии редактора захват завершается.
- Реальное форматирование: Off/Light/Smart/Smart+/Gemma возвращают фактический режим. При отсутствии/ошибке MLX остаётся Light и Capsule сообщает «Применено базовое форматирование»; Details хранит итог последней обычной диктовки без сырых ошибок helper. Проба показывает свой итог рядом с полем.

## Обычный Debug — проверка со своими моделями

`dist/CarrotType-0.6.0-Debug/CarrotType.app`. Установленный `/Applications/CarrotType.app` не заменялся.

1. Закрой установленную копию и любые другие Debug-копии, затем открой этот Debug. Проверь версию 0.6.0. Он использует твои текущие настройки/модели. При необходимости заново разреши Microphone/Accessibility для этой копии; подпись локальная, не Developer ID.
2. Открой Setup. Если все требования уже выполнены — сразу доступна проба, без новой загрузки Ultra. Запомни clipboard, счётчики Statistics и результат Copy Last Dictation (можно сначала сделать одну обычную диктовку). Начни пробу, скажи короткую фразу, нажми «Завершить запись». Результат только в поле Setup, clipboard/статистика/последняя обычная диктовка не меняются. Проба работает кнопками и при включённом hold-to-talk.
3. Проверь Escape/Cancel во время записи, отмену во время обработки, уход в другой раздел/закрытие окна при пробе. Нет внешней вставки; запись и Wave Link mute восстанавливаются. После завершения отмены доступна следующая проба. При переходе к уже идущей обработке отмена ждёт её безопасного завершения/отмены, результат отбрасывается. Перезапусти приложение: Boolean успешной пробы сохранён, её текст исчез.
4. Проверь обычную диктовку RU/EN, toggle/hold-to-talk, Escape/live draft, clipboard retain/Copy Last Dictation, привычные Smart/Gemma, Translate/Custom, микрофон/meter/Wave Link и статистику. Проба не меняет их настройки. Details показывает фактически применённое форматирование; успешный обычный paste учитывается один раз.
5. General: раскрой действие, поменяй язык/тип/инструкцию/model/hotkey, сверни/раскрой. Конфликт chord показывает сообщение и сохраняет прежнее назначение; захват не запускает диктовку. Проверь RU/EN и узкое окно 720×520. Смена языка не должна выключать работающий meter.
6. Сравни Details для обычных Off/Light и привычного Smart/Gemma: там должен быть фактический применённый режим. Пути missing helper/timeout/generation failure проверены автоматическим harness; визуальное сообщение о fallback при реальном сбое нужно дополнительно подтвердить, если такой сбой возникнет при ручной проверке.

## Чистый интерфейс без сброса своих настроек

`dist/CarrotType-0.6.0-UI-Review/CarrotType.app` — отдельный Debug bundle ID `app.carrottype.macos.setup-test`, свои preferences и Application Support `carrottype-setup-test`. Ultra/cleanup туда не копировались; глобальные hotkeys намеренно отключены. Для настоящего hotkey → paste и проверки Smart/Gemma используй обычный Debug выше; UI-копия предназначена для чистых экранов и списка действий, скачивать в неё cleanup-пакеты ради UI-проверки не требуется.

- Welcome открывается на первом запуске. Continue ведёт в Setup; до разрешений/Ultra статус не Ready. Можно прервать настройку и продолжить после перезапуска. Проверить denied permission и download/cancel/retry можно здесь, не удаляя рабочие модели основного профиля. Микрофон включается только по явному действию; для пробы потребуется разрешение и отдельная Ultra.
- В этом профиле безопасно сделать 0–5 действий, раскрывать редакторы, выбрать Custom с пустой инструкцией, проверить ограничения добавления/конфликты и ссылку Models при отсутствии cleanup. После удаления всех тестовых действий перезапуск оставляет список пустым. Не удаляй реальные рабочие bindings ради теста.
- При проверке русской/английской локализации и минимального размера окна проверь читаемость шага, кнопок и выбранной недоступной модели. Собственные модели/статистика основной установки остаются на месте.

## Автоматическая проверка и ограничения

- Debug arm64 `BUILD SUCCEEDED`; отдельные доставочные copies подписаны `CarrotType Development`, deep/strict verification. Известные Xcode CoreDevice/iOS Simulator warnings не мешают macOS build.
- `verify-setup-formatting.sh`: production прогресс/порядок шагов при частичной настройке/отозванном праве; Off/Light/успешные MLX modes; missing model/helper, timeout/generation fallback; cancellation; раздельная доставка без вызова caret/stats/clipboard closure для trial; реальный resolver, roundtrip 0–5 bindings и конфликтующие hotkeys без глобальной регистрации.
- `verify-dictation-reliability.sh`, `verify-ultra-models.sh`, `verify-app-updates.sh`, streaming catalog flags — passed. Governance validate/trace/review и diff/new-file checks — passed.
- Изолированная UI-копия запущена; native window list подтвердил Settings 880×680. Чтение accessibility tree/screenshots через Orca вернуло `permission_denied`, хотя inventory дважды сообщает `granted`. Полная визуальная проверка не выполнена; обход разрешений не применялся. Тестовая копия закрыта, установленная продолжила работать. Автоматическое подтверждение Microphone/Accessibility не выполнялось, микрофон не включался.
- До пользовательского подтверждения оставались ручные проверки реального microphone → STT → trial/normal paste, meter/RU/EN/minimum window и teardown. Ошибки helper в новых тестах управляются fake engine, старый transport/protocol harness проверяет настоящие subprocess failures; это не полный запуск MLX на всех моделях.
- Пользовательское подтверждение Debug и разрешение публикации получены 2026-11-10. Release packaging и проверка подписанных production assets выполняются отдельно. Полный lifecycle refactor и расширенный network audit остаются отдельно.

## Release preparation — 2026-11-10

User accepted Debug and authorized publication. Clean Release arm64 build succeeded in fresh temporary DerivedData. DMG integrity, preserved layout/background, deep/strict app/component signatures, helper path jail, MLX shaders, Ultra catalog and RU/EN microphone-purpose resources passed. Production ZIP and appcast were signed/verified with the existing Keychain key, without export. Artifact hashes are in `github-release-notes-v0.6.0.md`; remote draft/public checks follow before release closeout.
