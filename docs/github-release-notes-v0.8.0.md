# CarrotType 0.8.0 — draft

Not published. Signed Debug 0.8.0 (30) is under maintainer review; a separate publication instruction is required. Stable/latest is 0.7.0. Canonical localized content: `macos/CarrotType/Resources/ReleaseNotes.json`.

- Правила локальной постобработки: запинки, повторы, самоисправления, оформление и свои предпочтения. Текстовая проба прямо в настройках.
- System / Light / Dark, независимо от языка, с сохранением выбора.
- Для нового выбора Qwen3 0.6B и Gemma; совместимость установленного Smart+/старых действий сохраняется.
- Light сохраняет смысловые слова, переносы и fenced code. Незавершённые ответы и обнаруженные потери защищённых значений отклоняются с видимым переходом на базовую обработку.

Модель может ошибаться и не всегда следует предпочтениям. [Проверки/ограничения](debug-review-v0.8.0.md), [синтетическая оценка Gemma](2026-11-10-formatting-quality-0.8.0.md). Веса не включены; новых движков/сетевых каналов нет. Не Developer ID/notarized.
