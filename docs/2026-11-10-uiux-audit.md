# CarrotType 0.7.0: предварительный UI/UX-аудит и варианты

D1/D2, ветка `design/uiux-and-brand-0.7` от main `a68123a`. Источники: SwiftUI-код опубликованной 0.6.2, её ресурсы/локализация, просмотр текущего PNG-знака, предоставленные скриншоты CarrotType/OpenBot и подтверждённые ссылки OpenBot/Grok Bot. Материалы: [сравнение направлений](design/0.7.0/directions.html), [исходники/границы](design/0.7.0/README.md), [задача](specs/tasks/uiux-and-brand-refresh.md).

## Граница наблюдения

Попытка получить текущий CarrotType через native GUI automation завершилась timeout/kernel reset. Никаких новых native screenshots, нажатий в рабочих настройках, записи аудио, VoiceOver или полного walkthrough не выполнено. Нельзя объявлять D1 полностью пройденным или считать HTML макет проверкой реального SwiftUI. Ниже **код** означает проверяемую структуру/действие в исходниках; **гипотеза** требует проверки с человеком. Данные и installed app не менялись. Скриншот старого Sparkle из переписки не описывает новый What’s New 0.6.1/0.6.2; этот недостаток уже исправлен, повторно его не считаем находкой.

## Что сохраняем

| Сценарий | Сохраняемое поведение | Где проверено в коде / что требует native проверки |
| --- | --- | --- |
| Первый запуск | Микрофон → Accessibility → Ultra → отдельная пробная диктовка; готовность не зависит от пробного текста | SetupProgressView, SetupSettingsPane; реальный permission flow не пройден |
| Ежедневная запись | Toggle/hold, Escape, запись до cold load, live draft, WAV-final, single teardown | AppState/coordinator, StatusCapsule; реальный ввод/микрофон не проверен |
| Отмена/восстановление | Copy/Close непустого draft, Copy Last Dictation в RAM, отсутствие истории на диске | MenuBarViews/StatusCapsule; focus/VoiceOver не проверены |
| Выделенный текст | Translate/Custom, до 5 bindings, языковые пары, выбор Smart/Gemma, disclosure-редактор | GeneralSettingsPane; keyboard walkthrough не пройден |
| Настройка звука | Выбор входа, meter по явному включению, Wave Link unmute/restore | SetupSettingsPane/MenuBarViews; реальные устройство и mute не трогались |
| Форматирование | Off/Light/Smart/Smart+/Gemma, активные/доступные пакеты, видимый fallback | ModelsSettingsPane/FormattingOutcomeView; не запускался inference |
| Хранилище/статистика | Раздельные installed/cache/legacy, подтверждение legacy/cache, opt-in локальные counts/WPM | StorageSettingsPane/StatisticsSettingsPane; данные не удалялись |
| Обновления | Проверка, отдельные opt-ins, подписанный feed, ожидание операции, What’s New offline | AppUpdateViews/ReleaseNotesView; trust и updater не меняем |
| Среда | RU/EN, системные light/dark, Settings без remount при смене языка, Command-comma | App/Settings/MenuBarViews; native minimum/VoiceOver ещё не проверены |

Сильная сторона продукта: основная работа идёт у курсора, а настройки обслуживают этот сценарий. Пять понятных разделов, отдельные installed/cache, компактные bindings и сохранённый native updater уже полезны. Не нужен новый стартовый dashboard или постоянное окно для диктовки.

## Находки и приоритеты

P1: проверяемые риски доступности/ошибочного действия; P2: удобство и визуальная согласованность. Стоимость относительная, не оценка в днях.

