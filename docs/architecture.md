# Architecture

## Product shape

`carrottype` is a native macOS menu bar / background app. The primary loop is:

```text
Global hotkey
  → microphone capture
  → on-device STT (catalog model)
  → optional post-dictation formatting (Light / Qwen3 Smart)
  → insert text at caret in frontmost app
  → optional: keep result on clipboard (no pasteboard restore)
```

## Components

| Component | Responsibility |
|-----------|----------------|
| App shell (Swift / SwiftUI) | Lifecycle, menu bar status, Status Capsule (session chrome near notch), Setup/Status UI, permission prompts, RU/EN locale |
| Hotkey service | Register and handle global start/stop recording |
| Audio capture | Record microphone audio for the active session; optional experimental temporary unmute via Wave Link (ADR-007) |
| Model Manager | Catalog, download, verify, activate STT/cleanup packages (ADR-003) |
| STT runtime | Run active STT package (Parakeet / Whisper paths) |
| Cleanup runtime | `off` / `light` heuristics / Qwen3 MLX Smart modes via session-scoped helper process (ADR-009; UI: post-dictation formatting) |
| Text insertion | Paste at caret via Accessibility; optional retain-on-clipboard |

## Boundaries

- Default path is fully local: audio is not uploaded.
- Model weights download anonymously; no login required (ADR-003).
- Settings/Setup UI is secondary to the hotkey loop but required for readiness transparency; shell is a locked `NavigationSplitView` sidebar (General / Setup / Models / Storage) with Status as a compact header (`docs/specs/ux-setup-status.md`).
- Cloud STT/cleanup is out of MVP scope.
- Non-macOS platforms are out of MVP scope.

## Stack (ADR-002)

- Swift + Xcode, macOS 14+, Apple Silicon first
- SwiftUI for Setup/Status (`NavigationSplitView` + grouped Form panes) and minimal chrome; session Status Capsule via borderless `NSPanel` (`StatusCapsule*`, click-through)
- AVFoundation for capture
- Accessibility-based caret insertion
- Distribution via GitHub Releases (`.dmg` / `.app`), notarization preferred
- Models cached under Application Support; not bundled in the first release artifact by default

## Model catalog (ADR-003 + ADR-004 + ADR-005 + ADR-006 + ADR-008)

- **STT (runnable):** Whisper Base/Small/Turbo q5 ggml via WhisperMetalKit (ADR-004); **recommended** Parakeet TDT 0.6B v3 via FluidAudio CoreML (ADR-006); optional Apple SpeechAnalyzer on macOS 26+ via system `AssetInventory` (ADR-008). ggml downloads stage the URLSession temp file synchronously, then verify SHA-256 from the catalog.
- **Cleanup:** Off / Light heuristics; Smart / Smart+ via Qwen3 MLX in `CarrotTypeCleanupHelper` (`mlx-swift-lm`, ADR-005 + ADR-009). Host downloads packages; inference is out-of-process (stdin/stdout JSON, helper exits).
- Engines are selected through `STTEngine` / `CleanupEngine` adapters (`DictationPipeline`).
- Settings selection UX: only Ready packages are selectable; Ready-but-inactive rows offer **Make active** for both STT and Smart formatting.
- Idle resource policy: mic meter only when the user enables it in Settings (not on window open); language changes update copy via `L10n` without remounting Settings; permission poll stops when Ready; STT unloads after each session; Smart MLX lives only in the helper process (ADR-009) so host idle stays near cold start.
- Optional experimental temporary unmute during dictation (ADR-007): Settings toggle framed as Elgato Wave Link only; `MicMuteController` clears mute for the capture window (Wave Link primary; Core Audio silent fallback) and restores prior state when capture ends.
- Distribution: GitHub Release `.dmg` (`ops/deploy.md`); notarization deferred until Developer ID.

## Constraints

- Microphone and Accessibility permissions are mandatory for Ready.
- Gatekeeper / notarization affect real-world install UX from GitHub.
- Large model weights use on-demand download with progress in Setup UI (`docs/specs/ux-setup-status.md`).
