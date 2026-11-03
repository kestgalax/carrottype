# Storage pane UX — packages + download cache

Date: 2026-10-30  
Status: Approved (owner)  
Branch target: `feat/storage-cache-ux` (from `main` / post-v0.3.7)

## Goal

Redesign Settings → **Storage** so it equally supports:

1. **Inventory** — which installed packages are Active vs Unused and how much each uses.
2. **Freeing disk** — bulk remove unused packages **and** clear CarrotType-related Hugging Face download cache (without confusing the two).

Per-package **Delete** stays on **Models** (not duplicated on Storage).

## Decisions (from design dialogue)

| Topic | Choice |
|-------|--------|
| Primary jobs | Inventory **and** free space (equal) |
| Per-package Delete | **Models only**; Storage = bulk actions |
| Clear-cache scope | Only HF hub folders for repos in the CarrotType catalog |
| Layout | **Two sections** (Installed packages / Download cache) |

## Current baseline

Today (`StorageSettingsPane`):

- One section: total “Used by models”, per-package rows (Active/Unused + % share), **Delete unused packages**.
- Total = Application Support package footprints only (no HF cache).
- Models pane already has Delete on Ready STT/formatting packages.
- MLX Hub downloads also populate `~/.cache/huggingface/hub`; app Delete removes only Application Support dirs — re-download feels “instant” from cache (expected; ADR-015 / supply-chain note).

## Design

### Section 1 — Installed packages

- **Header:** Installed packages (L10n).
- **Total row:** bytes under Application Support `carrottype/models` (same measurement as today’s `totalInstalledBytes` / footprints). Label clarifies these are **installed packages**, not download cache.
- **Rows:** display name, size, Active / Unused, % of **package** total (unchanged Active rules: current STT, selected formatting package if used, any transform-binding model).
- **Empty:** caption when no packages on disk.
- **Action:** destructive **Delete unused packages** — disabled when none unused.
- **Footer:** explain Active; note that deleting a package in Models removes that install only and does **not** clear download cache.

### Section 2 — Download cache

- **Header:** Download cache (L10n).
- **Size row:** sum of on-disk sizes for Hugging Face hub folders that correspond to catalog `hubRepoID` / Hub URLs used by CarrotType packages (path pattern under `~/.cache/huggingface/hub/models--org--name`, plus `HF_HOME/hub` if set — same roots as progress estimation today).
- **Do not** include unrelated repos under `hub/`.
- **Do not** delete Application Support package dirs from this action.
- **Empty / zero:** secondary copy that cache is empty; clear button disabled.
- **Action:** destructive **Clear download cache** → **confirmation** alert (title + body: next Download may need network again; installed Ready packages stay until deleted separately).
- **Footer:** cache speeds re-download after Delete; clearing frees space but does not uninstall active models.

### Out of scope

- Per-row Delete on Storage.
- Wiping entire `~/.cache/huggingface` (all apps).
- Dedicated FluidAudio / Whisper temp-cache UI (unless already part of package footprint).
- Changing Models Delete behavior beyond copy that points users to Storage for cache.
- Notarization / version bump unless shipped as its own mini-release.

## Implementation sketch

- `ModelManager` (or small helper): `downloadCacheBytes(forCatalog:)` + `clearDownloadCache()` removing only matched `models--*` dirs; refresh sizes after clear.
- `StorageSettingsPane`: two `Section`s; confirmation via `.alert` / `confirmationDialog`.
- L10n EN/RU for new strings; update `docs/specs/ux-setup-status.md` Storage bullets; short roadmap note; optional one-liner in `docs/security/supply-chain.md`.
- Verification: Debug build; manual — Delete package leaves HF cache; Clear cache reduces size and leaves Ready installs; unused delete unchanged.

## Traceability

- Product: local models on disk, explicit user control (product intent / Storage UX).
- Follow-up to ADR-015 / Secure Coding Storage discussion (cache vs package delete).
- Spec baseline: `docs/specs/ux-setup-status.md` § Storage.
