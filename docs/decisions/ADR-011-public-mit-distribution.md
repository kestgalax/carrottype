# ADR-011: Public MIT distribution (portfolio / personal)

## Status

Accepted

## Context

CarrotType shipped as a private invite-only GitHub repo with unsigned DMGs. Product goals do not require App Store distribution, dual-commercial licensing, or registered trademarks. The maintainer may publish the repository for portfolio / open-source visibility without Apple Developer ID notarization. Forks are acceptable; a soft brand ask is enough.

## Decision

1. **License:** application source and project docs in this repository are **MIT** (`LICENSE`). Model weights remain third-party licenses (catalog / ADR-003).
2. **Visibility:** the GitHub repository **may be public**. Public source is not gated on notarization.
3. **Binaries:** GitHub Releases may ship **unsigned** `.dmg` builds. Install UX is Right-click → Open (Gatekeeper). Do not claim notarized / Gatekeeper-clean install without Developer ID + notarization evidence.
4. **Branding:** forks should attribute CarrotType and should not reuse the CarrotType name or app icon as their product brand (README soft ask — not a registered-trademark program).
5. **Out of scope for this ADR:** dual GPL/commercial licensing, domain-only closed-source distribution, Sparkle auto-update, paying for Apple Developer solely to unlock public visibility.

Notarization remains an **optional later** trust improvement (`ops/deploy.md`), not a publish blocker.

## Alternatives

- **Stay private forever** — fine for personal-only use; rejected as the default posture once portfolio visibility is desired.
- **GPL + commercial dual-license** — unnecessary given no commercial lock-down goal.
- **Public only after notarization** — over-blocks portfolio/source visibility.

## Consequences

- Update README, `.ai/constraints.md`, roadmap, and `ops/deploy.md` to match.
- Flipping GitHub visibility to public is a manual step after this documentation lands (`gh repo edit … --visibility public`).
- Historical release notes that say “invite-only” remain archive; new releases follow the public MIT posture.
