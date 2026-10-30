# Secure Coding Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the approved secure-coding hardening pass (checklist docs, helper path jail, MLX `hubRevision`, clipboard copy, notarization prep) without claiming notarized builds.

**Architecture:** Docs under `docs/security/`; defense-in-depth jail in `CarrotTypeCleanupHelper`; catalog `hubRevision` passed to HubClient + `.hub-revision` marker; clipboard restore shortened + retain footer honesty; notarization env example + script that fails closed without credentials.

**Tech Stack:** Swift macOS app, Hugging Face HubClient, XcodeGen, Markdown docs/ADRs.

## Global Constraints

- No Developer ID / notary credentials — prep only; unsigned DMG remains valid (ADR-011).
- No App Sandbox.
- No new network sinks.
- Do not commit secrets.
- Implement on branch `feat/secure-coding-hardening` from `main`.
- Commits only if the human asks.

---

### Task 1: Branch + ADR-015

**Files:**
- Create: `docs/decisions/ADR-015-hub-revision-and-helper-path-jail.md`
- Modify: (none yet)

- [x] **Step 1:** Create branch from `main`

```bash
git fetch origin main 2>/dev/null || true
git checkout main
git pull --ff-only 2>/dev/null || true
git checkout -b feat/secure-coding-hardening
```

- [x] **Step 2:** Write ADR-015 Accepted covering: optional catalog `hubRevision` for Hub snapshots; Whisper keeps `sha256`; helper rejects `modelDirectory` outside Application Support `carrottype/models/`; notarization remains optional.

---

### Task 2: Security documentation

**Files:**
- Create: `docs/security/secure-coding-checklist.md`
- Create: `docs/security/supply-chain.md`
- Modify: `.ai/constraints.md` (pointer to security docs)

- [x] **Step 1:** Write OWASP Mobile Top 10 checklist with Status / Evidence / Residual / Mitigation per category (post-hardening expected state).
- [x] **Step 2:** Write supply-chain note (SPM pins, sinks, Whisper vs hubRevision vs Parakeet residual).
- [x] **Step 3:** Link both from `.ai/constraints.md` Verification / Trust sections.

---

### Task 3: Helper path jail

**Files:**
- Modify: `macos/CarrotTypeCleanupHelper/main.swift`
- Modify: `macos/Shared/CleanupHelperProtocol.swift` (document `modelPathRejected`)

- [x] **Step 1:** Add `isAllowedModelDirectory(_:)` — resolve symlinks, require path under `~/Library/Application Support/carrottype/models/` with `/` boundary.
- [x] **Step 2:** Before MLX load, reject with `emit(.failure("modelPathRejected")); exit(0)`.
- [x] **Step 3:** Document error code in protocol comment.

---

### Task 4: Catalog `hubRevision` + download/ready

**Files:**
- Modify: `macos/CarrotType/Models/ModelTypes.swift`
- Modify: `macos/CarrotType/Models/BundledModelCatalog.swift`
- Modify: `macos/CarrotType/Resources/ModelCatalog.json` (bump `version` to 10)
- Modify: `macos/CarrotType/Services/ModelPackageLayout.swift`
- Modify: `macos/CarrotType/Services/Engines/QwenCleanupPackage.swift`
- Modify: `macos/CarrotType/Services/ModelManager.swift` (pass revision; ready check)

Pinned SHAs (fetched 2026-10-30 from HF `revision/main`):

| Package | hubRevision |
|---------|-------------|
| `cleanup.qwen3-0.6b-4bit` | `73e3e38d981303bc594367cd910ea6eb48349da8` |
| `cleanup.qwen3-1.7b-4bit` | `3b1b1768f8f8cf8351c712464f906e86c2b8269e` |
| `cleanup.gemma4-e2b-4bit` | `238767527555cb75a05732a84dff5d6ba0dd6809` |

- [x] **Step 1:** Add optional `hubRevision` to `CatalogPackage` (CodingKeys, init, decode).
- [x] **Step 2:** Add `hubRevisionMarker(in:)` to `ModelPackageLayout`.
- [x] **Step 3:** `QwenCleanupPackage.downloadPackage(..., revision: String = "main")` → `downloadSnapshot(..., revision:)`; write `.hub-revision` after success.
- [x] **Step 4:** `isPackageReady` — if expected revision provided and marker mismatches/missing → false.
- [x] **Step 5:** Wire `ModelManager.downloadMLXSnapshot` to pass package.hubRevision ?? "main"; ready refresh uses catalog hubRevision.
- [x] **Step 6:** Update JSON + BundledModelCatalog with pins; catalog version 10.

---

### Task 5: Clipboard + retain copy

**Files:**
- Modify: `macos/CarrotType/Services/TextInsertionService.swift` (0.35 → 0.20)
- Modify: `macos/CarrotType/Resources/Localizable.xcstrings` (`hotkey.retain_clipboard_footer` EN/RU)

- [x] **Step 1:** Shorten restore delay to 0.20s.
- [x] **Step 2:** Update footer: retained text stays on system pasteboard (other apps may read it).

---

### Task 6: Notarization prep

**Files:**
- Create: `ops/notarization.env.example`
- Create: `macos/scripts/notarize-dmg.sh` (executable)
- Modify: `ops/deploy.md` (expand follow-up section; link example + script)

- [x] **Step 1:** Env example placeholders only.
- [x] **Step 2:** Script: require DMG arg + keychain profile; submit/wait/staple; clear error if missing.
- [x] **Step 3:** Document in `ops/deploy.md`.

---

### Task 7: Roadmap + architecture touch + verify

**Files:**
- Modify: `docs/roadmap.md`
- Modify: `docs/architecture.md` (one line on hubRevision / helper jail if needed)

- [x] **Step 1:** Mark security pass done; notarization still optional when credentials exist.
- [x] **Step 2:** Debug build host (+ helper if scheme allows).
- [x] **Step 3:** Completion report to human (verification, residuals, no commit unless asked).
