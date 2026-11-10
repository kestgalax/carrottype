Draft only — Debug 0.6.2 (28) awaits manual acceptance. No production release/assets. Content generated from bundled ReleaseNotes.json.

# CarrotType 0.6.2

2026-11-10

Более надёжные сессии с привычным сценарием диктовки\.

## Улучшено

- Единое управление каждой записью\. Запуск, остановка и отмена завершаются одной очисткой: восстановлением mute и удалением временного аудио\.
- Настройки согласованы на протяжении записи\. Модель, форматирование и микрофон фиксируются при старте\. Изменения применяются к следующей сессии\.

## Исправлено

- Очистка моделей ждёт завершения операции\. Выгрузка предыдущей сессии не прерывает новую\. При занятом конвейере удаление пакетов предлагает повторить попытку позже\.


Verification/limits and manual checklist: `docs/debug-review-v0.6.2.md`. Still self-signed/unnotarized; Release/DMG/signed archive/feed preparation follows explicit user acceptance.
