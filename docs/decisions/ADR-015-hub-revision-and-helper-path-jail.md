# ADR-015: Hub revision pins and cleanup helper path jail

## Status

Accepted

## Context

The 2026-10-30 Secure Coding / OWASP Mobile Top 10 pass found two actionable integrity gaps that fit product intent without App Sandbox or notarization:

1. Whisper ggml downloads already verify optional catalog `sha256`. MLX Hub snapshots (Qwen / Gemma) downloaded via `HubClient.downloadSnapshot` tracked only TLS + Hub “main”, so a silent upstream tip change could alter weights without an app-level pin.
2. `CarrotTypeCleanupHelper` trusted any caller-supplied `modelDirectory` that contained `config.json`, so a same-UID crafted request could point MLX at an unexpected tree.

Unsigned GitHub Release DMGs remain allowed (ADR-011). Notarization stays optional when a Developer ID exists.

## Decision

1. **Catalog `hubRevision` (optional):** Hub-snapshot cleanup packages may declare a Hugging Face revision (prefer full commit SHA). Downloads pass that revision into `HubClient.downloadSnapshot`. After success the host writes `.hub-revision` under the package directory. Ready checks require the marker to match the catalog pin when a pin is set. Existing Whisper `sha256` policy is unchanged (ADR-003).
2. **Parakeet / FluidAudio:** No per-file app SHA in this ADR. Integrity for Parakeet remains SPM pin of FluidAudio + HTTPS; residual risk is documented in `docs/security/`.
3. **Helper path jail:** Before loading weights, the helper resolves `modelDirectory` and accepts it only if it is under `~/Library/Application Support/carrottype/models/` (symlink-resolved, path-boundary safe). Otherwise it emits `modelPathRejected` and exits without inference.
4. **Notarization:** Still optional trust polish (`ops/deploy.md`); prep scripts/docs may exist without claiming notarized builds.

## Alternatives

- **Per-file SHA manifests for every Hub file** — stronger but heavy to maintain for multi-file MLX trees; deferred.
- **App Sandbox** — rejected for MVP; conflicts with Accessibility / global hotkey product shape.
- **Leave Hub on floating `main`** — rejected for Smart/Gemma packages once pins are cheap.

## Consequences

- Catalog schema gains optional `hubRevision`; bundled JSON version bumps when pins are added.
- Users with previously downloaded Smart/Gemma packages may need one re-download so `.hub-revision` appears.
- Security checklist: `docs/security/secure-coding-checklist.md`, supply chain: `docs/security/supply-chain.md`.
