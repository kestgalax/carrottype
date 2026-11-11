# Debug review — CarrotType 0.8.0 (30)


## Published — 2026-11-11

Maintainer accepted the signed first-sentence Debug and authorized release: «ок, пока остановимся, хорошо получилось, давай релизить». Stable/latest **0.8.0 (30)** published on 2026-11-11 from tag/source `v0.8.0` / `819286a` (application code `0edde77`), PR #27. Known business-tone failures remain disclosed/experimental/off by default; release acceptance is not a semantic quality pass. Fresh clean Release arm64, signed host/helper/Sparkle, mounted DMG/layout/background, no bundled weights and real installed-Gemma Release helper smoke passed. Local governance passed; hosted regressions/Debug/actual native checks passed ([42891053801](https://github.com/kestgalax/carrottype/actions/runs/42891053801), [42891040649](https://github.com/kestgalax/carrottype/actions/runs/42891040649)); private hosted AIDOS explicitly skipped. Signed ZIP/feed and downloaded draft/public artifacts passed digests, signatures, lengths, identity/URLs; anonymous latest feed/archive match. Isolated A29→B30 install and negative cases passed; public native Sparkle probe found 0.8.0 from isolated build-29 metadata without installation. No user app/profile/model replacement or private-key export. Full independent device/TCC/VoiceOver/network and Qwen comparison remain unverified. Hashes: `docs/github-release-notes-v0.8.0.md`. Stop feature iteration per maintainer; collect feedback, no next stage selected; GigaAM stays deferred.

Final checks/logs: `/tmp/carrottype-0.8.0-release-build.log`, `/tmp/ct080-package-release.log`, `/tmp/ct080-prepare-update.log`, `/tmp/ct080-draft-verify.log`, `/tmp/ct080-public-verify.log`, `/tmp/ct080-public-probe.log`. Release app: `dist/.builds.noindex/CarrotType-0.8.0-Release/CarrotType.app`; DMG `dist/CarrotType-0.8.0.dmg`; signed assets under `dist/.builds.noindex/updates-0.8.0/`. The Debug and Release share build 30: a running 0.8.0 Debug does not see Release as a newer build; use the release DMG for this transition. Older clients can use the in-app update.

## Maintainer acceptance / release gate

Maintainer explicitly accepted the delivered first-sentence Debug and instructed «ок, пока остановимся, хорошо получилось, давай релизить». Manual/publication gate satisfied for current 0.8.0 (30), application source 0edde77. Individual full device/TCC/VoiceOver checks were not enumerated. Retain disclosed experimental business tone, off by default; acceptance is a product decision to ship the present scope, not proof of four-rule/model semantic reliability. Earlier “not release-ready/no authorization” entries are historical. Clean Release/signature/remote-asset/CI gates still apply.

## Current: first-sentence lowercase Debug

App: `dist/.builds.noindex/CarrotType-0.8.0-First-Lowercase/CarrotType.app`. Quit the previous instance before opening this one. Version/build 0.8.0/30 unchanged; existing development signature deep/strict checked. No new ZIP: earlier archives predate this control. Installed app and potentially running earlier review bundles remain untouched.

Focused manual check: disable full-prose lowercase, enable **Первое предложение со строчной буквы**. `Привет, Анна. Проверим CarrotType.` must become `привет, Анна. Проверим CarrotType.` in trial and ordinary dictation. With full-prose lowercase enabled, the first-letter switch is redundant/disabled while its preference is retained. Protected code/link starts remain unchanged.

