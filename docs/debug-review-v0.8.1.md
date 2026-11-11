# Debug review — CarrotType 0.8.1 (31)

Status: revised signed Debug accepted for publication; 0.8.1 stable published. Branch `feat/launch-at-login-0.8.1` from main d05027a. [Task](specs/tasks/launch-at-login.md), [ADR-019](decisions/ADR-019-launch-at-login.md). Maintainer explicitly authorized publication after revised Debug delivery; individual startup/reboot results were not enumerated.

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

Moved startup to the very bottom of General and removed persistent explanatory hints at the maintainer’s request. Installation guidance is available on hover for a non-installed review copy; conditional approval/errors and the native settings action remain. Service/registration behavior is unchanged. Refreshed arm64 Debug build: `/tmp/ct081-ui-build.log`; copied to the UI-Review path above and signed/deep-strict verified (`/tmp/ct081-ui-sign.log`). Local validate/trace/review passed. No new tests for this presentation-only change; initial startup fake-policy checks remain applicable. Visual placement and actual login behavior await manual confirmation. Publication subsequently authorized; see closeout below.

## Publication authorization

After the revised signed Debug was delivered, maintainer instructed «публикуй». This accepts the candidate for publication; individual reboot/approval results were not enumerated. App source is `fe2e9bc`; clean Release/DMG and local/draft/public update verification follow. No authorization for future versions or automatic user-app/login-item replacement.

## Release preflight

Clean Release arm64 BUILD SUCCEEDED (`/tmp/ct081-release-build.log`), inside-out signed. Default DMG creation failed with Resource busy; checksum-verified 0.8.0 installer filesystem was cloned and only the app replaced (`/tmp/ct081-package.log`). Final mounted app/version/helper/shaders/notes/deep signature/no bundled weights and matching ZIP verified. Layout `.DS_Store` SHA256 168249954ca4048d6c8970609563ddb655cc62c7c3ff2189ddc8fb4bce55ed84 and background SHA256 80495495b97af5f0b3dd8312a15a72f7c849f7c16c81d71ad0a4a22b62f8d64c unchanged. Local update signatures passed (`/tmp/ct081-assets.log`); no key export. Isolated candidate-code A30→B31 native install and negative cases passed (`dist/.builds.noindex/updates-0.8.1/results.txt`), not historical-binary/TCC evidence. Hosted final-app CI passed (42983616038, 42983623123); local login/update/notes/governance checks passed, hosted private AIDOS explicitly skipped. Draft/public download gates remain before publication closeout. [Hashes/notes](github-release-notes-v0.8.1.md).

## Publication closeout

Maintainer accepted the revised signed Debug and instructed «публикуй». Stable/latest **0.8.1 (31)** published on 2026-11-11, tag/source `v0.8.1` / `d8e166b` (application code `fe2e9bc`), PR #28. Opt-in native launch at macOS sign-in lives at the bottom of General without persistent hints. Clean Release arm64, signed host/helper/Sparkle, final mounted DMG/resources/metadata/no weights and ZIP/feed signatures passed. Initial DMG creation returned Resource busy; checksum-verified 0.8.0 filesystem template reused with unchanged layout/background. Local governance and hosted final-app regressions/Debug/native checks passed (42983616038, 42983623123); private hosted AIDOS explicitly skipped. Isolated candidate-code A30→B31 install and negative checks passed, not historical-binary or TCC proof. Downloaded draft/public files matched digests/signatures/length/identity/URLs; anonymous latest feed/archive matched. Native isolated build-30 Sparkle probe found the live update without installation. No user installation/profile/model/login-item replacement or private-key export. Individual actual reboot/system-approval results were not enumerated; independent device/TCC/VoiceOver/network checks remain unverified. Hashes: `docs/github-release-notes-v0.8.1.md`; evidence: `docs/debug-review-v0.8.1.md`. Next: collect startup feedback, no further stage selected; GigaAM remains deferred. Later releases retain their own Debug/manual/publication gate.

Draft gate `/tmp/ct081-draft-verify.log`; public gate `/tmp/ct081-public-verify.log`; isolated native probe `/tmp/ct081-public-native-probe.log`. Published assets remain immutable.
