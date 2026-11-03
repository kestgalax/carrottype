# Supply chain (SPM + model downloads)

CarrotType’s closed network sinks and dependency rules live in `.ai/constraints.md`. This note records how integrity is applied in practice.

## Direct product dependencies

Pinned in `macos/CarrotType.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` (and declared in `macos/project.yml`):

| Package | Role | Integrity posture |
|---------|------|-------------------|
| WhisperMetalKit | Whisper ggml STT | Catalog `sha256` on ggml files |
| FluidAudio | Parakeet CoreML STT / live draft | SPM revision pin; HTTPS Hub via library; **no app-level file SHA** |
| mlx-swift-lm (+ mlx-swift) | Cleanup helper inference | Runs only in `CarrotTypeCleanupHelper` |
| swift-huggingface | Hub snapshot download for MLX packages | Catalog `hubRevision` (ADR-015) |
| swift-transformers / transitive | Via mlx / HF stack | Transitive pins in `Package.resolved` |

Add or replace a **direct** dependency only with an ADR (or explicit engine ADR coverage).

## Model download integrity

| Kind | Mechanism |
|------|-----------|
| Whisper ggml (single file) | Catalog `sha256`; mismatch → delete + fail |
| MLX cleanup (Qwen / Gemma Hub snapshot) | Catalog `hubRevision` → `HubClient.downloadSnapshot(revision:)`; `.hub-revision` marker on disk |
| Parakeet (FluidAudio) | Library version + HTTPS; residual: trust FluidAudio + Hub tip for that library’s download API |
| Apple SpeechAnalyzer | System `AssetInventory` (ADR-008) |

## Application Support vs Hub cache

- **Installed packages** live under `~/Library/Application Support/carrottype/models/`. Models → Delete / Storage → Delete unused remove these dirs only.
- **Download cache** for Hub snapshots also lives under `~/.cache/huggingface/hub/models--…`. Re-download after package Delete can be fast because this cache remains.
- Settings → **Storage → Clear download cache** removes only catalog `hubRepoID` folders (not the whole Hub tree, not Application Support installs).

## Closed network sinks (reminder)

1. HTTPS model download (catalog / Hugging Face), user-triggered.
2. Localhost Wave Link (`127.0.0.1`) for experimental unmute.
3. Apple speech asset install when the user prepares SpeechAnalyzer.

Dictation runtime must not upload audio or transcript.

## Bumping pins

1. Change version / revision in `macos/project.yml` (or Xcode SPM UI).
2. Resolve / commit updated `Package.resolved`.
3. For MLX catalog packages: refresh `hubRevision` from Hugging Face (`/api/models/{repo}/revision/main` → `sha`) and bump catalog `version`.
4. Note residual risk in the PR / completion report if offline smoke was skipped.

## Notarization / binary trust

Unsigned Release DMGs are allowed (ADR-011). Developer ID + `notarytool` is optional polish — see `ops/deploy.md`, `ops/notarization.env.example`, `macos/scripts/notarize-dmg.sh`. Do not claim Gatekeeper-clean install without staple evidence.