Verification: `/tmp/ct080-first-letter-build.log` arm64 Debug succeeded; `/tmp/ct080-first-letter-rules.log` covers migration/default/persistence, RU/EN, quotation/newline/emoji/digits, protected starts, idempotence, combined controls, precedence and Off/Light/fallback. Actual AppState checks are recorded in `/tmp/ct080-first-letter-native.log`. No model prompt/weights/runtime/transform change, so prior tone failures remain open; not release-ready or authorized for publication. Prior-source d02c1e4 hosted CI passed: [42888614542](https://github.com/kestgalax/carrottype/actions/runs/42888614542), [42888536100](https://github.com/kestgalax/carrottype/actions/runs/42888536100). Addition-source hosted CI is separate/pending.

## Earlier: exact-control rework Debug

Branch `feat/deterministic-formatting-0.8` (main-based, earlier 0.8 work retained). **R1/R2 implemented for manual review; business-tone acceptance failed/open. Not release-ready or published.** The older delivery descriptions/checklists below are historical and superseded by this section.

App: `dist/.builds.noindex/CarrotType-0.8.0-Rules-Fix/CarrotType.app`. Quit the earlier Debug instance, then open this .app directly; no installation/replacement was performed. ZIP: `dist/CarrotType-0.8.0-30-Rules-Debug.zip`; SHA-256 `dd2abeccc9993fa91c0b82a66dde9178cdbbbd8f0ab5c2bec706639c4f85a31b`. Same 0.8.0/30 identity and existing development signing/trust. Existing model/settings files preserved; new controls default disabled/empty. Older free text was not parsed or silently moved into switches.

### Проверить только изменённое

1. General → точные настройки: удалять `ну`, включить строчные и отсутствие последней точки. В режиме Off проверить `Ну, Нам нужен Отчёт. Это Последняя Фраза.` → `нам нужен отчёт. это последняя фраза`. Использовать новые элементы управления; старые строки «Мои правила» для этой пробы не нужны и при Off не выполняются.
2. На Gemma повторить пробу: точные настройки должны сохраниться и при отклонении модели; статус отдельно сообщает, что произошло с моделью/стилем. Деловой стиль пока экспериментальный: на предоставленном тексте известен отказ проверки, не ожидайте исправления всего сценария.
3. Одна обычная диктовка в поле ввода с теми же точными настройками: вставка работает, после отмены проверки приложение не остаётся занятым.

### Verification and limits

- Final source build: `/tmp/ct080-rework-final-source.log`, arm64 Debug `BUILD SUCCEEDED`. Signed .app deep/strict verified; bundled identity/version/notes and extracted ZIP verified separately.
- Exact rules: `/tmp/ct080-rework-verified-rules.log`; legacy preferences, boundaries/protected prose, final punctuation/decimals/abbreviations, idempotence, success/fallback/empty/Off and tone status pass. Setup, reliability/helper transport and session/streaming regressions passed during this rework.
- Actual native AppState: `/tmp/ct080-rework-final-native.log`; legacy model/bindings/Storage, transform localised-error vs dictation typed errors, repeated System-theme transitions/no remount, exact controls in Off/Light/failing Gemma, gate/cancel/busy and no clipboard/history/stats mutation pass.
- Production offscreen RU/EN light/dark Settings/General/rules/model/notes/Capsule rendered, relevant rules layout inspected; `/tmp/ct080-rework-ui/`. This is not an interactive device/TCC/VoiceOver walkthrough. Existing outer scrollbar policy unchanged.
- Opt-in real Gemma AppState observations: `/tmp/ct080-rework-quality-final.log`; five synthetic cases: unchanged wording, two rejections, two edited outputs. No semantic PASS inferred from generation. [Detailed quality limits](2026-11-10-formatting-quality-0.8.0.md). Private supplied text was evaluated only locally and temporary source/logs removed; no downloads or model change. Qwen absent, not evaluated.
- Local governance validate/trace/review passed. Hosted final-source CI pending; verify its result before any later release. No tag, Release, appcast change or installed-app replacement. Full 0.8 acceptance/publication still pending.

## Earlier 0.8 diagnostic history

Status: implemented on `feat/formatting-rules-theme-0.8`, signed Debug for maintainer review. **Not published**; stable remains 0.7.0. No 0.8.0 manual acceptance/publication authorization yet. [Task/P1–P4](specs/tasks/dictation-rules-and-theme.md), [ADR-018](decisions/ADR-018-dictation-rules-and-cleanup-catalog.md).

## Коротко проверить вручную

1. **Основные → правила:** выберите Gemma или Qwen3 0.6B, откройте «Проверить на тексте». Сравните «эм привет как дела» с включённым/выключенным удалением запинок. В «Мои правила» задайте «Пиши название приложения керроттайп как CarrotType» и проверьте «сегодня мы проверяем керроттайп». Затем одна обычная диктовка в поле ввода: вставка работает; перевод/Custom остались отдельными действиями.
2. **Тема:** System → Light → Dark, затем перезапуск. Выбор сохраняется, язык независим; окно/Details/«Что нового»/Capsule читаются. В System смена темы macOS подхватывается. Светлая/тёмная принудительные темы не должны следовать смене macOS.
3. **Безопасность результата:** проба «я не согласен на 15 процентов напиши Марии до 17:30» сохраняет число/отрицание (возможен честный fallback на Light). Отмена пробы не оставляет приложение занятым. В новом выборе моделей только Qwen/Gemma; старый Smart+, если уже был активен/в действии, продолжает работать. Ничего удалять для проверки не нужно.

Модель может не выполнить предпочтение: Gemma в синтетических примерах не всегда применяла самоисправление или разбиение на абзацы. Это не жёсткие текстовые преобразования. При обнаруженной потере чисел/обёрток/кода результат отклоняется целиком и применяется Light; факт fallback виден в пробе и обычной диктовке. Проверки ограничены и не доказывают сохранность всего смысла.

## Build and local verification

- arm64 Debug via pinned resolved packages/Xcode 27: `BUILD SUCCEEDED`; version/build 0.8.0/30. Source identity/trust/settings paths unchanged. Signing: existing self-signed CarrotType Development, **not Developer ID/notarized**.
- Current delivery app (UI fixes + formatting diagnostic): `dist/.builds.noindex/CarrotType-0.8.0-Formatting-Review/CarrotType.app`; archive: `dist/CarrotType-0.8.0-30-Debug.zip`. No replacement/launch of `/Applications/CarrotType.app`, user settings/model/stat roots unchanged. Build/test bundles kept in noindex/temporary locations to avoid Spotlight duplicates.
- `verify-formatting-rules.sh`: real rule persistence/corruption/Unicode bound/snapshot/dispatch, tokenizer-budget arithmetic/context limits, real Light meaningful words/newlines/fenced-code/empty handling, protected-literal validation, v3 purpose separation, theme persistence/system/invalid fallback and independent language key.
- `verify-formatting-app.py --build-log <successful non-cached Debug log>`: actual AppState/ModelManager against built Debug dylib, separate temporary signed bundle/defaults/model/stat root, no registered hotkeys/mic. Caught and fixed legacy-ready status being incorrectly hidden by the non-downloadable guard. Checks restored legacy active mode/binding-specific availability/no new recommendation/Storage; actual theme/rules persistence; trial admission/lease/result/fallback/cancel/busy admission; clipboard changeCount/history/stats unchanged. Helper fixture is invalid/outside its production jail, so fallback check intentionally performs no model inference.
- Production lifecycle, reliability, setup/formatting, Ultra migration/storage, update gate/signature, release-notes, catalog and brand checks passed. No new dependency/model revision/engine/network sink or trust change. Hosted CI evidence is recorded below once available; local checks do not stand in for a hosted result.
- Actual production SwiftUI rendered offscreen in RU/EN, light/dark, Settings minimum 720×520, General/Models/notes/rules and Capsule. Layouts inspected; no interactive/VoiceOver/device/TCC/system-theme walkthrough claim. Evidence under `dist/.builds.noindex/CarrotType-0.8.0-Native-Review/`.

## Model evidence and limits

Synthetic developer-authored texts only; existing installed pinned Gemma 4 E2B read locally, no downloads/user dictations. `scripts/evaluate-formatting.py` + `scripts/fixtures/formatting-quality.json` provide reproducible helper-only opt-in evaluation. Final observations: `dist/.builds.noindex/CarrotType-0.8.0-model-eval-final.json`; [quality notes](2026-11-10-formatting-quality-0.8.0.md). Each helper call cold-loads/exits; timings are single observations, not comparative latency/RAM benchmarks.

The first verbose prompt copied the transcript; shortened direct instructions improved hesitation/punctuation and custom-term behavior. Real examples still exposed model losses (15 dropped, outer quotes/fences removed, Cyrillic introduced into English); conservative checks now reject these outputs to visible Light fallback rather than inserting them. Inner quoted speech and question-as-data examples retained meaning; Translate regression produced the English translation independently of rules. Context-overflow example rejected before generation. Self-correction/paragraph compliance remains imperfect and is explicitly a quality limitation.

Qwen3 0.6B is absent: no hidden download, no Qwen/Gemma quality/latency/RAM comparison claimed. Full long-output runtime, independent TCC/device, accessibility, actual update installation and network audit were not rerun for this change; production bounded-output/cancellation/update regressions cover controller behavior only. GigaAM stays deferred. Maintainer manual review and separate release instruction remain required.

## Delivery integrity

Final local signed Debug archive SHA-256: `e9e90e28ed358e09e4ff650dc4dcfc23f2518bb6068ae298200b5934409506ef`. Deep/strict signature verification and bundled version/notes/catalog/MLX resources checked. Local governance validate/trace/review passed; [implementation review and residual risks](reviews/2026-11-10-dictation-rules-theme.md).

PR: [#26](https://github.com/kestgalax/carrottype/pull/26), draft for Debug review. Initial hosted production regressions passed; clean Debug compile was still running when a final local sign/percent-number guard refinement was made. The final signed Debug was rebuilt, real native checks and numeric-sign/percent regressions passed; final-source hosted CI is pending, not claimed successful. Check current PR status before any release. Hosted AIDOS is explicitly skipped without private tooling; local validate/trace/review passed.

## System-theme correction after maintainer feedback

The maintainer observed forced Light/Dark working but returning to System not changing the rendered theme. Isolated native reproduction confirmed a stale SwiftUI environment with simultaneous NSApplication appearance and preferredColorScheme: native appearance reverted to inherited Dark, but SwiftUI stayed Light. Removing the duplicate SwiftUI override restored the actual environment; application appearance alone is the authority. No Settings remount or preference migration.

Regression now checks the actual native Settings host's SwiftUI environment, window inheritance and mount count for repeated Light→System/Dark→System/Light→Dark→System, rather than merely asserting NSApp.appearance=nil. Local Debug/native/rules checks and signing rerun. The new app is in a separate noindex Theme-Fix folder to avoid replacing the previous running Debug bundle. Quit the old instance before launching it. Full OS-wide appearance toggling remains manual; the test does not alter global macOS settings.

Original final-source hosted CI completed successfully: [42868789703](https://github.com/kestgalax/carrottype/actions/runs/42868789703), source 6eae745; hosted governance explicitly skipped, local governance passed. Fix-source hosted CI is separate/pending. Manual recheck and publication authorization remain pending.

## Outer scrollbar feedback

Maintainer explicitly requested hiding the window-wide scrollbar. All seven Settings Forms now use `.scrollIndicators(.never)` (the `.hidden` value left the track visible with the current native preference); nested text editors explicitly retain automatic indicators. A native probe confirmed never hides the outer NSScrollView indicator while the nested NSTextView scroller stays enabled. Final isolated production RU/EN/light/dark render/inspection checks outer scrollers disabled and content offset still movable, then restores position for screenshots. No new persistent test suite for this reversible visual change; Debug build and actual offscreen/native inspection suffice. Physical wheel/trackpad/keyboard interaction remains for manual check.

Theme-fix hosted app/native checks passed for source 7d5f84b: [42874592078](https://github.com/kestgalax/carrottype/actions/runs/42874592078). Scrollbar-source hosted CI is separate/pending. New signed UI-Review copy avoids replacing the potentially running Theme-Fix copy. Quit the old instance before launching it; no installed-app/model/settings change.

## Gemma four-rule review

Maintainer supplied the rules and a message for local evaluation through actual AppState.runFormattingTrial (separate temporary defaults/stat root, read-only installed Gemma, no microphone/clipboard/history/stats writes). [Findings](2026-11-10-formatting-quality-0.8.0.md#maintainer-custom-rule-diagnostic-gemma-actual-text-trial): rule delivery works, but business/combined compliance does not meet a deterministic-rule quality bar. Final supplied-message run preserved both questions, lowercased and removed the last full stop; no reliable business rewrite. Casing-only synthetic example still lost other punctuation. A numeric synthetic combination used Light fallback. No complete four-rule pass claimed.

Clarified prompt priority and explicit-only tone editing, retained literal/no-custom framing, discarded contaminating few-shot variants, added conservative existing-question-mark-loss rejection and actual-mode/prominent fallback display. Actual native AppState/theme/trial, rules/intent guards and setup/formatting checks passed; Debug rebuilt/signed and archive verified. Generic model/style acceptance remains open. This is a safer and clearer diagnostic, not a claim of solved business style. No raw maintainer message is committed; synthetic counterparts extend the opt-in corpus. No publication authorized.
