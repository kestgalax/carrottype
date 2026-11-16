# CarrotType 0.12.0

2026-11-16

Микрофоны теперь собраны в список приоритета: диктовка переходит на следующий рабочий микрофон,
когда интерфейс отключён, и возвращается к нему после подключения.

> Статус: **черновик подготовки выпуска**. Версия 0.12.0 (37) собрана в ветке
> `feat/smart-mic-priority`; публикация в stable/latest не выполнена. SHA-256 и ссылка на демо
> заполняются после сборки DMG и загрузки ассетов.

## Новое

- **Приоритет микрофонов с автоматическим переключением.** Каждый микрофон, добавленный в
  список, остаётся в нём на своём месте. Диктовка использует первую **рабочую** запись, поэтому
  отключённый USB-интерфейс или гарнитура сохраняют место и снова становятся активными после
  подключения. Выбор микрофона в меню перемещает устройство в начало списка, а не перезаписывает
  единственное сохранённое значение. Прежний одиночный выбор один раз переносится в список из
  одной записи; `carrottype.selectedAudioInputID` по-прежнему хранит фактически выбранный микрофон.
- **Компактная строка микрофона и окно приоритета.** В «Диктовке» и «Настройке» виден только
  активный микрофон и кнопка **«Настроить…»**; полный упорядоченный список открывается в нативном
  окне настроек, где строки перетаскиваются в нужном порядке (нативный `List` + `onMove`, без
  отдельного режима редактирования). Для каждой строки показано, активна ли она, является ли
  устройством по умолчанию или недоступна; изменения применяются сразу, без отдельного сохранения.
  В «Настройке» остаются разрешения, необязательный индикатор и экспериментальное снятие mute
  (ADR-007).

## Улучшено

- **При первом запуске выбирается микрофон, который действительно пишет.** Если приоритет ещё не
  сохранён, первой записью становится встроенный микрофон, а не виртуальное устройство или
  микрофон Continuity, поэтому первая диктовка не уходит в тишину. Виртуальные микширования
  Wave Link считаются рабочими только при подключённом физическом оборудовании Wave, а
  отключённые записи сохраняют запомненные названия.
- **Настройки сохраняют фокус после запроса доступа к микрофону.** Пока настройки открыты,
  CarrotType временно входит в обычный цикл активации приложений (LSUIElement → regular), поэтому
  системное окно доступа к микрофону возвращает фокус окну приложения, а не оставляет его позади
  других программ. После закрытия настроек приложение снова работает только в строке меню.
- **Смена микрофона не прерывает диктовку.** Подключение и отключение устройств пересчитывает
  активный микрофон только когда CarrotType не занят. Диктовка или пробная запись используют
  устройство, зафиксированное при старте, для записи, живого черновика, индикатора и снятия mute
  Wave Link, а новый приоритет применяется со следующей сессии.
- **Список устройств читается из Core Audio.** Учитываются тип транспорта (встроенный, USB,
  Bluetooth, виртуальный, aggregate), производитель и наличие входных каналов, поэтому скрытые и
  служебные устройства больше не выглядят как рабочие микрофоны.

## Установка

Обновитесь через «Проверить обновления» в CarrotType или скачайте DMG и перенесите приложение в
«Программы». Модели, настройки, статистика, разрешения, привязки преобразований и выбранный режим
Dynamic Island сохраняются. Приоритет микрофонов хранится локально; ничего не отправляется в сеть.
Отключённые микрофоны остаются в списке — это ожидаемое поведение, автоматического удаления
записей нет.

Сборка подписана CarrotType Development, но не Developer ID и не нотаризована. При первом
скачивании macOS может потребовать: Системные настройки → Конфиденциальность и безопасность →
«Всё равно открыть».

## Демо

Короткий беззвучный ролик (H.264, 1920×1080, 30 fps) о приоритете микрофонов и окне с
перетаскиванием: `CarrotType-0.12.0-mic-priority-demo.mp4`.

- Ссылка: **TBD — добавляется после загрузки ассета в GitHub Release.**
- Формат и гейт: `ops/release-motion.md`; бриф `motion/briefs/mic-priority.md`.
- SHA-256 ролика добавляется в таблицу ниже после загрузки.

## История изменений

Опубликованные заметки 0.11.1 перенесены в неизменяемую `ReleaseNotesHistory.json` без изменения
прежней записи. Полная структурированная история начинается с 0.6.1 и теперь непрерывна от сборки
36 до 27; «Что нового» и подписанный inline-фид показывают пропущенные версии офлайн. Неполная
история обозначается явно.

## Проверка выпуска

Ветка `feat/smart-mic-priority` от опубликованной `main` (`027dd52`, 0.11.1). Это подготовка
релиза: версия/сборка **0.12.0 (37)**, `ReleaseNotes.json`/`ReleaseNotesHistory.json`, project
metadata, заметки и документация меняются; приложение уже принято maintainer’ом по поведению
(«отлично, теперь все работает»). Публикация в stable/latest — отдельный гейт координатора.

