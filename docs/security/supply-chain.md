# Supply chain (SPM + model downloads)

CarrotType’s closed network sinks and dependency rules live in `.ai/constraints.md`. This note records how integrity is applied in practice.

## Direct product dependencies

Pinned in `macos/CarrotType.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` (and declared in `macos/project.yml`):

| Package | Role | Integrity posture |
|---------|------|-------------------|
| Sparkle 2.10.1 | Native app updater (ADR-017) | Exact SPM revision `ab7d71291238df6e0492143b120c9b696a35f603`; binary checksum in upstream manifest; archive and feed Ed25519 verification |
| FluidAudio | Parakeet CoreML STT / live draft | SPM revision pin; HTTPS Hub via library; **no app-level file SHA** |
| mlx-swift-lm (+ mlx-swift) | Cleanup helper inference | Runs only in `CarrotTypeCleanupHelper` |
| swift-huggingface | Hub snapshot download for MLX packages | Catalog `hubRevision` (ADR-015) |
| swift-transformers / transitive | Via mlx / HF stack | Transitive pins in `Package.resolved` |

Add or replace a **direct** dependency only with an ADR (or explicit engine ADR coverage).

## Model download integrity

| Kind | Mechanism |
|------|-----------|
| MLX cleanup (Qwen / Gemma Hub snapshot) | Catalog `hubRevision` → `HubClient.downloadSnapshot(revision:)`; `.hub-revision` marker on disk |
| Parakeet (FluidAudio) | Library version + HTTPS; residual: trust FluidAudio + Hub tip for that library’s download API |

## Application Support vs Hub cache

- **Installed packages** live under `~/Library/Application Support/carrottype/models/`. Models → Delete / Storage → Delete unused remove these dirs only.
- **Download cache** for Hub snapshots also lives under `~/.cache/huggingface/hub/models--…`. Re-download after package Delete can be fast because this cache remains.
- Settings → **Storage → Clear download cache** removes only catalog `hubRepoID` folders plus the allowlisted retired Parakeet v3 repo cache (not the whole Hub tree, not Application Support installs).

## Closed network sinks (reminder)

1. HTTPS model download (catalog / Hugging Face), user-triggered.
2. Localhost Wave Link (`127.0.0.1`) for experimental unmute.
3. Signed app metadata/inline notes/archives on the project GitHub Releases, including HTTPS GitHub asset redirects/CDN. Manual checks or opt-in automatic checks/downloads only; system profiling disabled. Isolated development loopback feed is not used in production (ADR-017).
Apple SpeechAnalyzer asset preparation is retired in the 0.4.0 (ADR-016). Existing shared system assets are not removed.

Dictation runtime must not upload audio or transcript.

## Bumping pins

1. Change version / revision in `macos/project.yml` (or Xcode SPM UI).
2. Resolve / commit updated `Package.resolved`.
3. For MLX catalog packages: refresh `hubRevision` from Hugging Face (`/api/models/{repo}/revision/main` → `sha`) and bump catalog `version`.
4. Note residual risk in the PR / completion report if offline smoke was skipped.

## Notarization / binary trust

Unsigned Release DMGs are allowed (ADR-011). Developer ID + `notarytool` is optional polish — see `ops/deploy.md`, `ops/notarization.env.example`, `macos/scripts/notarize-dmg.sh`. Do not claim Gatekeeper-clean install without staple evidence.

## 0.4.0 — retired STT packages

ADR-016 removes WhisperMetalKit and Apple SpeechAnalyzer runtime; all remaining SPM pins are unchanged. Ultra uses the existing FluidAudio path and inherits ADR-006 downloader residuals (including path handling). No new download sink or inference runtime. Old STT weights are never removed automatically: LegacySTTStorage inventories fixed known paths and rejects symlink escapes for explicit group deletion. It excludes Ultra, cleanup packages, unknown experiments and shared Apple system assets. Safety checks run only against temporary fixtures.

The resolved Sparkle license and bundled third-party notices ship as `Contents/Resources/Sparkle-LICENSE.txt` (upstream notice text retained).

## Updater signing and remaining trust limits

Only the Ed25519 public key is embedded/committed. The private key stays in login Keychain account `app.carrottype.macos.updates`; make an encrypted offline backup outside the workspace. Build/sign scripts never export it and refuse a mismatched public key. Signed feed verification has no expiration fallback; archives verify before extraction. Lost keys without backup require manual reinstall with a new key for current self-signed distribution. EdDSA is not Developer ID/notarization and does not guarantee TCC grant continuity. Real native installer and signature-negative checks supplement, but do not replace, the Debug manual UI/TCC gate. Full independent network audit remains deferred; dictation is expected to work offline with installed models and updater disabled.
