# Dynamic Island: проект настроек

2026-11-11. **Решение согласовано; реализация разрешена.** Maintainer: «согласовываю, давай делать мне нравится» после предложения Codex о трёх режимах, default Full и сохранении result-панелей. Реализует OpenCode, проверяет Codex; публикация отдельно.

Исследование, проект и review — Codex. После согласования реализацию выполняет OpenCode в отдельном Orca worktree на новой ветке от актуального main. Номер версии пока не выбран. Связь: [product intent](../../product-intent.md), [roadmap](../../roadmap.md), [ADR-014](../../decisions/ADR-014-live-dictation-streaming.md).

## Metadata

- Task ID: dynamic-island-settings
- Status: approved for implementation, Debug/manual acceptance and publication pending

## Traceability

- Product Intent Link: `docs/product-intent.md`
- Roadmap Item: `docs/roadmap.md` — Current focus, Dynamic Island planning
- Feature Spec: `docs/specs/ux-setup-status.md`, `docs/specs/features/live-dictation-streaming.md`
- Related ADRs: ADR-012, ADR-014, ADR-016, ADR-017, ADR-018

## Цель

Уменьшить перекрытие рабочей области капсулой во время диктовки; собрать настройки островка в отдельном пункте sidebar **Dynamic Island**. Сохранить hotkey → локальное распознавание → вставка у курсора, полезные результаты и сообщения об ошибках.

Это исследование исходников, не результат проверки живого интерфейса. Нативный вид подсветки, несколько экранов и fullscreen требуют отдельной проверки на Debug-прототипе.

## Найдено в коде

| Доказательство | Значение для проекта |
|---|---|
| [GeneralSettingsPane](../../../macos/CarrotType/Views/Settings/GeneralSettingsPane.swift): один существующий пользовательский контрол капсулы — `liveDraftEnabled`, «Показывать текст во время речи». | Перенести контрол; сохранить ключ `carrottype.liveDraftEnabled` и значение. |
| [SettingsPane](../../../macos/CarrotType/Views/Settings/SettingsPane.swift) и [CarrotTypeSettingsView](../../../macos/CarrotType/Views/CarrotTypeSettingsView.swift): пять разделов, фиксированный sidebar/HStack. | Добавить шестой пункт после General; сохранить размеры окна и текущие переходы. |
| [StatusCapsuleGeometry](../../../macos/CarrotType/Views/StatusCapsule.swift): обычное состояние занимает 36 pt ниже выреза; draft имеет ширину минимум 360 pt и тело до 280 pt. | Выключение текста уменьшает, но не убирает капсулу. Нужен отдельный режим отображения. |
| Там же: NSPanel не активирует приложение; статусы пропускают мышь, результаты принимают Copy/Close; `hide()` уничтожает hosting view. | Нельзя скрыть все фазы без разбора: потеряются результаты. Скрытые анимации должны прекращаться. |
| `preferred()` выбирает сначала экран с вырезом, затем основной; обрабатывает изменение конфигурации экранов. | Сохранить политику первого этапа; не обещать следование за курсором. |
| [AppState](../../../macos/CarrotType/AppState.swift): `SessionSettings.liveDraft` управляет preview; финальная вставка всегда через WAV. Escape с непустым draft даёт Copy/Close на 5 секунд. | Скрытие текста должно отключать ненужные preview-проходы. |
| Там же: `.transformResult`, `.liveDraftResult`, `.dictationRecovery` используют общий result UI; `.understanding` используется и диктовкой, и transform. | Политике отображения нужна принадлежность операции, одного значения фазы недостаточно. |
| [MenuBarViews](../../../macos/CarrotType/Views/MenuBarViews.swift): отдельные формы/цвета и accessibility labels для записи, processing, cleanup, ошибки. | Уже есть основа режима без статусного оверлея. |
| Ошибка доступна в меню и [Details](../../../macos/CarrotType/Views/Settings/StatusDetailsPane.swift); Details показывает `lastFormattingOutcome`. | Не нужна новая история или система уведомлений. |

Не переносить в Dynamic Island микрофон/Wave Link, PTT, clipboard, форматирование, язык или тему: это настройки диктовки/приложения.

