# CarrotType 0.12.0

2026-11-16

Микрофоны теперь собраны в список приоритета: диктовка переходит на следующий рабочий микрофон,
когда интерфейс отключён, и возвращается к нему после подключения.

> Статус: **релиз 0.12.0 (37)**. Release-сборка arm64, DMG и подписанные ZIP/appcast собраны из
> ветки `feat/smart-mic-priority`; ассеты проходят проверку черновика перед публикацией в
> stable/latest. SHA-256 DMG/ZIP/appcast записаны ниже. Motion companion не входит в выпуск.

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

N/A — maintainer отказался от motion companion для 0.12.0 («без демо»).
Формат/гейт: `ops/release-motion.md` (waiver).


## История изменений

Опубликованные заметки 0.11.1 перенесены в неизменяемую `ReleaseNotesHistory.json` без изменения
прежней записи. Полная структурированная история начинается с 0.6.1 и теперь непрерывна от сборки
36 до 27; «Что нового» и подписанный inline-фид показывают пропущенные версии офлайн. Неполная
история обозначается явно.

## Проверка выпуска

Ветка `feat/smart-mic-priority` от опубликованной `main` (`027dd52`, 0.11.1). Версия/сборка
**0.12.0 (37)**, `ReleaseNotes.json`/`ReleaseNotesHistory.json`, project metadata, заметки и
документация меняются; поведение приложения принято maintainer’ом («отлично, теперь все работает»).

Локальные проверки: `scripts/verify-smart-mic-priority.sh` (нормализация, миграция, упорядоченное
переключение, сохранение недоступных записей, promote, bounded move, round-trip defaults,
Wave Link usability) и `scripts/verify-release-notes.sh` (непрерывная история 37→27, RU/EN и
безопасный рендер) — PASS. Чистая arm64 Release-сборка; Finder layout вернул `-1743`, поэтому
использован checksum-verified DMG-шаблон 0.11.1 (`11de7b60…`, 23 830 560 байт) с сохранёнными
`.DS_Store`, background, layout и Applications-ссылкой. Финальный DMG прошёл `hdiutil verify`,
mounted app/helper/MLX/identity проверены, весов моделей нет. ZIP и appcast подписаны и проверены
`prepare-update.py --previous-build 36`.

Не входит в этот выпуск: новые движки/модели, сетевые адресаты, нотаризация, GigaAM. ADR не
требуется: граф захвата, поведение системного устройства ввода по умолчанию и модель
распространения не меняются (ADR-007 не затронут).

## SHA-256

| Файл | Байт | SHA-256 |
|---|---:|---|
| `CarrotType-0.12.0.dmg` | 23861036 | `f943164101df9045e4e9646dd67799f38e21b0bdf35e5e18d16d0d88970f4497` |
| `CarrotType-0.12.0-37.zip` | 23942520 | `28424c9acfbcb16a13914427cf89a2c4aefb82f4a74e4518066327ab6559c864` |
| `appcast.xml` | 48636 | `7d6a2570f8615df76939073b26bb39083b09fbda14beebaa7a8cd999b471a026` |

SHA-256 `CarrotType.app/Contents/MacOS/CarrotType`: `74e9d79658a5a56c38777750dfc9ae747441f729be6dea96ff3922467de51a35`.
SHA-256 helper `CarrotType.app/Contents/MacOS/CarrotTypeCleanupHelper`: `3d06fa96e3ba42f959569757464c24e5ae47839a74be6c9f94794f55b5b04944`.
CDHash приложения: `33dd3d7f0d503073b9f94d62a9ed39561bf57bf2`.

---

# CarrotType 0.12.0 (English)

2026-11-16

Microphones now form an ordered priority list: dictation fails over to the next usable mic when your
interface is unplugged and returns to it when it reconnects.

> Status: **release 0.12.0 (37)**. The arm64 Release build, DMG and signed ZIP/appcast are built
> from `feat/smart-mic-priority`; the assets pass the draft gate before stable/latest publication.
> DMG/ZIP/appcast SHA-256 values are recorded above. The motion companion is not part of this
> release.

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

N/A — maintainer waived the motion companion for 0.12.0 (“без демо”).
Format/gate: `ops/release-motion.md` (waiver).


## Release verification

Branch `feat/smart-mic-priority` from published `main` (`027dd52`, 0.11.1). Version/build
**0.12.0 (37)**, `ReleaseNotes.json`/`ReleaseNotesHistory.json`, project metadata, notes and
documentation change; the application behavior was accepted by the maintainer («отлично, теперь
все работает»).

Local checks: `scripts/verify-smart-mic-priority.sh` (normalization, migration, ordered failover,
retention, promote, bounded move, defaults round-trip, Wave Link usability) and
`scripts/verify-release-notes.sh` (contiguous history 37→27, RU/EN, safe rendering) — PASS. Clean
arm64 Release build; Finder layout returned `-1743`, so the checksum-verified 0.11.1 DMG
(`11de7b60…`, 23,830,560 bytes) was reused as the installer filesystem template with unchanged
`.DS_Store`, background, layout and Applications link. The final DMG passed `hdiutil verify`, the
mounted app/helper/MLX/identity checks, and contains no model weights. The ZIP and appcast are
signed and verified by `prepare-update.py --previous-build 36`.

Not part of this release: new engines/models, network sinks, notarization, GigaAM. No ADR is
required: the capture graph, system default input behavior and distribution trust model are
unchanged (ADR-007 unaffected).
