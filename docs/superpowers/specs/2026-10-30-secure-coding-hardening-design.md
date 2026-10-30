# Secure Coding hardening (OWASP Mobile Top 10 pass)

Date: 2026-10-30  
Status: Approved (owner) — design dialogue; notarization = prep only (no Developer ID yet)  
Branch target: `feat/secure-coding-hardening` (from `main`)

## Goal

Close the actionable gaps from the 2026-10-30 security audit mapped to OWASP Mobile Top 10 / Secure Coding Guidelines, without changing product intent (local-first dictation, unsigned DMG still valid per ADR-011).

## Constraints

- No Apple Developer ID / notary credentials available → **notarization is documentation + script prep only**; do not claim notarized builds.
- Do not introduce App Sandbox (breaks Accessibility / global hotkey product shape).
- Do not add cloud STT/cleanup or new network sinks (`.ai/constraints.md`).
- Catalog / integrity policy changes need ADR coverage (amend ADR-003 or small ADR-015).
- No commits of secrets, `.env` with real passwords, or signing material.

## Approach (chosen)

**Hardening + docs** (not docs-only, not sandbox rewrite):

1. Secure Coding checklist + supply-chain note under `docs/security/`.
2. Helper `modelDirectory` path jail.
3. Optional `hubRevision` pin for MLX Hub snapshots (+ marker verify).
4. Clipboard restore timing + retain-clipboard copy clarity.
5. Notarization prep scripts/docs without running notary.
6. Roadmap / constraints / deploy updates.

## Workstreams

### A. Documentation — Secure Coding checklist

Create `docs/security/secure-coding-checklist.md`:

- One section per OWASP Mobile Top 10 category (same labels as the audit / Secure Coding UI).
- For each: **Status** (`OK` / `Risk` / `N/A`), **Evidence** (paths), **Residual risk**, **Mitigation done or deferred**.
- Link to related ADRs (`ADR-003`, `ADR-009`, `ADR-011`) and `.ai/constraints.md`.

Create `docs/security/supply-chain.md`:

- Direct SPM deps and why they exist.
- Closed network sinks list (mirror constraints).
- Whisper `sha256` vs Hub `hubRevision` vs Parakeet/FluidAudio residual risk.
- How to bump pins (`Package.resolved`) and re-audit.

### B. Helper path jail

In `CarrotTypeCleanupHelper/main.swift` (before loading MLX):

1. Resolve `request.modelDirectory` to a standardized absolute path (`resolvingSymlinksInPath` / `standardizedFileURL`).
2. Allowed root: `~/Library/Application Support/carrottype/models/` (same layout as `ModelManager`).
3. Require: resolved path is equal to root **or** a strict subdirectory of root (prefix check with path-separator boundary; reject `..` escapes).
4. On violation: emit failure code `modelPathRejected` (add to `CleanupHelperResponse` error codes) and exit without loading.

Host already passes package dirs under that root; jail is defense-in-depth if helper is invoked standalone or host is compromised partially.

Shared helper (optional small util in Shared or duplicated resolve in helper only — prefer one small function in helper to avoid expanding Shared surface unless tests need it).

### C. Model integrity — `hubRevision` for MLX

Extend catalog schema (`ModelCatalog.json`, `ModelTypes`, `BundledModelCatalog`):

- Optional `hubRevision: String?` — Hugging Face git revision (prefer **full commit SHA**).

Download path (`QwenCleanupPackage.downloadPackage`):

- Pass `revision:` into `HubClient.default.downloadSnapshot` (API already supports it; default today is effectively `main`).
- When catalog has `hubRevision`, use it; else keep `"main"` and document residual risk in checklist.

After successful download:

- Write marker file `.hub-revision` containing the pinned revision string (or `"main"` if unpinned).
- Ready check: if catalog `hubRevision` is set, require marker match; mismatch → not ready (user can re-download).

**Out of scope this pass:**

- Per-file SHA for multi-file Parakeet/MLX trees.
- Changing FluidAudio Parakeet download API (pin remains SPM `0.17.7` + residual TLS/Hub trust) — documented only.
- Whisper path unchanged (existing `sha256`).

Pin concrete commit SHAs for current Qwen/Gemma catalog entries at implementation time via Hugging Face Hub API (`/api/models/{repo}/revision/main` or equivalent).

ADR: short **ADR-015** (or ADR-003 amendment) — catalog may carry `hubRevision` for Hub snapshots; Whisper keeps `sha256`.

### D. Clipboard hardening + copy

- Reduce default restore delay in `TextInsertionService` from `0.35` → `0.20` seconds (still enough for ⌘V consumers; shorter pasteboard window).
- `SelectionTextService` clipboard fallback: keep restore; align delay if longer than insert path.
- Update `hotkey.retain_clipboard_footer` (EN/RU): note that retained text stays on the system pasteboard (other apps/clipboard tools can read it) — explicit over magic.

No AX set-value rewrite this pass (large UX risk across apps).

### E. Notarization prep (no credentials)

- Expand `ops/deploy.md` “Follow-up: Developer ID + notarization” into a checklist: cert install, `SIGN_IDENTITY`, hardened runtime notes, `notarytool` store-credentials (Keychain profile name only), submit/staple/assess, Release-notes gate.
- Add `ops/notarization.env.example` with placeholder keys only (`APPLE_ID=`, `TEAM_ID=`, `NOTARY_PROFILE=carrottype-notary`, `SIGN_IDENTITY=Developer ID Application: …`).
- Optional thin script `macos/scripts/notarize-dmg.sh` that:
  - Requires env / keychain profile;
  - Submits + waits + staples given DMG path;
  - Fails clearly if profile missing (no secrets in repo).
- Do **not** change ADR-011: unsigned Release remains allowed.
- Do **not** enable `--options runtime` resign in release script until Developer ID is real (existing comment about library validation stays).

### F. Governance / roadmap

- Update `.ai/constraints.md` trust/supply-chain pointers to new security docs.
- Update `docs/roadmap.md`: security pass / checklist done; notarization still optional when credentials exist; next focus accordingly.
- No version bump / GitHub Release required for this hardening pass unless owner asks.

## Non-goals

- App Sandbox / MAS distribution
- Certificate pinning to Hugging Face
- Encrypting model weights at rest
- Obfuscation / anti-RE (MIT)
- Full offline network audit (Little Snitch) as CI gate
- Actually notarizing a build

## Verification

- Debug build of host + helper after Swift changes.
- Manual / unit-style check: helper rejects path outside Application Support models root (e.g. `/tmp/evil` with fake `config.json`).
- Catalog decode still works with and without `hubRevision`.
- Docs links resolve; roadmap reflects completion.
- Skipped: real `notarytool` submit (no credentials) — residual risk stated in completion report.

## Traceability

- Audit: OWASP Mobile Top 10 Secure Coding pass (2026-10-30)
- Product: local-first privacy (`docs/product-intent.md`)
- ADR-003 / ADR-009 / ADR-011 + new ADR-015 (hubRevision)
- Roadmap: deferred security pass → executed; notarization remains optional polish