| ID / приоритет / стоимость | Проблема → эффект → предложение | Основание / критерий проверки |
| --- | --- | --- |
| A1 · P1 · малая | Два `Picker("", …).labelsHidden()` у Translate → назначение списка не задано явно → добавить локализованные «Первый язык»/«Второй язык» и проверить VoiceOver | **Код:** GeneralSettingsPane, язык A/B. Фактическое озвучивание не наблюдалось; оба списка должны иметь различимые имена и значения |
| A2 · P1 · малая | Capsule делает `repeatForever` и отдельные анимации без чтения reduce-motion → системная настройка может игнорироваться → использовать `accessibilityReduceMotion`, статичный индикатор при включении | **Код:** StatusCapsule. Запись остаётся различимой текстом/значком, без постоянной пульсации; не менять state machine |
| A3 · P1 · малая | Последние слова live draft: белый с opacity 0.42 на чёрном при 12 pt → расчётный контраст около 3.95:1 → повысить контраст до ≥4.5:1, сохранить различие interim/confirmed | **Код/расчёт**, не измерение pixels: StatusCapsule `liveDraftText`. Проверить native rendering и Increase Contrast; не убирать последние слова |
| A4 · P1 · малая/средняя | Clear stats вызывает очистку сразу, delete installed/bulk идёт без отдельного dialog на этом UI-пути → случайное действие дорого исправлять → предложить подтверждение с именем/объёмом/эффектом | **Код:** StatisticsSettingsPane → AppState.clearUsageStatistics; Models/Storage → AppState maintenance. Legacy/cache уже подтверждаются, их не дублировать. Не трогать данные при аудите |
| A5 · P1 · малая | Sidebar сделан plain-кнопками, выбранность только фон/цвет → экранному диктору состояние явно не передаётся → selected trait/value и видимый keyboard focus | **Код:** CarrotTypeSettingsView.sidebarRow; VoiceOver и Tab/Shift-Tab не проверены. Не заменять navigation автоматически на новый стек |
| U1 · P2 · средняя | Основные содержат hotkey/hold/draft/clipboard, форматирование выбирается в Models → ежедневные настройки разделены → добавить связанный режим форматирования в Основные, сохранив полный Models | **Код + гипотеза:** General/ModelsSettingsPane. Задача: поменять Light/Smart без поиска в пакетах; один источник binding, Ready-only/fallback без изменений |
| U2 · P2 · малая | Заголовок блока «Горячая клавиша» объединяет clipboard/live draft/hold → заголовок уже содержания → назвать группу «Диктовка», оставить подписи и подсказки | **Код:** GeneralSettingsPane/Localizable.xcstrings. RU/EN, быстро найти каждую настройку; никаких переключателей в скрытый advanced |
| U3 · P2 · малая | В sidebar Ready/Almost/Blocked + Details, конкретный следующий шаг есть глубже в Setup → возможен лишний переход → предложить одну краткую actionable подсказку при not ready | **Код + гипотеза:** SettingsStatusHeader/SetupProgressView. Сохранить подробности ошибок и все шаги, не маскировать «blocked» спокойным брендом |
| V1 · P2 · малая/средняя | У icon объём/мелкая кардиограмма, menu bar использует SF Symbols, Capsule rounded custom type, notes свой orange → связь поверхностей слабее → общий небольшой набор акцента/отступов/типографики, знак отдельно | **Наблюдение PNG + код:** Assets, MenuBarViews, StatusCapsule, ReleaseNotesView. Не перекрашивать recording/error в брендовый orange; state symbols остаются |
| V2 · P2 · требуется замер | При minimum 720×520 sidebar занимает 200, notes min width 460, General содержит длинные hints → возможна теснота в RU → сначала реальные native screenshots/keyboard walkthrough, потом правка размеров | **Гипотеза**, clipping не наблюдался. HTML 720×520 не доказывает native отсутствие clipping. Длинные названия входа, ошибки, 5 раскрытых bindings, long notes |

Не предлагаем перенос updates в отдельный новый раздел прямо сейчас: существующий общий блок с What’s New уже решает запрос 0.6.1. В макете он сохранён. Если появится реальная теснота, обсуждаем отдельно. Уменьшение числа моделей форматирования, функций и разрешений в scope не входит.

## Референсы и направления