## Сравнение вариантов

| Вариант | Польза | Ограничение |
|---|---|---|
| Один выключатель островка | Небольшой объём | Нет промежуточной заметной индикации; неочевидна судьба результатов. |
| **Три режима хода диктовки** | Выбор между подробностью, подсветкой и свободным экраном | Требует компактного представления и ясного описания исключений. Рекомендуется. |
| Отключить вообще все панели | Ничего не всплывает | Нужен другой интерфейс результатов перевода и восстановления; пересмотр ADR-012. Отдельный объём. |

## Предлагаемый раздел

Sidebar: **Dynamic Island**. Группа «Во время диктовки» / “During dictation”, один выбор:

1. **Полная капсула** / “Full capsule” — текущие состояния и текст при включённом live draft.
2. **Минимальная индикация** / “Minimal indicator” — маленькая подсветка без текста и роста.
3. **Только строка меню** / “Menu bar only” — нет статусной панели; состояние показывает существующая иконка.

Ниже — существующий переключатель «Показывать текст во время речи». Доступен только в полной капсуле при поддержке preview моделью. В других режимах виден, но отключён с коротким объяснением; сохранённое значение не сбрасывается. Возврат к полной капсуле восстанавливает прежний выбор.

Встроенный небольшой preview показывает синтетические состояния «Запись» / «Обработка», используя общие компоненты реального UI. Он не начинает запись/модель, не создаёт WAV, не меняет clipboard/stats и не открывает настоящую панель поверх приложений.

Подпись: «Настройки применяются со следующей диктовки. Результаты перевода и восстановление текста показываются отдельно». Для строки меню — контекстное замечание об ограниченной заметности при её автоскрытии. Дополнительные подтверждения не нужны.

## Минимальная индикация

Первый прототип: тонкая светящаяся полоска под нижним краем выреза без тела с текстом; ориентир выступа 4–6 pt. На экране без выреза — полоска примерно 44 × 8 pt вверху по центру под строкой меню. Окончательные размеры и заметность проверить на native Debug.

Запись — цельная красная полоска с мягкой пульсацией; обработка — три точки в той же области. Форма отличает состояния независимо от цвета. Reduce Motion отключает пульсацию, Increase Contrast сохраняет границу. Не забирать фокус, пропускать клики. Это индикатор записи, а не обещание, что распознавание уже готово или слышит речь.

## Матрица поведения для согласования

| Состояние | Полная капсула | Минимальная индикация | Только строка меню |
|---|---|---|---|
| Idle | Панели нет | Панели нет | Панели нет |
| Запись | Listening; draft при включённой опции | Полоска; preview не запускается | Иконка записи; preview не запускается |
| STT / cleanup | Текущий статус | Три точки без текста | Существующая иконка processing/cleanup |
| Успешная отправка команды вставки | Текущая Writing/Done последовательность | Индикатор исчезает | Панели нет |
| Light fallback | Текущее сообщение | Предупреждение в меню и Details | Предупреждение в меню и Details |
| Escape при записи | С непустым draft — Copy/Close на 5 с, иначе скрыть | Отмена и скрытие, draft не вычислялся | Отмена, draft не вычислялся |
| Ошибка записи/STT | Существующая ошибка в меню/Details | То же | То же |
| Ошибка вставки готового текста | Result с Copy/Close | Такой же result | Такой же result |
| Translate / Custom | Текущие processing и result | Без изменений | Без изменений |
| Setup trial | Выбранное представление записи; финал в Setup | Компактная запись; финал в Setup | Иконка и inline Setup; финал в Setup |

Режим строки меню отключает **статус диктовки**, а не любые result-панели. Если принципиален полный запрет окон, до реализации нужен дополнительный проект доставки результатов. Менять этот смысл молча нельзя.

Для fallback добавить в меню условную короткую строку из существующего RAM `lastFormattingOutcome`; Details оставляет подробности. Подпись явно относится к последней завершённой диктовке, а не текущей обработке. Не считать fallback ошибкой записи. Отправка команды вставки не является подтверждённой вставкой в принимающее приложение.

## Контракт реализации

