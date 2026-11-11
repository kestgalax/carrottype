# ADR-019: Opt-in main app launch at login

## Status

Accepted for 0.8.1 implementation: maintainer requested a small patch with startup after restart/power-on. Debug/manual acceptance and separate publication instruction remain required.

## Context

The maintainer wants the menu-bar app available after restarting or powering on a Mac. Startup must remain explicit, reversible and visible in macOS, without automatically recording or registering disposable development builds.

## Decision

Use the native macOS 13+ `SMAppService.mainApp` within the existing macOS 14+ stack. Explicitly register/unregister only on a user toggle; never on init, launch, refresh, update or model selection. No separate helper/LaunchAgent/daemon, login shell scripts or third-party dependency. Login means after the user signs in, not before login or microphone recording at boot.

System status is authoritative; do not persist a second desired-state Boolean. Preserve externally configured status. Refresh when General appears and when the app becomes active; report enabled/pending approval/not registered/unavailable, with native Login Items settings action and localised failure feedback. Pending approval is registered/requested but is not reported as an active startup guarantee.

Allow new registration only from an application installed beneath `/Applications` or the user's `~/Applications`, with resolved path boundaries. Explain this restriction for review copies/DMG/translocation to avoid registering a disposable Debug path. Allow explicit unregistration of an existing item even from an uninstalled copy. No installation or login-item mutation in automated tests; inject the system adapter, test policy/errors with fakes and provide a signed Debug for manual installed-app/relogin checking.

No runtime/engine/model/network/trust changes. No automatic recording, model load/download, preference reset, installation replacement or changes to other login items. Keep the existing menu-bar application and first-run behavior.

## Sources

- [Apple SMAppService](https://developer.apple.com/documentation/servicemanagement/smappservice)
- [Main app service](https://developer.apple.com/documentation/servicemanagement/smappservice/mainapp)
- [Register](https://developer.apple.com/documentation/servicemanagement/smappservice/register())
- Xcode 27.2 SDK `ServiceManagement.framework/Headers/SMAppService.h` inspected locally (code signing requirement, status and register/unregister semantics).

## Alternatives

- A saved Boolean plus automatic registration on each launch: rejected; can override a user's external macOS choice and hide registration failures.
- Custom LaunchAgent/plist, daemon or third-party startup package: unnecessary for the main application; use the supported native service in the existing stack.
- Register a temporary Debug/DMG path: rejected; that copy may disappear or start an obsolete build on subsequent login.

## Consequences

Actual restart/logout behavior, system approval and self-signed installed-app registration need maintainer manual verification; do not infer success from mock tests. macOS owns the registration and may require approval. This is opt-in convenience within the current product intent, not a launch-before-login service.
