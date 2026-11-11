# 0.8.1 — opt-in launch at login

## Metadata

- Task ID: launch-at-login
- Status: signed Debug accepted for publication; release verification in progress

## Traceability

- Product Intent Link: `docs/product-intent.md`
- Roadmap Item: `docs/roadmap.md` — 0.8.1 startup patch
- Feature Spec: `docs/specs/ux-setup-status.md`
- Related ADRs: ADR-002, ADR-019

## Scope

Native `SMAppService.mainApp` toggle at the bottom of General, without persistent descriptive hints, explicit opt-in with authoritative OS state, pending approval/settings action, failure feedback and refresh on appearance/activation. No launch-before-login, separate helper/plist, automatic registration/recording, installation, model/settings reset or other login-item mutation. Register only an installed Applications copy; explicit removal remains possible after moving a registered app. Shared ServiceManagement adapter is injected for pure tests. Version 0.8.1 (31); existing functionality retained.

## Acceptance Criteria

- Init/launch/refresh never register/unregister; saved OS-enabled state is not reset and no shadow Boolean is persisted.
- Explicit toggle registers/unregisters, reflects true status after success/failure, and reports pending approval without implying startup is already approved.
- General refreshes external settings changes on reactivation; native settings action appears for approval/errors.
- Temporary/DMG/review copies explain installation requirement in contextual help and cannot register themselves. Explicit removal of an already registered item remains possible.
- Signed Debug before manual installed-app/login/reboot verification; publication only after separate maintainer instruction.

## Verification

- Check: `scripts/verify-launch-at-login.sh` uses injected fakes for init/no-write, enable/disable/idempotence, approval, external changes, errors and installed-path policy. No automated real service registration or reboot.
- Check: arm64 Debug, release-notes validation, existing real AppState native regression and local governance; self-signed Debug resource/signature verification.
- Check: maintainer manually installs/opens the Debug from Applications, enables startup (approves in macOS if needed), logs out/restarts and confirms menu-bar app, then disables and checks the next login. Record this as unverified until observed/confirmed.

## Documentation Updates

- Update: roadmap, architecture, UX spec, ADR-019, README usage, Debug review and memory; bundled RU/EN release notes/version/build.

## ADR Impact

New ADR required: ADR-019 accepted for opt-in native login-item registration. No new runtime/engine, third-party dependency, network sink or distribution trust change; existing native stack/identity retained.