- Новая локальная enum-настройка; отсутствующее/неизвестное значение → полная капсула. Сохранить defaults: live draft off для новых пользователей, старый Bool без сброса.
- Захватить режим и effective preview в конфигурацию сессии: `full && savedLiveDraft && supportsStreaming`. Использовать захваченные значения при отмене и завершении, не перечитывать изменённую настройку.
- Режим действует со следующей диктовки. Изменения в recording/processing не прерывают capture/teardown, не меняют текущий UI и не запускают второй preview.
- Сохранить режим до завершения UI-последовательности сессии; старые delayed callbacks не должны показывать панель поверх новой операции.
- Не стирать доменные фазы ради скрытия окна. Общая policy различает dictation status, recovery и transform; применяется во всех `attach/sync/show/positionPanel`, включая screen-change/theme/locale. Скрытая панель не должна появляться из другого пути.
- Не менять engine/runtime, модели, сеть, хранение текста, install/operation gate, mute, PTT, paste, stats. В idle не оставлять фоновые preview-проходы/анимации.

## Задачи после согласования

Каждая задача трассируется к этому spec и roadmap. OpenCode получает согласованный spec, новую ветку от актуального main и отдельный worktree. Codex проверяет отчёт и diff.

| Шаг | Scope / вероятные файлы | Acceptance и verification |
|---|---|---|
| D0 — выбор | Этот документ; будущая поправка ADR-014 | Пользователь выбирает режимы, исключения и форму индикатора. До выбора app-код не менять. |
| D1 — раздел и preferences | Новый enum/pane; `AppState.swift`, `SettingsPane.swift`, `CarrotTypeSettingsView.swift`, General, RU/EN resources | Шесть разделов с keyboard access; live draft перенесён один раз. Изолированные defaults: absent/invalid + старые true/false. Native RU/EN/light/dark/minimum-size; preview без микрофона/моделей. |
| D2 — policy и индикатор | `AppState.swift`, `StatusCapsule.swift`, при необходимости общие policy/view файлы | Матрица выполнена; preview не вызывается в compact/menu. Result/recovery доступны. Снятый режим стабилен до завершения. Проверять production policy и настоящую AppState/coordinator с fake adapters, не копию алгоритма. |
| D3 — регрессии и Debug | `MenuBarViews.swift`, harness scripts, docs/architecture, ux spec, ADR-014 | Fallback виден без статусной панели. Lifecycle/setup/reliability проверки и Debug build успешны. Подписанный Debug для ручной оценки. Roadmap/memory отражают доказательства и риски. |

Обязательные сценарии: toggle/PTT; холодный старт; stop/Escape до preview-ready; пустой/непустой draft; ошибка вставки; transform после dictation; новая сессия при старой success-анимации; изменение режима в recording/processing; смена экранов при скрытой панели; закрытие Settings; Quit/ожидающий update. Проверять отсутствие **вызовов** preview в compact/menu, не только пустой текст.

Применимые команды: `bash scripts/verify-session-lifecycle.sh`, `bash scripts/verify-setup-formatting.sh`, `bash scripts/verify-dictation-reliability.sh`, `python3 scripts/verify-model-catalog-streaming.py`; дополнить native/AppState fixtures адресными сценариями. Governance: `npm run aidos:validate`, `npm run aidos:trace`, `npm run aidos:review`; Debug — по `ops/ci.md`. Реальные notch/external display/fullscreen, VoiceOver и видимость при скрытой строке меню — отдельные ручные проверки, не следствие успешной сборки.

## Documentation / ADR impact

После согласования дополнить ADR-014 условиями effective preview и Escape без draft. ADR-012 остаётся прежним при сохранении transform UI; глобальный запрет result-панелей потребует его пересмотра. Новый ADR о runtime/engine/trust не требуется. При реализации обновить перечень sidebar в architecture/ux-setup-status, условия live draft в product intent и пользовательский путь в README (сохранив тон). Не менять релизные версии/историю сейчас. Публикация требует отдельного принятия Debug и разрешения.

## Решения для обсуждения

