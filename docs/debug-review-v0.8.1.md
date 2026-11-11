# Debug review — CarrotType 0.8.1 (31)

Status: signed Debug for manual startup review, not published. Branch `feat/launch-at-login-0.8.1` from main d05027a. [Task](specs/tasks/launch-at-login.md), [ADR-019](decisions/ADR-019-launch-at-login.md). Stable remains 0.8.0; no acceptance/publication authorization for this patch.

App: `dist/.builds.noindex/CarrotType-0.8.1-UI-Review/CarrotType.app`. No ZIP needed to launch it. Quit the current instance, move this app to Applications and open it there to test registration. Nothing was installed, quit or registered automatically by the agent; preserve a copy of the stable app if needed for rollback. The non-installed review copy intentionally disables new registration and explains why in contextual help.

## Короткая ручная проверка

1. Откройте приложение из «Программ». В самом низу Основных включите «Запускать при входе в macOS». Если требуется разрешение — нажмите кнопку настроек macOS и разрешите запуск; вернитесь и проверьте статус.
2. Перезагрузите Mac или выйдите/войдите: CarrotType должен появиться в строке меню, без автоматической записи. Одна обычная диктовка подтверждает прежнюю работу.
3. Выключите автозапуск: после следующего входа приложение не должно запускаться именно через эту настройку. Независимое macOS «Открыть окна повторно при входе» может восстановить открытое приложение — для чистой проверки предварительно завершите CarrotType.

## Verification and limits

- arm64 Debug build `/tmp/ct081-debug-build.log`: BUILD SUCCEEDED, pinned packages; version/build 0.8.1/31, existing development identity, no notarization/trust change.
- `verify-launch-at-login.sh`, `/tmp/ct081-login-checks.log`: explicit register/unregister, no init/refresh mutation, idempotence, pending approval, settings action, external changes, both error paths and installed-path guard with fakes. No real startup/System Settings changes.
- Native production AppState/ModelManager/theme/trial/error checks: `/tmp/ct081-native-checks.log`; no registration in this path. Release-notes validation `/tmp/ct081-notes-checks.log`.
- Signed app deep/strict verification. No user app/model/profile or other login-item replacement/removal, no microphone/network/model inference required by the change.
- Actual self-signed SMAppService registration, system approval, installed app after restart/logout and disabling remain manual/unverified. Do not infer them from injected tests or a successful build. Initial-source hosted app CI passed (42977909726, 42977969226); UI-revision CI follows push. Local governance passed. Publication only after maintainer acceptance and instruction.

## UI feedback revision

Moved startup to the very bottom of General and removed persistent explanatory hints at the maintainer’s request. Installation guidance is available on hover for a non-installed review copy; conditional approval/errors and the native settings action remain. Service/registration behavior is unchanged. Refreshed arm64 Debug build: `/tmp/ct081-ui-build.log`; copied to the UI-Review path above and signed/deep-strict verified (`/tmp/ct081-ui-sign.log`). Local validate/trace/review passed. No new tests for this presentation-only change; initial startup fake-policy checks remain applicable. Visual placement and actual login behavior await manual confirmation. No publication authorization.
