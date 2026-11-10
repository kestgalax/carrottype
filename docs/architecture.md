# Architecture

## Product shape

`carrottype` is a native macOS menu bar / background app. The primary loop is:

```text
Global hotkey (toggle by default; hold-to-talk only when Walkie-talkie is on)
  → microphone capture (16 kHz mono WAV; optional fan-out to streaming STT)
    → on-device STT (Parakeet Ultra; full-buffer offline live draft when enabled — ADR-014/016)
  → optional post-dictation formatting (Light / Qwen3 0.6B / Gemma)
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
- Settings model UX: Ultra state/download/cancel/retry/delete without an STT picker. Cleanup modes remain Ready-only selectable; Ready-but-inactive Qwen3 0.6B/Gemma rows retain **Make active**; Smart+ is compatibility-only from 0.8.0 (ADR-018).
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

## Setup and formatting feedback — 0.6.0

`SetupProgress` derives the next step from live permissions, Ultra readiness and a persisted trial-completion Boolean. Welcome is separate from readiness; Settings is presented once per first launch from the always-present menu label. Setup reuses native permission/meter/Wave Link and package download controls.

Trial entry reserves the existing `UpdateInstallationGate` before scheduling capture. It reuses the recorder, live draft, mute, STT/formatting and teardown; `DictationDelivery` pins the destination for completion to either caret or Setup. Only the caret closure inserts/copies/counts/updates last dictation. Trial text/outcome stay in RAM; a successful non-empty trial sets a Boolean. Cancelling/closing Setup cancels the trial Task and suppresses output while retaining the reservation until actual teardown. Trial button control is independent of PTT; normal hotkey flow remains. Full session-coordinator refactoring remains planned; now 0.6.2 after the maintainer-added 0.6.1 update-presentation stage (see roadmap).

`DictationFormatting` wraps the existing cleanup engines and returns text plus requested/actual modes and safe missing/generation fallback reason. Missing/failing MLX uses real Light formatting; cancellation propagates. Capsule briefly reports fallback and Details holds the last normal outcome; no raw helper diagnostics/transcripts are persisted. Existing stats and paste-dispatch semantics remain.

Transform disclosure rows retain saved mode selection, explain the same `TransformModelSelection` resolution used at runtime and navigate to Models without downloading. A saved empty array is distinct from absent/invalid preferences. Hotkey capture temporarily unregisters app chords and always restores registration on apply/conflict/cancel; editing callbacks cannot start dictation. Registration can be disabled by dependency injection for tests. The Debug-only `setup-test` identity uses isolated preferences/model/stat roots and disables global registration; it is never a shipping identity.

## Update presentation — 0.6.1

`ReleaseNotes.json` is bundled version/build/date plus localized summary/sections/items. `ReleaseNotes.decode` validates identity/schema/date/content and supplies English fallback; `ReleaseNotesStore` reads it locally and persists only observed/read version+build identifiers. The first tracked launch establishes a quiet baseline; subsequent observed changes remain unread across relaunch until the sheet opens. There is no automatic popup or HTTP read. Invalid/missing/mismatched data leaves the app usable with a notes-unavailable message and explicit GitHub releases link.

General and Details reuse `WhatsNewButton` and a native scrollable `ReleaseNotesView` sheet; footer actions stay visible. Opening the sheet does not invoke the updater, change opt-ins, or remount Settings. Native copy follows the existing explicit app locale. The installed version is distinct from the available version in Sparkle.

`release_notes.py` validates the same resource for packaging and renders escaped template-owned inline HTML/CSS and Markdown. `prepare-update.py` reads the signed app’s bundled source, checks version/build, embeds RU/EN descriptions with `xml:lang`, then signs the feed/archive exactly as before. No JS or remote note/style/font/image resources. Standard Sparkle UI, localization, installer, trust and gate remain; its labels and description selection follow system preferred localizations, not the live in-app override. Production no longer accepts independently authored `--notes`; legacy plain text is staging-only.

Debug staging accepts only `app.carrottype.macos.update-test[.<run-id>]`; unique run/scenario identities prevent native resume state from contaminating other tests. Debug profile roots derive from these identities, outside production data; production bundle validation still requires the exact real ID. A/B fixtures use signed copies of the Debug candidate with different builds and matching note metadata; they prove the native installer, not independent TCC continuity or the behavior of a historically compiled app.

## Session ownership — 0.6.2

`DictationSessionCoordinator<Configuration, Output>` owns a single main-actor lifecycle: idle → starting → recording → transcribing/cleaning → finishing → idle, or cancelling → idle. It reserves the shared install gate synchronously before creating a task. Recorder/mute/preview adapters are created with the coordinator; AppState handles published presentation and existing caret/trial/recovery/statistics delivery only. Each start captures a value configuration (model ID/path, formatting mode/directory, microphone and active shortcut/live-draft choices). Clipboard/statistics opt-ins retain their live delivery-time semantics.

Capture begins without awaiting preview/unmute. Preview attachment waits for unmute; token/state guards drop late transcript/peak/phase callbacks. On every exit, cancel capture as needed, wait for unmute before restoring mute, cancel/join preview start, stop preview, remove owned WAV and await engine unload before dropping the reservation. Processing cancellation flags/cancels its owning task, discarding even a late non-cooperative result; it does not launch a competing teardown. Result delivery is single-shot and precedes final unload. Capture/stop/processing failures share this exit path.

Idle unload and package deletion use `maintain` to reserve before awaits; new starts cannot overlap them. If another operation is busy, selection-change unload is unnecessary because that owner unloads on exit; deletion reports retry-after-operation. All UI package deletion calls route through this reserved AppState boundary. Transform tasks also retain their gate lease through awaited unload. No fire-and-forget unload can affect the next session.

Ordinary Quit closes session/maintenance and hotkey entry, cancels capture/processing/transform, awaits current operation/maintenance teardown, then replies to AppKit with the final install gate lock. Sparkle's original install-on-quit/resume termination guard runs first; requesting installation during busy work does not forcibly cancel it. The will-terminate mute hook remains best effort for abnormal termination; SIGKILL cannot be made graceful.

Production `LiveDraftText` and `WaveLinkPortOrder` are compiled into the regression harness rather than mirrored in test scripts. Tests inject delayed audio/engine/mute adapters into the real coordinator; they do not claim real device/model/TCC coverage. GitHub Actions uses a pinned AIDOS checkout and production regressions, then unsigned arm64 Debug compilation on Xcode 27 (current resolved MLX requires Swift 6.3/experimentalCGen). No CI publication or signing secrets.

Streaming's own actor is also generation-bound: stop/unload cancels and joins its actual preview loop before manager cleanup. A late pass uses the callback captured for that epoch and cannot clear another epoch's single-flight flag. Recorder PCM handlers capture the engine epoch; stale queued chunks are dropped. Each AudioRecorder start creates a fresh fanout and captures its peak callback rather than looking up the next session's mutable handler. The compatibility `StreamingSTTEngine.feed` entry remains; actual recorder attachment uses the generation-bound handler. The actual actor/fanout are compiled with a test-only stub FluidAudio module for controlled in-flight inference; production always imports the real pinned SDK.

## Native A presentation — 0.7.0

Limited `AppStyle`/Settings row components keep native macOS Forms and the existing five-pane navigation/window bounds. General formatting observes the same ModelManager and calls the same Ready-only selection path as Models. Confirmation views precede existing deletion/stat actions; they do not reserve/unload/delete on Cancel. Capsule adapts existing animation/text styling to accessibility preferences without changing recording/session delivery. Original SVG brand masters and deterministic native PNG exports supply AppIcon and an 18pt idle menu template; active state symbols retain their meaning. No engine/runtime/dependency/network/trust or data storage change.

## Dictation preferences and theme — 0.8.0 (ADR-018)

New cleanup choices are Qwen3 0.6B and Gemma; Off/Light remain. Smart+ stays catalogued/non-downloadable for already active ready selections, existing binding-specific choices and Storage. Ready status is derived before the download-availability guard, so stopping new downloads does not disable installed legacy models. No new fallback recommends Smart+; files and saved bindings are not migrated/deleted.

`DictationRules` is a bounded local value, captured into `DictationPipelineConfiguration` at session start. Helper protocol v3 carries explicit dictation purpose/rules or independent transform instructions, rejecting mixed contracts. The shared prompt retains literal-cleanup constraints. Actual tokenizer/chat input length and model config determine a bounded output budget; incomplete generation, empty output and conservative protected-literal loss checks fail to visible Light fallback. These checks cannot prove semantic fidelity. Transform prompts/framing/caps retain ADR-012 behavior. Models still run in the same process-per-request helper and exit to release memory.

Formatting's text trial owns the same operation gate through actual formatting and awaited unload; cancellation/quit join it before release. Text/result are RAM-only, no clipboard/paste/Last Dictation/statistics writes. Theme is a separate UserDefaults enum (`carrottype.appTheme`, invalid/absent → System); `NSApplication.appearance` is the sole theme authority for native windows and SwiftUI hosts, without a view identity change. Settings must not also use `preferredColorScheme`: switching that preference back to nil can leave the SwiftUI environment in the previous forced scheme. Capsule uses semantic light/dark colors; system menu symbols remain templates. No global macOS appearance change.

0.8.0 custom-rule feedback: presentation/word/tone preferences explicitly outrank generic cleanup defaults while content/language/intent protection remains. Only an explicit style request permits changing wording; no-custom behavior stays literal. Existing question-mark loss is a conservative rejection alongside protected literals. Trial results show captured actual mode and a prominent fallback warning, rather than implying every returned string came from the selected model. Actual AppState/Gemma trials reveal combined/style compliance remains unreliable; this is not a rule-execution guarantee.


### 0.8.0 exact-control rework (ADR-018)

`DictationRules` now decodes old saved payloads with defaults for new opt-in word/case/final-period/business-tone fields. Explicit word deletion runs before inference/base cleanup; exact controls run after either model output or Light fallback through the same `DictationFormatting.perform` used by trial and dictation. Off disables base cleanup/model, not explicitly enabled exact controls. Protected prose segmentation preserves code/URL/email/identifiable ASCII technical tokens; final punctuation preserves internal decimal/version points, ?/!, ellipses and recognised abbreviations. Empty final text does not insert/count. Light conservatively bypasses strings containing code/URLs/email to avoid altering protected literals.

Business tone has a separate prompt but the same helper/purpose and content guards; transform instructions remain independent. Typed missing/budget/timeout/incomplete/rejected/other failures reach stage-specific UI without raw diagnostics. Tone additionally requires equal question-mark counts; ordinary literal cleanup retains the previous question-punctuation policy. `FormattingOutcome` separately reports exact controls, generated/unchanged wording and failed/inactive tone. Model generation is not proof of a successful tone or semantic fidelity. Current Gemma evaluation has failures; style acceptance remains open and the control is labelled experimental, off by default.


The optional `lowercaseFirstLetter` control is another final exact operation: only the first prose letter changes; the rest retains case. Protected starts stay unchanged, full-prose lowercase takes precedence, old saved settings default this new key false. No helper prompt or transform change.
