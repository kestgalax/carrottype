# Разделение General: диктовка и преобразования

2026-11-11. **Решение Codex согласовано; реализация разрешена после интеграции теста печати.** Maintainer: «ок, мне нравится, тогда после интеграции теста печати, переходим к этому изменению». Не запускать параллельно с текущей реализацией теста. Debug/manual acceptance и публикация будущей версии отдельно.

## Metadata

- Task ID: settings-organization
- Status: approved; dependency satisfied (typing-speed test integrated and 0.10.0 published); S1–S4 implemented for Codex review. No version bump, publication or merge is authorized by this implementation.
- Branch: implementation `kestgalax/settings-organization` from `origin/main` `22536e7` (published 0.10.0, PR #31 merge `bd387d8`); the approved design/history commits `5443d07`, `93b76cd`, `d4583d4` are preserved here.
- Roles: Codex исследует/проектирует/проверяет; реализация — OpenCode 2 в отдельном main-based worktree (latest maintainer instruction «давай тогда через opencode продолжим»). Direct ZCode readiness did not work and is not executing.

## Implementation status — 2026-11-12

Dependency check: the typing-speed test is integrated and 0.10.0 (34) is published from
`origin/main` `22536e7`; the maintainer’s earlier approval
(«ок, мне нравится, тогда после интеграции теста печати, переходим к этому изменению»)
is therefore no longer waiting on a future integration. The approved S1–S4 scope was implemented
on the fresh main-based branch above with the exact mapping in this spec:

- General owns language, theme, app updates and launch-at-login as its final section.
- Dictation owns the existing shortcut/PTT/clipboard controls plus the existing Ready-only
  formatting selector, exact rules, model preferences/My Rules and text trial.
- Text actions owns the existing Translate/Custom bindings (max 5, disclosure, add/delete,
  conflict handling and saved empty array).
- Dynamic Island, Setup, Models, Storage and Statistics keep their existing content and order;
  the typing test remains Statistics-only.

Runtime, persistence keys, saved values, defaults, models, prompts, helper protocol, trust/network
and history are unchanged. Evidence and limitations are in
`docs/debug-review-settings-organization.md`; Codex review and a separate manual/publication gate
remain.

## Traceability

- Product Intent Link: `docs/product-intent.md` — primary dictation and independent selection-transform loops, simple native shell.
- Roadmap Item: `docs/roadmap.md` — Settings organization proposal, separate from active typing-test implementation.
- Feature Spec: `docs/specs/ux-setup-status.md`, `docs/specs/features/selection-transform.md`.
- Related ADRs: ADR-002, ADR-012, ADR-014, ADR-018, ADR-019.

## Наблюдение по production-коду

[GeneralSettingsPane](../../../macos/CarrotType/Views/Settings/GeneralSettingsPane.swift) объединяет четыре задачи: запуск диктовки (hotkey/PTT/clipboard), оформление после распознавания, действия над выделенным текстом (до пяти bindings), настройки приложения (updater/theme/language/login). [FormattingRulesSection](../../../macos/CarrotType/Views/Settings/FormattingRulesSection.swift) — самый длинный блок: точные правила, model preferences, My Rules, summary/reset и text trial. Проблема не только в высоте: пользователю приходится искать настройки разных сценариев в одном месте.

[Dynamic Island](../../../macos/CarrotType/Views/Settings/DynamicIslandSettingsPane.swift) уже вынесен. [Setup](../../../macos/CarrotType/Views/Settings/SetupSettingsPane.swift) ведёт разрешения, выбор/проверку микрофона, Wave Link, Ultra и вводную пробу. [Models](../../../macos/CarrotType/Views/Settings/ModelsSettingsPane.swift) управляет пакетами/загрузками и сохраняет существующий выбор оформления. [SettingsPane](../../../macos/CarrotType/Views/Settings/SettingsPane.swift) содержит шесть пунктов, sidebar фиксирован 200pt. Native минимум окна — 720×520. Это аудит исходников, не измерение пользовательской навигации или новый native screenshot.

## Варианты

| Вариант | Эффект | Ограничение |
|---|---|---|
| Только «Оформление» отдельным пунктом | Убирает самый длинный блок из General | Управление диктовкой отдельно от её результата; General всё ещё смешивает app и transforms. |
| Только «Диктовка», с оформлением внутри | Небольшой шаг, +1 пункт | Bindings остаются в General, приложение/работа с текстом всё ещё смешаны. |
| **«Диктовка» + «Преобразования»** | Два основных продуктовых сценария имеют собственные места; General остаётся настройками приложения | +2 пункта: всего8; требуется проверить весь sidebar/низ окна. Рекомендуется. |
| Отдельно «Диктовка», «Постобработка», «Преобразования» | Самые короткие страницы | Уже9 пунктов, риск раздробить простой продукт и разделить один speech→result сценарий. Для первого шага не рекомендуется. |

## Рекомендуемая структура

| Пункт sidebar | Что находится внутри |
|---|---|
| **Основные / General** | Язык/тема, проверка и настройки обновлений, запуск при входе в macOS (последняя секция, как ранее просил maintainer). |
| **Диктовка / Dictation** | Сочетание клавиш, режим рации, оставлять результат в clipboard. Затем «Оформление текста»: Off/Light/Qwen/Gemma, точные правила, model preferences/My Rules, text trial и честная обратная связь о fallback. |
| **Преобразования / Text actions** | Существующие Translate/Custom bindings: hotkeys, language pairs, model/custom instructions, add/delete; без изменения выполнения или результата. |
| **Dynamic Island** | Существующие три режима, live-draft switch и preview; имя без перевода. |
| **Настройка / Setup** | Готовность, разрешения, микрофон/проверка уровня/Wave Link, Ultra и вводная диктовка. |
| **Модели / Models** | Существующее управление пакетами/загрузками и ready-only выбор. |
| **Хранилище / Storage** | Существующие данные/кэш/удаление. |
| **Статистика / Statistics** | Существующая статистика/WPM; текущая отдельная реализация теста скорости остаётся здесь. |

«Постобработка» в интерфейсе лучше назвать **«Оформление текста»** и держать внутри «Диктовки»: это то, каким будет вставленный текст. «Преобразования» работают с уже выделенным текстом, даже когда оформление диктовки выключено; это отдельный сценарий ADR-012.

На странице Dictation сначала короткая группа управления записью, затем выбор оформления/видимый обзор активных настроек и правила. Объёмные My Rules/text trial уже можно открывать по запросу, используя существующие disclosure-приёмы. Не прятать включённые правила без видимого summary и не менять значения при сворачивании. Дополнительное сворачивание всей группы правил — отдельное UX-решение, не обязательная часть первоначального переноса. Не заменять длинный General одной гигантской плоской формой без разделов.

## Сохранение поведения

- Перенос представлений, не изменение обработки/моделей/prompts/гранулярности правил. Те же `AppState` и observed `ModelManager`, те же keys/defaults, exact controls под Off/Light, legacy compatibility, явные ошибки/fallback и экспериментальный business tone.
- Не создавать вторые копии preferences для новых страниц. Выбор оформления на Dictation и Models использует прежний общий источник и Ready-only path, без загрузки от перехода на страницу.
- Извлечь private binding editor/formatting selector из General в переиспользуемые view-файлы. Сохранить max5bindings, collapse/add-expand, independent model resolution, пустой сохранённый список, конфликты chords, отмену capture и регистрацию hotkeys.
- Смена страницы во время записи **сочетания клавиш** отменяет её и восстанавливает регистрацию. Не путать `hotkey.isRecording` (capture chord) с активной диктовкой.
- Formatting text trial при уходе/закрытии отменяется и дожидается teardown через существующий gate; перенос `.onDisappear` не должен оставлять helper/reservation или внезапно отменять trial при несущественном remount.
- Не менять реальные capture/session/transform/delivery/statistics/updater, auto-start policy, clipboard или TCC. Не добавлять clock/task/monitor ради навигации. Это UI-реорганизация в существующем SwiftUI/AppKit.
- Setup микрофон и Wave Link в первом шаге **не дублировать** на Dictation. При необходимости одна ссылка «Настроить микрофон» ведёт в Setup; не переносить permissions/первый запуск вместе с этой задачей. То же для Models.
- Сохранить first-run и default General-if-ready/Setup-if-not-ready, Details/version/What’s New, окно и sidebar width. Выбирать Dictation при каждом открытии — отдельное несогласованное изменение, не делать автоматически.
- Восемь пунктов должны помещаться/оставаться достижимыми в реальном minimum720×520. Если навигация/нижний статус конфликтуют, scroll только списка sidebar с закреплённым нижним статусом, без увеличения минимума и скрытия Details/What’s New. Решение проверить native RU/EN light/dark, длинные локализованные имена, keyboard focus/VoiceOver. Не считать standalone detail720px доказательством whole-window layout.

## План после согласования

Сначала завершить текущий typing-test, провести Codex review, проверить релевантные проверки и интегрировать результат в main. Только после этой зависимости запускать OpenCode на реорганизацию настроек в новом worktree и новой ветке от обновлённого main. Оба изменения затронут Settings shell/AppState/тестовые ожидания и документацию; не расширять текущий typing-test dispatch. Пользователь уже разрешил следующий этап, повторное согласование прежнего scope не нужно. Публикация теста отдельным релизом не является предпосылкой: зависимость — проверенная интеграция кода. Публикация будущей версии требует собственного разрешения.

| Шаг | Scope / вероятные файлы | Acceptance / verification |
|---|---|---|
| S0 — выбрать | Этот spec и UX mapping | Согласовать2новых пункта, оформление внутриDictation, General только app. Это не разрешение на engine/behavior changes. |
| S1 — извлечение компонентов | General, новые Dictation/TextActions panes, отдельные editor/formatting views | Существующие controls/values/actions перенесены один раз; общий state/ready-only manager; ни одного потерянного поля/настройки. До/после inventory для всех saved modes. |
| S2 — навигация | SettingsPane, CarrotTypeSettingsView, RU/EN resources, focused-pane fixtures | Восемь пунктов с keyboard/accessibility; first-run/default/deep-links работают. Whole-shell720×520 и default-size native layouts всех новых страниц, footer/scroll reachability. |
| S3 — lifecycle и regression review | Existing setup/formatting/typing-test/Dynamic Island fixtures, targeted production integration checks | Chord capture отменён без потери регистрации; trial закрывается с реальным awaited cleanup; language/theme без shell remount; новый typing test живёт только в Statistics и не сломан. Не переписывать проверкиallCases вслепую: проверить фактические назначения. |
| S4 — docs/Debug | architecture, UX, ADR-012/018 crossrefs, task/roadmap/memory, Debug evidence | Relevant regressions, governance, arm64 Debug и подпись. Codex review; реальное ручное принятие до публикации. |

## Acceptance Criteria

- S0 завершён: инвентаризация, варианты, распределение и риски подготовлены; пользователь согласовал2новых пункта и порядок после интеграции typing-test. Ожидается dependency, не дополнительное подтверждение того же решения.
- Будущий UI: General только app; Dictation управление/оформление; Text actions выбранный текст; остальные пункты сохраняются. Все settings и stored values совпадают с исходными.
- Не возникает новых runtime/dependencies/network/engine/model defaults/history. Уход со страницы не ломает hotkeys, trial или gate.
- Native whole-shell layout подтверждает доступность8пунктов и нижнего статуса на минимальном размере. Перенос сам по себе не объявлять performance improvement без замера.

## Verification

- Check: чтение production General/FormattingRules/SettingsPane/Setup/Models и UX-spec; сверка границ ADR-012/014/018/019.
- Check: planning docs — local links, `git diff --check`, AIDOS validate/trace/review. App build skipped: app-код не меняется.
- Check: implementation — applicable setup/formatting/lifecycle/Dynamic Island/typing-test checks, targeted actual UI-state and hotkey/trial fakes, arm64 Debug; native RU/EN light/dark/min-size/all-model-mode visual QA. VoiceOver/интерактивная навигация — отдельная ручная проверка.

## Documentation Updates

- Update: этот proposal, roadmap/memory на этапе исследования.
- Update: после выбора architecture/sidebar UX, README settings paths, ADR-012 binding location и ADR-018 rule location; сохранить историю принятых архитектурных решений и опубликованные notes. Новый Debug review, roadmap следующего шага.

## ADR Impact

Existing ADR must be superseded or amended: поправить только ссылки/расположение UX в ADR-012/018 при реализации, runtime/protocol policy не меняется. ADR-002 native shell и ADR-014/019 behavior сохраняются; новый runtime/trust ADR не требуется.

## Согласование

Согласованный шаг — «Диктовка» и «Преобразования», а оформление — группа внутри «Диктовки»; General содержит настройки приложения. Пользователь выбрал реализацию после интеграции теста печати. Уменьшенный вариант с bindings в General остаётся исторической альтернативой, не выбранным scope. Codex координирует зависимость и review, OpenCode реализует следующий этап; завершённые агентские сессии освобождать после завершения их работы.
