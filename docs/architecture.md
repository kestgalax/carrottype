# Architecture

## Product shape

`carrottype` is a native macOS menu bar / background app. The primary loop is:

```text
Global hotkey (toggle by default; hold-to-talk only when Walkie-talkie is on)
  → microphone capture (16 kHz mono WAV; optional fan-out to streaming STT)
    → on-device STT (Parakeet Ultra; full-buffer offline live draft when enabled — ADR-014/016)
  → optional post-dictation formatting (Light / Qwen3 Smart)
  → insert text at caret in frontmost app
  → optional: keep result on clipboard (no pasteboard restore)
```

Secondary loop (ADR-012):

```text
Transform hotkey (default ⌥')
  → read selected text (AX / ⌘C fallback)
  → on-device LLM via cleanup helper (custom instructions + chosen Smart/Gemma package)
  → Status Capsule result (Copy / Close; no auto-replace)
```

## Components

| Component | Responsibility |
|-----------|----------------|
| App shell (Swift / SwiftUI) | Lifecycle, menu bar status, Status Capsule (session chrome near notch), Setup/Status UI, permission prompts, RU/EN locale |
| Hotkey service | Register and handle global dictation + N transform binding hotkeys; dictation is toggle (default) or hold-to-talk only (Settings Walkie-talkie) |
| Audio capture | Record microphone audio for the active session; optional experimental temporary unmute via Wave Link (ADR-007) |
| Model Manager | Catalog, download, verify, activate STT/cleanup packages (ADR-003) |
| STT runtime | Parakeet Ultra only (ADR-016, 0.4.0); optional live draft via `StreamingSTTEngine` (ADR-014) |
| Cleanup runtime | `off` / `light` heuristics / Qwen3 MLX Smart modes via session-scoped helper process (ADR-009; UI: post-dictation formatting); same helper for selection transform with custom instructions (ADR-012) |
| Selection text | Read focused selection; transform result shown in Capsule (not auto-paste) |
| Text insertion | Paste command via Accessibility; clipboard ownership-aware restore; optional retain-on-clipboard; last completed text recoverable from RAM only (0.3.10) |
| Usage stats (ADR-013) | Opt-in local daily buckets (dictation characters/duration/sessions + per-binding transform counts); Settings → Statistics; no upload |

## Boundaries

- Default path is fully local: audio is not uploaded.
- Model weights download anonymously; no login required (ADR-003).
- Settings/Setup UI is secondary to the hotkey loop but required for readiness transparency; shell is a locked sidebar (General / Setup / Models / Storage / Statistics) with Status as a compact header (`docs/specs/ux-setup-status.md`).
- Optional usage statistics (ADR-013) are local JSON under Application Support; off by default; never transcripts or network.
- Cloud STT/cleanup is out of MVP scope.
- Non-macOS platforms are out of MVP scope.

## Stack (ADR-002)

- Swift + Xcode, macOS 14+, Apple Silicon first
- SwiftUI for Setup/Status (`NavigationSplitView` + grouped Form panes) and minimal chrome; session Status Capsule via borderless `NSPanel` (`StatusCapsule*`, click-through)
- AVFoundation for capture
- Accessibility-based caret insertion
- Distribution via GitHub Releases (`.dmg` / `.app`); public MIT source allowed (ADR-011); notarization optional
- Models cached under Application Support; not bundled in the first release artifact by default

## Model catalog (ADR-003 + ADR-004 + ADR-005 + ADR-006 + ADR-008 + ADR-010 + ADR-012 + ADR-015 + ADR-016)

