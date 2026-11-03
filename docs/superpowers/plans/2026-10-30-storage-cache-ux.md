# Storage Cache UX Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Two-section Storage pane — installed packages inventory + CarrotType-scoped HF download cache clear (spec `2026-10-30-storage-cache-ux-design.md`).

**Architecture:** Extend `ModelManager` with catalog-scoped hub cache size + clear; rewrite `StorageSettingsPane` into two Form sections with confirmation alert. Per-package Delete stays on Models.

**Tech Stack:** SwiftUI Settings Form, existing `ModelManager` disk helpers, L10n xcstrings.

## Global Constraints

- New branch `feat/storage-cache-ux` from `origin/main`.
- Clear only `models--*` dirs for catalog Hub repos; never wipe whole `hub/`.
- Do not remove Application Support packages from cache clear.
- Commits only if human asks.

---

### Task 1: ModelManager hub-cache API

**Files:** Modify `macos/CarrotType/Services/ModelManager.swift`

- [x] Expose `downloadCacheBytes: Int64` summing `hubCacheBytes` for each catalog package with a resolvable hub repo id.
- [x] Expose `clearDownloadCache()` removing those directories if present; call `objectWillChange` / refresh as needed.
- [x] Reuse existing `hubCacheBytes(forRepoID:)` / hub root resolution; make reusable for listing URLs to delete.

### Task 2: StorageSettingsPane + L10n

**Files:**
- Modify `macos/CarrotType/Views/Settings/StorageSettingsPane.swift`
- Modify `macos/CarrotType/Resources/Localizable.xcstrings`
- Wire clear via `AppState` if other deletes go through AppState — mirror `deleteUnusedModelPackages` pattern.

- [x] Section Installed packages (existing list + delete unused + updated labels/footers).
- [x] Section Download cache (size + clear + confirmation).
- [x] EN/RU strings.

### Task 3: Docs + verify

**Files:** `docs/specs/ux-setup-status.md`, `docs/roadmap.md`, optionally `docs/security/supply-chain.md`

- [x] Update Storage bullets; roadmap next focus / in progress.
- [x] Debug build.
