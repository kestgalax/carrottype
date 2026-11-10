# Debug review — CarrotType 0.8.0 (30)

Status: implemented on `feat/formatting-rules-theme-0.8`, signed Debug for maintainer review. **Not published**; stable remains 0.7.0. No 0.8.0 manual acceptance/publication authorization yet. [Task/P1–P4](specs/tasks/dictation-rules-and-theme.md), [ADR-018](decisions/ADR-018-dictation-rules-and-cleanup-catalog.md).

## Коротко проверить вручную

1. **Основные → правила:** выберите Gemma или Qwen3 0.6B, откройте «Проверить на тексте». Сравните «эм привет как дела» с включённым/выключенным удалением запинок. В «Мои правила» задайте «Пиши название приложения керроттайп как CarrotType» и проверьте «сегодня мы проверяем керроттайп». Затем одна обычная диктовка в поле ввода: вставка работает; перевод/Custom остались отдельными действиями.
2. **Тема:** System → Light → Dark, затем перезапуск. Выбор сохраняется, язык независим; окно/Details/«Что нового»/Capsule читаются. В System смена темы macOS подхватывается. Светлая/тёмная принудительные темы не должны следовать смене macOS.
3. **Безопасность результата:** проба «я не согласен на 15 процентов напиши Марии до 17:30» сохраняет число/отрицание (возможен честный fallback на Light). Отмена пробы не оставляет приложение занятым. В новом выборе моделей только Qwen/Gemma; старый Smart+, если уже был активен/в действии, продолжает работать. Ничего удалять для проверки не нужно.

Модель может не выполнить предпочтение: Gemma в синтетических примерах не всегда применяла самоисправление или разбиение на абзацы. Это не жёсткие текстовые преобразования. При обнаруженной потере чисел/обёрток/кода результат отклоняется целиком и применяется Light; факт fallback виден в пробе и обычной диктовке. Проверки ограничены и не доказывают сохранность всего смысла.

## Build and local verification

- arm64 Debug via pinned resolved packages/Xcode 27: `BUILD SUCCEEDED`; version/build 0.8.0/30. Source identity/trust/settings paths unchanged. Signing: existing self-signed CarrotType Development, **not Developer ID/notarized**.
- Delivery app: `dist/.builds.noindex/CarrotType-0.8.0-Debug/CarrotType.app`; archive: `dist/CarrotType-0.8.0-30-Debug.zip`. No replacement/launch of `/Applications/CarrotType.app`, user settings/model/stat roots unchanged. Build/test bundles kept in noindex/temporary locations to avoid Spotlight duplicates.
- `verify-formatting-rules.sh`: real rule persistence/corruption/Unicode bound/snapshot/dispatch, tokenizer-budget arithmetic/context limits, real Light meaningful words/newlines/fenced-code/empty handling, protected-literal validation, v3 purpose separation, theme persistence/system/invalid fallback and independent language key.
- `verify-formatting-app.py --build-log <successful non-cached Debug log>`: actual AppState/ModelManager against built Debug dylib, separate temporary signed bundle/defaults/model/stat root, no registered hotkeys/mic. Caught and fixed legacy-ready status being incorrectly hidden by the non-downloadable guard. Checks restored legacy active mode/binding-specific availability/no new recommendation/Storage; actual theme/rules persistence; trial admission/lease/result/fallback/cancel/busy admission; clipboard changeCount/history/stats unchanged. Helper fixture is invalid/outside its production jail, so fallback check intentionally performs no model inference.
- Production lifecycle, reliability, setup/formatting, Ultra migration/storage, update gate/signature, release-notes, catalog and brand checks passed. No new dependency/model revision/engine/network sink or trust change. Hosted CI evidence is recorded below once available; local checks do not stand in for a hosted result.
- Actual production SwiftUI rendered offscreen in RU/EN, light/dark, Settings minimum 720×520, General/Models/notes/rules and Capsule. Layouts inspected; no interactive/VoiceOver/device/TCC/system-theme walkthrough claim. Evidence under `dist/.builds.noindex/CarrotType-0.8.0-Native-Review/`.

## Model evidence and limits

Synthetic developer-authored texts only; existing installed pinned Gemma 4 E2B read locally, no downloads/user dictations. `scripts/evaluate-formatting.py` + `scripts/fixtures/formatting-quality.json` provide reproducible helper-only opt-in evaluation. Final observations: `dist/.builds.noindex/CarrotType-0.8.0-model-eval-final.json`; [quality notes](2026-11-10-formatting-quality-0.8.0.md). Each helper call cold-loads/exits; timings are single observations, not comparative latency/RAM benchmarks.

The first verbose prompt copied the transcript; shortened direct instructions improved hesitation/punctuation and custom-term behavior. Real examples still exposed model losses (15 dropped, outer quotes/fences removed, Cyrillic introduced into English); conservative checks now reject these outputs to visible Light fallback rather than inserting them. Inner quoted speech and question-as-data examples retained meaning; Translate regression produced the English translation independently of rules. Context-overflow example rejected before generation. Self-correction/paragraph compliance remains imperfect and is explicitly a quality limitation.

Qwen3 0.6B is absent: no hidden download, no Qwen/Gemma quality/latency/RAM comparison claimed. Full long-output runtime, independent TCC/device, accessibility, actual update installation and network audit were not rerun for this change; production bounded-output/cancellation/update regressions cover controller behavior only. GigaAM stays deferred. Maintainer manual review and separate release instruction remain required.

## Delivery integrity

Final local signed Debug archive SHA-256: `114c9ef3ccd498e94a572313a9af1f5c3bbd26eb3ad6a89e28e22dcf28687a73`. Deep/strict signature verification and bundled version/notes/catalog/MLX resources checked. Local governance validate/trace/review passed; [implementation review and residual risks](reviews/2026-11-10-dictation-rules-theme.md).

PR: [#26](https://github.com/kestgalax/carrottype/pull/26), draft for Debug review. Initial hosted production regressions passed; clean Debug compile was still running when a final local sign/percent-number guard refinement was made. The final signed Debug was rebuilt, real native checks and numeric-sign/percent regressions passed; final-source hosted CI is pending, not claimed successful. Check current PR status before any release. Hosted AIDOS is explicitly skipped without private tooling; local validate/trace/review passed.
