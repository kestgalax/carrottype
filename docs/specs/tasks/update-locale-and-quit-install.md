# Update language and quit-install fixes

## Metadata

- Task ID: update-locale-quit-install
- Title: Make update notes follow the in-app language and make install-on-quit honest and reachable
- Status: Implementation + Debug evidence delivered; no publication in this task
- Target: 0.11.0 (35) Debug bugfix unless Sparkle identity requires a metadata bump

## Traceability

- Product Intent Link: `docs/product-intent.md` — explicit controls, local-first, reliable primary loop
- Roadmap Item: `docs/roadmap.md` — 0.11.0 published; post-release update fixes
- Related ADRs: ADR-017 (opt-in checks, separate download/install-on-quit, no forced silent restart)
- User request: maintainer reported that (1) the changelog/version description ignores the selected language and (2) “download and install on quit” looks broken
- Coordinator refinement: Cursor mail `msg_56ca5c292907` / run `run_8a8e8994d2c8`
- Evidence: `docs/debug-review-update-locale-quit.md`

## Root causes

1. `ReleaseNotes.content(locale:)` looked up `languageCode ?? "en"` with no shared normalization or in-app fallback, unlike `L10n`. A locale without a usable code therefore silently produced English notes even when the app language was Russian.
2. Sparkle selects the localized appcast `<description>` and its own labels from the process preferred localizations (`NSBundle.preferredLocalizations`, app-domain `AppleLanguages`), not from CarrotType’s `AppLanguage`. A system-English/Russian-in-app combination stayed English in the standard update window.
3. The automatic-download toggle is gated by Sparkle’s `allowsAutomaticUpdates`, which is derived from `automaticallyChecksForUpdates` unless `SUAllowsAutomaticUpdates` is set. With opt-in checks off (ADR-017), the toggle was disabled without any explanation, so it looked broken. This is a Sparkle dependency rule, not a self-signed-policy failure.
4. `CarrotTypeApplicationDelegate.applicationShouldTerminate` asked the updater guard first. With a pending install-on-quit and an active operation, it returned `.terminateCancel` and showed an alert, so `prepareForQuit` never drained and Sparkle never reached the install-on-quit handoff.

## Plan

### P1 — language

- Add `AppLanguageCode` as the one normalizer: any `ru*` identifier → `ru`, everything else → `en`, with an explicit fallback when the locale has no language code.
- Use it from `L10n.t` and `ReleaseNotes.content(locale:preferredLanguageCode:)`; keep the English content fallback.
- Keep What’s New on `appState.effectiveLocale` (already true) and add regression coverage for RU, EN, unknown and missing locale codes.
- Bridge the in-app language into the app-domain `AppleLanguages` key so Sparkle’s standard UI/appcast description selection follows CarrotType on the next launch. Only remove that key when CarrotType wrote it, preserving any user-owned per-app language choice. Appcast keeps both `en` and `ru` descriptions; no JS.

### P2 — quit install

- Never cancel a user quit from the updater guard. `applicationShouldTerminate` always goes through `AppState.prepareForQuit`, which drains capture/STT/formatting and replies via `.terminateLater` exactly once.
- Track a pending install-on-quit in `UpdateInstallationGate`; keep Sparkle’s documented `return false` install-on-quit path (installer tool completes after exit) because returning `true` and invoking the immediate handler would force a relaunch, contrary to ADR-017.
- `prepareForTermination` checks the gate is idle, marks the installation, clears a postponed relaunch (a quit is not a relaunch request) and allows termination.
- Explain in Settings that checks, background downloads and install-on-quit are different steps; show why the download toggle is disabled instead of silently disabling it.
- Cover busy-drain, pending install-on-quit, abort reset and termination in the production gate checks.

## Acceptance Criteria

- RU app language shows RU What’s New even if the system locale is English; EN/unknown still fall back to EN.
- Sparkle’s next-launch update window uses the in-app language for both its labels and the localized appcast description; switching back to System restores system behavior.
- A pending install-on-quit survives a busy quit: operations drain, the app terminates, and the staged update can install. A cancelled/aborted update clears the pending state.
- Manual checks and manual install/relaunch remain unchanged. Automatic checks and downloads remain opt-in; no forced restart while the app is running.
- Signed Debug arm64, production regression scripts, evidence document and roadmap/memory updates. No publication, no version bump unless strictly required.

## Verification

- `scripts/verify-release-notes.sh` — language resolution, RU/EN notes, history and corrupt-fallback checks.
- `scripts/verify-app-updates.sh` — gate busy-drain/pending-quit/abort checks plus update asset tests.
- Existing formatting/session/dynamic-island/typing-speed/launch/catalog regressions because `AppLanguage.swift` is shared.
- Signed arm64 Debug under `dist/.builds.noindex/...`; inspect bundle identity/version/signature and run the app checks that do not mutate the installed profile.
- Native Sparkle GUI/TCC interaction is limited to what can be observed without replacing the installed app; document the exact gap.

## Documentation Updates

- `docs/architecture.md` — shared language resolution and updater presentation bridge; quit drain semantics.
- `docs/roadmap.md` — post-0.11.0 bugfix status and next gate.
- `.ai/memory.md` — short durable note.
- `docs/debug-review-update-locale-quit.md` — commands, results, hashes and limits.

## ADR Impact

No new ADR. Follows ADR-017: checks stay off by default, background download/install-on-quit stays a separate opt-in, no forced silent restart, standard Sparkle UI/installer and signed feed retained.
