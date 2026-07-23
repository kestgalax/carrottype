# ADR-002: Runtime Stack

## Status

Accepted

## Context

Before application runtime code is added, this project must choose its initial stack.

Product form: native macOS menu bar / background app with global hotkey → local STT → caret paste.

Distribution goal: publish on GitHub as a downloadable notarized `.app` / `.dmg` so non-developer users can install without building from source.

Initial onboarding direction considered Swift and Tauri/Rust shells with on-device Parakeet/Whisper-class models.

## Decision

Use a **native Swift macOS app** as the product shell and orchestration layer:

- Language / runtime: Swift, macOS 14+ target (Apple Silicon first).
- App form: menu bar / background agent with global hotkey.
- UI toolkit: SwiftUI for status / settings; minimal chrome for MVP.
- Audio capture: AVFoundation (or equivalent Apple audio APIs).
- Text insertion: Accessibility / CGEvent paste path into the frontmost app caret (explicit user-granted permissions).
- STT: on-device models in the Parakeet / Whisper class, integrated via a local runtime suitable for macOS (e.g. Core ML / MLX / whisper.cpp binding — exact engine chosen in a follow-up ADR or task spike).
- Package / build: Xcode + Swift Package Manager where applicable.
- Tests: XCTest for unit logic; manual verification for hotkey → paste loop.
- Distribution: GitHub Releases (`.dmg` / `.app`), ideally signed and notarized; optional Homebrew Cask later. Not Mac App Store for MVP (Accessibility constraints).

Models are not required to ship inside the first GitHub artifact; first-run download of a default local model is allowed.

## Alternatives

- **Tauri / Rust shell**
  Rationale: rejected for MVP. Does not improve end-user install vs a notarized native `.app`, adds WebView/runtime weight, and makes global hotkey + caret paste on macOS harder for little gain while the product is macOS-only.

- **Hybrid (Swift input + separate STT process)**
  Rationale: deferred. May reappear if a specific STT engine is easiest as a sidecar binary; not the default architecture.

- **Cloud STT API**
  Rationale: rejected as default path — conflicts with local-first privacy in product intent.

## Consequences

- Implementation may begin after this ADR is Accepted (this document).
- `docs/architecture.md` must match this decision.
- Contributors need Xcode to build from source; end users should install prebuilt Releases.
- Model catalog, download policy, and Qwen3 cleanup modes are defined in `ADR-003-model-catalog-and-cleanup.md`.
- Windows/Linux are explicitly out of MVP scope.