- **STT (0.4.0, ADR-016):** only `stt.parakeet-ultra` via FluidAudio CoreML. No STT picker, Whisper adapter/dependency or Apple SpeechAnalyzer runtime. Installed Ultra is reused; absent Ultra requires an explicit download. Legacy/unknown saved STT ids migrate to Ultra without deleting weights or silently downloading. Storage inventories known retired directories separately with confirmed optional deletion; shared Apple system assets and unknown experimental models are untouched.
- **Cleanup:** Off / Light heuristics; Smart / Smart+ via Qwen3 MLX; optional **Gemma 4 E2B** MLX (`cleanup.gemma4-e2b-4bit`, ADR-010) — all LLM cleanup in `CarrotTypeCleanupHelper` (`mlx-swift-lm`, ADR-005 + ADR-009). Host downloads Hub snapshots with optional catalog `hubRevision` (ADR-015); inference is out-of-process (stdin/stdout JSON, helper exits). Helper rejects `modelDirectory` outside Application Support `carrottype/models/`.
- **Selection transform (ADR-012):** same helper + packages; General **bindings** (hotkey + Translate with user language pair / Custom instruction + model); Translate uses `NLLanguageRecognizer` flip; result in Status Capsule (Copy / Close + optional direction); not required for Ready.
- Engines are selected through `STTEngine` / `CleanupEngine` adapters (`DictationPipeline`); transform reuses the MLX cleanup engine with non-nil instructions.
- Live draft (ADR-014): catalog `supportsStreaming` + Settings toggle (default off); Ultra runs ~1 s single-flight **offline** re-transcribes of accumulated PCM for Capsule (OpenBot-style); last two words muted; Capsule grows with text; stop always uses session WAV file STT → cleanup → paste.
- Settings model UX: Ultra state/download/cancel/retry/delete without an STT picker. Cleanup modes remain Ready-only selectable; Ready-but-inactive Qwen Smart/Smart+/Gemma rows retain **Make active**.
- Idle resource policy: mic meter only when the user enables it in Settings (not on window open); language changes update copy via `L10n` without remounting Settings; permission poll stops when Ready; STT unloads after each session; Smart MLX lives only in the helper process (ADR-009) so host idle stays near cold start.
- Optional experimental temporary unmute during dictation (ADR-007): Settings toggle framed as Elgato Wave Link only; `MicMuteController` clears mute for the capture window (Wave Link primary; Core Audio silent fallback) and restores prior state when capture ends.
- Distribution: GitHub Release `.dmg` (`ops/deploy.md`); public repo + MIT (ADR-011); notarization optional later.

## Constraints

- Microphone and Accessibility permissions are mandatory for Ready.
- Gatekeeper / notarization affect real-world install UX from GitHub.
- Large model weights use on-demand download with progress in Setup UI (`docs/specs/ux-setup-status.md`).

## Application updater — 0.5.0 (ADR-017)

`AppUpdateService` owns a single Sparkle 2.10.1 standard updater. Menu, Status Details and General use that instance; settings bind to Sparkle's KVO properties rather than duplicate UserDefaults flags. Checks/download-and-install-on-quit default off; profiling is disabled even for saved preferences. Feed and archives require Ed25519 signatures, verified before extraction; signed-feed failure never expires. Inline plain-text notes avoid a separate web view content origin.

`UpdateInstallationGate` reserves operations synchronously before their Task starts. Dictation holds a reservation across capture, STT, cleanup, paste, cancellation and mute restoration; transforms release on all exits. A pending relaunch resumes only after the last reservation ends and locks new operations before invoking Sparkle's callback. The application delegate synchronously rechecks at termination for resumed/install-on-quit paths. An aborted install clears the lock. Checks/downloads alone do not reserve or block operations. This is a narrow safety boundary, not the deferred session-coordinator refactor.

Stable HTTPS feed is the `appcast.xml` asset of the latest GitHub Release; archives use versioned asset URLs. `prepare-update.py` validates identity/monotonic build/trust settings, compares embedded and Keychain public keys, archives with preserved symlinks, signs and verifies archive/feed. It does not publish. Self-signed signing includes Sparkle installer/XPC/app components inside-out. No model weights in app archives; models, settings and statistics retain their existing locations. Debug-only staging identity uses a separate model/statistics root and preferences domain; native installer smoke does not run microphone capture or verify TCC.