Локальные проверки: `scripts/verify-smart-mic-priority.sh` (нормализация, миграция, упорядоченное
переключение, сохранение недоступных записей, promote, bounded move, round-trip defaults,
Wave Link usability) и `scripts/verify-release-notes.sh` (непрерывная история 37→27, RU/EN и
безопасный рендер) — PASS. Debug arm64 сборка — см. отчёт подготовки.

Не входит в этот выпуск: новые движки/модели, сетевые адресаты, нотаризация, GigaAM. ADR не
требуется: граф захвата, поведение системного устройства ввода по умолчанию и модель
распространения не меняются (ADR-007 не затронут).

## SHA-256

Заполняется после сборки Release DMG и загрузки ассетов черновика.

| Файл | Байт | SHA-256 |
|---|---:|---|
| `CarrotType-0.12.0.dmg` | TBD | TBD |
| `CarrotType-0.12.0-37.zip` | TBD | TBD |
| `appcast.xml` | TBD | TBD |
| `CarrotType-0.12.0-mic-priority-demo.mp4` | TBD | TBD |

---

# CarrotType 0.12.0 (English)

2026-11-16

Microphones now form an ordered priority list: dictation fails over to the next usable mic when your
interface is unplugged and returns to it when it reconnects.

> Status: **release preparation draft**. Version 0.12.0 (37) is prepared on
> `feat/smart-mic-priority`; nothing is published to stable/latest. Hashes and the demo link are
> filled in after the DMG and release assets exist.

## New

- **Ordered microphone priority with automatic failover.** Every microphone you keep in the list
  stays there in order. Dictation uses the first **usable** entry, so a disconnected USB interface or
  headset keeps its place and becomes active again when it reconnects. The menu microphone picker
  moves the chosen device to the front instead of overwriting a single saved value. An existing
  single-microphone choice migrates once into a one-entry list, and
  `carrottype.selectedAudioInputID` still stores the resolved microphone.
- **A compact microphone row and a priority sheet.** Dictation and Setup show only the active
  microphone plus **Configure…**; the full ordered list opens in a native Settings sheet where rows
  are dragged into a new order (native `List` + `onMove`, no separate edit mode). Each row shows
  whether the device is active, the system default or unavailable, and edits apply immediately
  without a separate Save. Setup keeps permissions, the optional meter and the experimental unmute
  switch (ADR-007).

## Improved

- **First run chooses a microphone that actually captures.** When no priority is saved yet, the
  first entry is seeded with the built-in microphone instead of a virtual or Continuity device, so
  the first dictation is not routed to a silent input. Wave Link virtual mixes count as usable only
  while physical Wave hardware is present, and disconnected entries keep their remembered names.
- **Settings keeps focus after a microphone permission prompt.** While Settings is open, CarrotType
  temporarily joins the normal app activation cycle (LSUIElement → regular), so the microphone
  permission sheet returns focus to the window instead of leaving it behind other apps. The app
  returns to menu-bar-only activation when Settings closes.
- **A microphone change never interrupts dictation.** Plugging or unplugging a device re-resolves
  the active microphone only while CarrotType is idle. A dictation or setup trial keeps the device
  captured at start for the recorder, live draft, meter and Wave Link unmute, and the new preference
  applies from the next session.
- **Devices are enumerated through Core Audio.** Transport type (built-in, USB, Bluetooth, virtual,
  aggregate), manufacturer and input channels are considered, so hidden and utility devices no
  longer look like usable microphones.

## Install

Update from Check for updates inside CarrotType, or download the DMG and move the app to
Applications. Models, settings, statistics, permissions, text-action bindings and the selected
Dynamic Island mode are preserved. The microphone priority list stays local; nothing is uploaded.
Disconnected microphones remain in the list by design — entries are never pruned automatically.

The build is signed with CarrotType Development, not Developer ID, and is not notarized. On first
launch macOS may ask you to open it from System Settings → Privacy & Security → Open Anyway.

## Demo

Short silent clip (H.264, 1920×1080, 30 fps) covering microphone priority and the drag-reorder
sheet: `CarrotType-0.12.0-mic-priority-demo.mp4`.

- Link: **TBD — added after the asset is uploaded to the GitHub Release.**
- Format/gate: `ops/release-motion.md`; brief `motion/briefs/mic-priority.md`.
- Clip SHA-256 is added to the table after upload.

## Release verification

Branch `feat/smart-mic-priority` from published `main` (`027dd52`, 0.11.1). This is release
preparation: version/build **0.12.0 (37)**, `ReleaseNotes.json`/`ReleaseNotesHistory.json`, project
metadata, notes and documentation change; the application behavior was already accepted by the
maintainer («отлично, теперь все работает»). Publication to stable/latest is a separate coordinator
gate.

Local checks: `scripts/verify-smart-mic-priority.sh` (normalization, migration, ordered failover,
retention, promote, bounded move, defaults round-trip, Wave Link usability) and
`scripts/verify-release-notes.sh` (contiguous history 37→27, RU/EN, safe rendering) — PASS. Debug
arm64 build is recorded in the preparation report.

Not part of this release: new engines/models, network sinks, notarization, GigaAM. No ADR is
required: the capture graph, system default input behavior and distribution trust model are
unchanged (ADR-007 unaffected).
