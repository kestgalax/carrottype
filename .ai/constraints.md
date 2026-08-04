# Constraints

## Product / platform

- MVP is a **macOS menu-bar** dictation app (Apple Silicon first, macOS 14+).
- Do not expand to iOS, Windows, or cloud-first SaaS without an accepted ADR and product-intent change.
- Primary loop stays: hotkey → local STT → optional formatting → caret paste.
- Secondary loop (ADR-012): transform **bindings** → read selection → local LLM (Translate pair flip or custom instructions) → Capsule result (Copy / Close); reuse cleanup helper packages only.

## Engines and models

- Do not introduce a new STT or cleanup runtime, package manager, or distribution channel without an ADR.
- Model weights are **not** bundled in the `.dmg` (on-demand download into Application Support).
- Do not flip catalog `recommended` STT until `docs/stt-ru-en-quality-note.md` has a filled Result section.

## Privacy / network / dependencies

Local-first privacy is a hard product constraint (see `docs/product-intent.md`, ADR-003).

### Data-flow contract

```text
mic → temp audio → on-device STT → optional local cleanup → caret paste → delete temp
```

- Settings and selections stay on-device (`UserDefaults`, Application Support).
- Do not persist dictation audio longer than the session needs.

### Closed network sinks

Only these outbound / network paths are allowed without a new ADR + product-intent change:

1. **HTTPS model download** — catalog / Hugging Face URLs, triggered by explicit setup/download (see `ModelManager`, ADR-003).
2. **Localhost Wave Link** — `127.0.0.1` WebSocket/TCP for experimental unmute (ADR-007, `MicMuteController`).
3. **Apple speech asset install** — system `AssetInventory` download when the user taps Prepare for `stt.apple-speechanalyzer` (ADR-008). Audio/transcript stay on-device.

Dictation runtime (`DictationPipeline` and engines) must not upload audio or transcript text.

### Forbidden by default

- Cloud STT or cloud cleanup that sends audio/text off-device.
- Telemetry, analytics, or crash-reporting SDKs that upload data.
- Silent phone-home during dictation after models are installed.
- Any outbound network outside the closed sink list.

### Dependency triage (SPM)

- **Direct** product dependencies (e.g. FluidAudio, WhisperMetalKit, mlx-swift-lm, swift-huggingface, swift-transformers) are conscious risk: add/replace only with an ADR (or explicit coverage in the engine ADR).
- **Transitive** pins in `Package.resolved` are not cleaned “for purity”; do not add a new *direct* dependency without answering: why in the pipeline, any HTTP after install, pinned revision, integrity where applicable (e.g. Whisper SHA-256 in catalog).
- Do not claim “fully offline / nothing leaves the device” without noting model-download sinks and residual risk from transitive SDKs.

### Verification posture

- For changes that touch network, engines, or dependencies: state offline dictation expectation in the plan / completion report / review, or record residual risk if not verified.
- Airplane mode / Little Snitch smoke is **not** required on every PR; it is deferred full-pass work, not a per-change gate.

## Repository hygiene

- Do not commit secrets, `.env`, signing certificates, or personal Keychain material.
- Do not commit `dist/`, `macos/.derivedData/`, or `macos/.derivedData-release/`.
- Keep repository artifacts (docs, ADRs, specs) as the source of truth — not chat history.

## Trust / distribution

- Do not claim notarized / Gatekeeper-clean install until Developer ID signing + notarization are done.
- The GitHub repository **may be public** (MIT, ADR-011). Unsigned DMG via GitHub Releases is an allowed distribute path; Gatekeeper install is Right-click → Open.
- Notarization / Apple Developer ID is **optional later**, not a blocker for public source or unsigned Release downloads.
- Soft brand ask (README): forks should attribute CarrotType and not reuse the name/icon — no dual-commercial or registered-trademark requirement.
