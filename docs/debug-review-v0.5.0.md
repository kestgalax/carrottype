# Проверка Debug 0.5.0 (25)

Статус: Debug предоставлен; пользователь 2026-11-10 явно поручил публикацию после обсуждения ошибки доступа к feed. Выпуск готовится, ещё не опубликован. Ветка `feat/github-app-updates`, ADR-017, задачи U1–U3 плана улучшений. Предыдущая опубликованная версия — 0.4.0 (24).

## Что изменилось

Нативная проверка/загрузка/установка обновлений Sparkle из GitHub Releases. Автоматические проверки и скачивание с установкой при выходе — отдельные добровольные настройки, по умолчанию выключены. Подпись проверяется у feed и архива. Установка ждёт завершения записи, распознавания, форматирования, вставки, отмены с восстановлением mute или transform. Остальные функции сохраняются.

## Сборки

- Обычная: `dist/CarrotType-0.5.0-Debug/CarrotType.app` — использует существующие настройки/модели, не заменяет /Applications.
- Отдельный тест обновления: `dist/CarrotType-0.5.0-update-test/manual-A/CarrotType.app`, build 25 → 26. Bundle ID `app.carrottype.macos.update-test`, отдельные настройки и `~/Library/Application Support/carrottype-update-test`. Для этой проверки уже подготовлена независимая APFS-копия установленного Ultra; исходные веса не менялись. Cleanup-пакеты туда не копировались.
- Локальный сервер: `dist/CarrotType-0.5.0-update-test/start-server.command`. Только `127.0.0.1:39187`, публичных тестовых релизов нет. Автоматический тест сервер остановил; для ручного теста его нужно запустить снова.

## Ручная проверка

1. Закрыть все запущенные копии CarrotType и открыть обычный Debug. В General появился блок «Обновления приложения», обе опции изначально выключены. Проверить включение/выключение и сохранение после перезапуска, RU/EN, доступность «Проверить обновления…» в меню и Details. Пока 0.5.0 не опубликована, настоящий GitHub feed отсутствует: ошибка проверки ожидаема и не должна мешать диктовке. После теста автоматические опции можно выключить.
2. Проверить обычную диктовку RU/EN, hold-to-talk, Escape, live draft, сохранение/Copy последнего результата, выбранный микрофон/meter и Wave Link unmute/restore, если используется. Проверить привычное форматирование и Translate/Custom, настройки и Statistics. Модели и данные основной установки должны остаться на месте.
3. Закрыть обычный Debug. Запустить `start-server.command` (оставить его терминал открытым), затем тестовую `manual-A/CarrotType.app`. Пройти её отдельный Setup, выдать микрофон/Accessibility для тестовой копии; Ultra уже подготовлен. Проверить meter/короткую диктовку до обновления. Не скачивать cleanup ради этой проверки.
4. В тестовой копии выбрать «Проверить обновления…»: должно появиться нативное предложение обновления с build 25 до 26, затем скачивание и установка. Marketing version обеих тестовых сборок — 0.5.0. После перезапуска подтвердить build 26 командой ниже; повторная проверка должна сообщить, что новой версии нет. Настройки тестовой копии и Ultra должны сохраниться; снова проверить meter, диктовку и Accessibility. Если macOS потребует повторной выдачи прав, записать это, не считать их сохранение доказанным.
5. Чтобы проверить ожидание активной сессии **при первом переходе A → B**, начать запись в редакторе, открыть проверку обновлений и запросить установку, пока запись активна. Приложение не должно перезапуститься. Вернуться в редактор и завершить диктовку: установка продолжается после обработки/вставки. Обычная проверка обновлений/скачивание сами по себе не должны блокировать новую запись. Вместо завершения можно проверить Escape: сначала отмена и восстановление mute, затем установка. Для повторения нужен свежий A (не понижать уже обновлённый app на месте при работающем процессе).
6. Остановить локальный сервер через Ctrl-C; проверить понятную ошибку проверки без сети. Закрыть тестовую копию, вернуться к обычному Debug/установленной версии. /Applications этой проверкой не заменялся.

```bash
/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' \
  '/Users/kestgalax/Projects/2026/carrottype/dist/CarrotType-0.5.0-update-test/manual-A/CarrotType.app/Contents/Info.plist'
```

До публикации также требуется проверка установленной Release-копии из итогового DMG, read-only/DMG/translocation поведения Sparkle и фактического сохранения TCC. Текущая локальная подпись не является Developer ID/нотарификацией. Приватный Ed25519-ключ остаётся в Keychain; перед выпуском нужен контролируемый владельцем зашифрованный backup вне репозитория (ops/deploy.md).

## Автоматически проверено

- Debug arm64: `BUILD SUCCEEDED`; отдельная доставочная копия подписана `CarrotType Development`, `codesign --verify --deep --strict` passed. Известные предупреждения Xcode CoreDevice/старого iOS Simulator не мешают macOS build.
- Production `UpdateInstallationGate`: очередь старта, занятость и teardown, последняя проверка перед termination, атомарная блокировка новой операции, abort/retry и однократный callback.
- Release metadata/feed tests: монотонный build, stable-only, обязательная подпись, production/staging isolation, экранирование заметок и подпись/размер в feed.
- Настоящий Sparkle 2.10.1 installer на двух подписанных app bundles: offline 2001; изменённый подписанный feed 1000; повреждённый архив 4005 — build 25 сохранён. Доступное обновление → native install → build 26; повторная проверка — нет новой версии. После замены deep signature, helper и MLX metallib на месте, внешние fixture-файлы неизменны. Логи и `results.txt` в test directory. Это не проверка реальных пользовательских данных/TCC/GUI.
- Clipboard/selection/helper/protocol regressions; Ultra catalog/migration/legacy path safety; streaming catalog flags passed.
- AIDOS validate/trace/review passed (existing advisories only), shell syntax and local diff hygiene checked.

Отдельные результаты ручной UI/TCC проверки пользователь не перечислял; публикация явно авторизована. Независимое подтверждение TCC и полный network audit отсутствуют. Итоговый Release DMG и GitHub assets проверяются при выпуске. Offline dictation с установленными моделями должна сохраняться независимо от updater; это нужно подтвердить ручным smoke. Повторного разрешения на сам выпуск не требуется; при preflight обнаружена приватная видимость репозитория; пользователь отдельно разрешил публичный доступ к коду/истории, и видимость изменена на public.

## Release verification — 2026-11-10

The user explicitly instructed publication after Debug delivery and separately authorized public repository code/history. GitHub visibility is verified public. Individual manual UI/TCC results were not enumerated; those limits remain recorded rather than inferred from the authorization.

Clean Release arm64 `BUILD SUCCEEDED`. Final DMG `hdiutil verify`, deep app/component signatures, Ultra-only catalog, no Whisper/debug dylib/model weights, cleanup helper path-jail rejection and MLX shaders passed. Existing DMG background and layout hashes remain unchanged. Production ZIP and appcast are signed with the persistent Keychain key and verified; artifact hashes are in the 0.5.0 release notes. No private key was exported. Remote asset verification/publication follows these local gates.