Пользователь подтвердил [OpenBot](https://openbot.run/) и [Grok Bot](https://x.ai/bot), 2026-11-10. Прямой native-референс: присланный What’s New OpenBot, с явным заголовком/версией, секциями, основным и вторичным текстом, отдельным footer. Берём принцип иерархии, а не знак, конкретную палитру/маскота или буквальную композицию. Сайты/публичные previews дают визуальный контекст, но не проверку их установленных приложений. Не переносим их agent workspace/чат в маленькую утилиту диктовки.

В браузере просмотрены первые экраны обоих сайтов. У OpenBot: крупный простой заголовок, тёмная поверхность, контрастный основной CTA и сиреневый акцент; сложный светящийся hero-фон не переносим в рабочую утилиту. У Grok Bot: светлая поверхность, чёрно-белая иерархия, крупный знак рядом с названием и спокойные серые вторичные тексты. Для CarrotType берём чёткость силуэта и иерархию, оставляя собственную морковь и тёплый акцент. Это наблюдения публичных страниц, а не полный аудит их приложений.

| Направление | Что меняется | Компромисс |
| --- | --- | --- |
| A · Нативный | Системная типографика, знакомые группы, тёплый точечный акцент, те же 5 разделов | Ближе к текущему продукту; меньше визуальной новизны, минимальный риск поведения |
| B · Тёплый | Более мягкие поверхности и выраженный тёплый акцент при том же составе экрана | Более заметный характер; больше проверки contrast/hover/selection, не оранжевая запись |
| C · Графичный | Монохром, сильнее заголовки, открытые группы вместо большого числа заливок | Самый большой визуальный сдвиг; дополнительная работа с native Form/light/dark/keyboard |

Три оригинальных SVG-гипотезы: A — морковь без мелких деталей; B — диагональная морковь с курсором; C — C с ростком. Это ещё не финальные app/icon/template exports. B в 16 px потребует optical simplification; C слабее связан с текущей морковью. У всех оставляем отдельную монохромную версию. Старые assets/history сохраняются. App/menu/installer/Sparkle согласуем только после выбора; menu bar recording/error не заменяем бездумно постоянным знаком.

Рекомендация к обсуждению: **интерфейс A**, проверить **логотип A и B** рядом в native icon sizes. Первый implementation-срез: A1–A5, U1/U2, аккуратные общие style tokens, выбранный знак. U3 — только если not-ready путь подтвердит пользу; V2 — до замеров не менять геометрию окна. Это предложение, не принятое решение.

## Как продолжить и что ещё проверить

1. Обсудить направления интерфейса/знака и конкретный scope. Затем записать решение; пока SwiftUI/assets/version metadata не менялись, нового Debug нет.
2. Завершить native D1: первый запуск/permission denial; Ultra missing/downloading/failed; обычная/hold/cancel/cold live draft; trial/transform; 720×520 и 880×680; RU/EN/light/dark; VoiceOver/keyboard/reduced motion/Increase Contrast. Не очищать реальные модели/статистику ради smoke.
3. D3 небольшими правками, без нового runtime/dependency/network/trust. После изменения shared bindings/controls — соответствующие production проверки; затем Debug 0.7.0, краткий ручной чеклист и отдельное разрешение публикации.

Нормативная основа: [Apple Settings](https://developer.apple.com/design/human-interface-guidelines/settings), [App icons](https://developer.apple.com/design/human-interface-guidelines/app-icons), [Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility). Читались официальные Markdown-версии страниц 2026-11-10. Не трактуем рекомендацию сократить settings как разрешение убрать полезные функции.

## Проверка материалов

WebKit/Playwright: 36 комбинаций направления/экрана/темы/ширины без JS errors и горизонтального переполнения content; footer What’s New виден в каждой комбинации. Screenshot-проверка A/light/minimum, B/dark/notes, C/dark/Capsule, монохромных маленьких знаков и mobile-адаптации страницы. SVG XML parsed. Нашлась и исправлена проблема самого HTML: footer notes уходил вниз при малом окне; теперь прокручивается только тело notes. Это не утверждение об ошибке/исправлении рабочего native приложения. Локальные evidence: `dist/CarrotType-0.7.0-Design-Review/` (не в git). Скриншоты первых экранов референсов также там; их сетевые/analytics console errors не относятся к автономному макету.

AIDOS validate/trace/review проходят, trace Missing Links: None; diff check и локальные Markdown-ссылки проверены. Native app build/functional regressions не запускались: изменены только документы, HTML и исследовательские SVG вне shipping assets. Само приложение не менялось; native GUI/VoiceOver walkthrough остаётся незавершённым.