1. Три режима выше с полной капсулой по умолчанию или достаточно полной капсулы и минимального индикатора?
2. Допустимы ли result-панели перевода и восстановления при ошибке вставки во всех режимах?
3. Подходит ли тонкая подсветка, без live draft и Copy после отмены в минимальном режиме? Сохранённая опция текста возвращается в полной капсуле.

### Согласованный выбор — 2026-11-11

Все три режима; Full по умолчанию без изменения сохранённых preferences. Минимальный режим — тонкая подсветка записи и компактная обработка, без вычисления draft и Copy после Escape. Menu bar only отключает статус диктовки; transform и recovery Copy/Close остаются во всех режимах. Preview настройки — синтетический, без записи. Режим захватывается на следующую сессию. D0 завершён. D1–D3 поручаются OpenCode в отдельном новом worktree от main с этим согласованным документом; Codex выполняет review перед доставкой Debug пользователю.

## Проверка проекта и ограничения

Исходники сверены с ADR-012/014/016/017/018 и lifecycle-архитектурой: финал через WAV, RAM-only результат, сохранение operation gate и per-version release gate. App-код не менялся; сборка/app-регрессии не нужны для документационного этапа и не запускались. Нативный вид/заметность — гипотеза до прототипа. Исследовательская задача OpenCode остановлена после уточнения ролей; её результат не использован как доказательство.

## Acceptance Criteria

- Для этапа планирования: есть inventory по исходникам, варианты, рекомендуемая матрица, миграция, риски, вопросы и проверяемые D0–D3. Подготовлено Codex; реализация остаётся заблокированной на согласовании пользователя.
- Для будущей реализации: раздел, три режима и исключения соответствуют согласованной матрице; preferences сохранены; hidden preview не работает; results/recovery доступны; текущая сессия стабильна при смене режима.
- OpenCode доставляет проверенный Debug и отчёт; Codex проводит review. Нативные ручные ограничения и отдельная публикационная авторизация явно отражены.

## Verification

- Check: чтение production Settings/AppState/Capsule/menu/Details и сверка с ADR; локальные ссылки документа разрешаются.
- Check: `git diff --check` и локальные AIDOS validate/trace/review перед доставкой проекта.
- Check: Debug и app-регрессии отложены до app-реализации; здесь изменены только документы. Будущие команды и ручные сценарии перечислены в D1–D3.

## Documentation Updates

- Update: этот проект, roadmap и memory обновлены на этапе планирования.
- Update: при реализации — architecture, ux-setup-status, product intent, README, ADR-014 и Debug evidence; не переписывать опубликованные release notes.

## ADR Impact

Existing ADR must be superseded or amended: после согласования дополнить ADR-014 условиями effective preview/отмены в режимах без текста. ADR-012 сохраняется при существующей доставке transform results. Нового runtime/engine/network/trust решения нет; глобальное отключение result-панелей потребует отдельного пересмотра ADR-012 до реализации.

## Реализация — 2026-11-11 (OpenCode, на review)

D1–D3 реализованы в отдельном Orca worktree на новой ветке от main `d0a4058`; авторитетный spec-коммит `0b3e27c` перенесён cherry-pick, прежняя planning-ветка не использована. Добавлены `DynamicIslandMode`/`DynamicIslandPolicy`, pane после General, перенос live-draft переключателя с тем же ключом, synthetic preview на общих компонентах, minimal indicator и menu-only suppression. Режим и effective preview захватываются в `DictationSessionSettings`; minimal/menu не вызывают preview и не дают Escape Copy. Result/recovery/transform остаются full; fallback виден в меню/Details. Coordinator/install gate/WAV/paste/PTT/mute/stats/model policy не менялись.

Проверки: `bash scripts/verify-dynamic-island.sh`; `python3 scripts/verify-dynamic-island-app.py` (actual AppState/coordinator с fake adapters); существующие lifecycle/setup/reliability/catalog scripts; AIDOS validate/trace/review; arm64 Debug build. Offscreen native RU/EN light/dark/minimum snapshots и подписанный Debug приложены в отчёте. Реальные notch/external/fullscreen, VoiceOver, auto-hidden menu bar и интерактивное принятие остаются ручными; публикация не разрешена. Код review выполняет Codex.
