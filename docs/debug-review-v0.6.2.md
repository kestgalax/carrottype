# Debug 0.6.2 (28): lifecycle и проверки

Статус: C1–C2 реализованы в `refactor/dictation-session-lifecycle` от main после 0.6.1. Локальный arm64 Debug и production checks проходят. Ручное принятие и публикация 0.6.2 ещё не разрешены. 0.7.0 UI/UX/logo не начат; текущие интерфейс/иконка сохранены.

## Сборка

`dist/CarrotType-0.6.2-Debug/CarrotType.app` — обычный Debug с текущими моделями/настройками. Подпись `CarrotType Development`, не Developer ID/notarized. Установленная `/Applications/CarrotType.app` не заменяется агентом. Закрой другие копии перед открытием Debug; при необходимости повторно разреши Microphone/Accessibility этой копии.

## Что изменилось

- Координатор владеет стартом/остановкой/отменой и очисткой; следующий запуск/установка ждёт завершения предыдущей выгрузки. Модель/форматирование/вход и режим горячей клавиши фиксируются на запись; clipboard/statistics opt-ins продолжают учитываться при доставке, как раньше.
- При отмене recorder останавливается сразу; teardown дожидается pending unmute/preview/worker и восстанавливает прежний mute ровно один раз. Отменённый trial не доставляет поздний результат.
- У streaming actor и PCM/peak callbacks свои поколения. Запоздалые данные старой записи не должны менять новую. Обычный Quit отменяет/дожидается cleanup перед выходом; Sparkle сохраняет прежнее ожидание занятой операции.
- Удаление моделей при занятом конвейере отклоняется с предложением повторить позже. Защита автоматизированно проверена с тестовым телом удаления; рабочие веса не удалялись. Все полезные функции сохранены.

## Ручной чеклист

1. Обычная диктовка RU/EN: toggle → stop → однократная вставка; Off/Light и привычный Smart/Gemma; Copy Last Dictation/retain clipboard, Translate/Custom и локальная статистика. Поменяй форматирование во время записи: текущая сессия использует начальное значение, следующая — новое. Clipboard opt-out при доставке сохраняет прежнее поведение.
2. Hold-to-talk: очень быстрое нажатие/отпускание, затем нормальное удержание; несколько быстрых stop/start/Escape. После завершения очистки снова доступна запись. Нет двойной вставки/зависшего Listening или устаревшего текста в следующем Capsule. Поменять toggle/hold во время записи можно, но активный chord заканчивает сессию по её исходному режиму.
3. Live draft на холодном запуске: начни говорить сразу, останови/отмени во время загрузки, затем повтори. Итог по WAV не теряет начало речи; Escape сохраняет непустой draft в Copy/Close, без вставки. При teardown холодной CoreML загрузки новая запись может кратко ждать безопасного завершения; это не новая бесконечная запись. Проверь, что текст/уровень старой записи не появляются в новой.
4. Если используешь Wave Link unmute: до старта запомни исходный mute. Stop, Escape, короткая/тихая запись, trial Cancel и Quit должны восстановить именно исходное состояние. Аудиозапись начинается без ожидания RPC, preview ждёт unmute. Саму запись/LED и реальную доступность устройства агент не проверял.
5. Setup trial: нормальный результат только в Settings; Cancel/Escape во время записи, Cancel/выход из Setup при обработке. Clipboard, Last Dictation, stats и внешний caret не меняются. Следующая проба доступна после завершения cleanup; пустой/отменённый trial не отмечается как успешный.
6. Обычный Quit во время записи/загрузки/обработки: нет финальной вставки после принятой отмены, mute восстановлен, приложение выходит после безопасного cleanup и потом запускается снова. Если результат уже начал доставляться, Quit дожидается его завершения. SIGKILL/аварийное выключение остаются неграциозными и не тестируются как обычный Quit.
7. Settings: RU/EN, mic meter, выбранный вход, сохранённые bindings/модели, Storage/stats и «Что нового». Рабочие модели ради проверки удаления **не удаляй**: занятый путь и отсутствие вызова удаления уже проверены на production reservation/fixtures автоматически. Реальные файлы могут быть удалены только при твоём осознанном действии в idle.
8. Updater: проверка/скачивание не обрывают запись/transform; установка/перезапуск ждут capture/STT/cleanup/restore/unload. Публичный latest пока 0.6.1 (27), поэтому этот Debug 28 корректно не предлагает новой версии. Никаких тестовых публичных релизов для smoke не создаётся.

## Автоматическая проверка и границы

- `verify-session-lifecycle.sh` компилирует actual coordinator + installation gate с управляемыми задержками: queued PTT release, cold preview/unmute, повторные stop/cancel, snapshot, non-cooperative поздний результат, ошибки start/stop/process, старые callbacks, удаление временного WAV, delete/unload/install/termination barriers. Проверяется ровно одна restore/unload.
- Тот же harness компилирует реальные LiveDraftText/WaveLinkPortOrder вместо копий, actual streaming actor/fanout с test-only SDK module: paused inference, join before cleanup, поздний result и сохранённый старый PCM handler. Production всегда использует настоящий pinned FluidAudio; реальный CoreML inference это не доказывает.
- Targeted mutations в **временных копиях** production кода (удалить final unload, сломать junk sanitation/cached-port priority, убрать epoch guard настоящего streaming actor) компилировались и обнаруживались тестами. Tracked код не ломался. Дополнительная streaming epoch-проверка относится к реальному actor со stub SDK.
- Existing reliability/setup/Ultra/update/notes/catalog tests и локальный Debug проходят. Release-notes tests используют актуальные bundle metadata вместо фиксированного номера предыдущего релиза.
- `.github/workflows/macos.yml`: pinned checkout/AIDOS, read-only token, actual regression suite и unsigned arm64 Debug на совместимом Xcode 27; без моделей, микрофона, ключей и публикации. Удалённый запуск не выполнен: GitHub отклонил push workflow из-за отсутствия scope `workflow` у текущего OAuth-токена; подключённая интеграция также вернула `403 Resource not accessible by integration`. Ветка и коммиты сохранены локально; remote branch/PR/run не созданы. YAML прошёл локальный синтаксический разбор; это не считается успешным CI.
- Native микрофон/права, настоящий cold CoreML/unmute/VoiceOver/meter и поведение после замены остаются ручными. Реальные пользовательские данные/модели/статистика не удалялись. Новые движки, зависимости и network sink не добавлены; offline dictation после установки моделей ожидается без сети, полный независимый network audit не выполнялся.

Публиковать только после принятия этой Debug-версии пользователем. Release/DMG/production ZIP/appcast для 0.6.2 пока не готовились.
