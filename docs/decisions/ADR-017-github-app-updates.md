# ADR-017: Signed GitHub application updates with Sparkle

## Status

Accepted — implements the maintainer-approved 0.5.0 U1–U3 plan; 0.5.0 shipped on 2026-11-10 after Debug delivery and explicit publication authorization. Future versions still require their own Debug/manual gate.

## Context

Updating currently requires a manual DMG download. Preserve the local dictation pipeline and all existing functions. The current self-signed distribution does not have Developer ID/notarization (ADR-011); update authenticity therefore needs a separate persistent signing key. This ADR extends the closed network sinks and supersedes ADR-011's deferral of Sparkle.

## Decision

- Add the direct Sparkle 2.10.1 binary SPM dependency at an exact version; commit its resolved revision. Its manifest verifies the binary archive SHA-256. Use its standard native update UI, installer and signature verification instead of a custom downloader/installer.
- Stable feed: `https://github.com/kestgalax/carrottype/releases/latest/download/appcast.xml`. Archives use immutable version-specific GitHub Release URLs. Keeping the feed as a release asset avoids another hosting account/deployment. Drafts and prereleases must never replace stable; upload archive before feed, verify assets before making a release latest. First updater-enabled installation is manual.
- Permit HTTPS requests only for update metadata/inline release notes and application archives on the project GitHub Releases, including GitHub's HTTPS release-asset redirects/CDN (`release-assets.githubusercontent.com`, `objects.githubusercontent.com`). These are downloads, never audio/transcript uploads. No analytics, system profile or JavaScript in release notes. Model download policy remains separate.
- Automatic checks default off, enabled explicitly in Settings. Background download/install-on-quit is a separate opt-in Sparkle setting, default off. No silent forced restart. Native UI reports availability, no update, download/signature/network errors.
- Require Ed25519 signatures on archives and verify before extraction (`SUVerifyUpdateBeforeExtraction`). Require signed appcasts, with no signature failure expiry (`SURequireSignedFeed`, expiration 0); inline release notes share the feed signature. Embed only the public key. Store the persistent private key in the macOS login Keychain under a project-specific account. Never put private key material in the repository, logs, artifacts or CI. Signing scripts fail closed when keys are missing.
- Back up the signing key to maintainer-controlled encrypted offline storage using Sparkle's documented export/import procedure; never automate export into the workspace. Loss without backup means a manual reinstall with a new key (no unsigned fallback for the current self-signed app). A restored key must reproduce the embedded public key before release. Future Developer ID key-rotation options require a documented procedure.
- Reserve an operation before scheduling dictation/transform tasks; hold the reservation across recording, STT, formatting, paste, cancellation and mute restoration. Defer Sparkle relaunch until idle. Lock new operations atomically before invoking the postponed install handler; also check at application termination as a final guard for Sparkle paths that omit postponement. Unlock if installation aborts. Downloading/checking does not block dictation.
- Keep models, settings and local stats outside the app bundle. Test two isolated real app builds/feed before release; report native install/TCC tests honestly if manual verification is still pending. EdDSA authenticates updates; it does not notarize the app or guarantee persistence of TCC grants. Keep Gatekeeper instructions and manual DMG fallback.

## Alternatives

- GitHub Pages appcast: viable, but an extra deployment and separate publication ordering; release asset hosting is sufficient for one stable channel.
- Custom GitHub downloader and bundle replacement: rejected; duplicates signature, installer and relaunch logic.
- Automatic checks enabled for everyone or cloud telemetry: conflicts with explicit opt-in/local privacy.
- HTTPS alone or temporary signing keys: rejected; no durable update authenticity.
- Wait for notarization: unnecessary for implementation, but actual self-signed upgrade/TCC acceptance remains a release gate.

## Consequences

0.5.0 adds one dependency and one narrowly defined network sink; offline dictation remains independent. Staging uses separate app identity and signed local feed, never a dummy public release or replacement of the user's installation. Full native upgrade/TCC checks and each version's Debug manual confirmation remain required before publication.

Official sources checked 2026-11-10: [setup](https://sparkle-project.org/documentation/programmatic-setup/), [configuration](https://sparkle-project.org/documentation/customization/), [publishing](https://sparkle-project.org/documentation/publishing/), [2.10.1 source/API](https://github.com/sparkle-project/Sparkle/tree/2.10.1).
