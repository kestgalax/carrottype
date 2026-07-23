# Constraints

## Product / platform

- MVP is a **macOS menu-bar** dictation app (Apple Silicon first, macOS 14+).
- Do not expand to iOS, Windows, or cloud-first SaaS without an accepted ADR and product-intent change.
- Primary loop stays: hotkey → local STT → optional formatting → caret paste.

## Engines and models

- Do not introduce a new STT or cleanup runtime, package manager, or distribution channel without an ADR.
- Do not add cloud STT/cleanup that uploads audio by default.
- Model weights are **not** bundled in the `.dmg` (on-demand download into Application Support).
- Do not flip catalog `recommended` STT until `docs/stt-ru-en-quality-note.md` has a filled Result section.

## Repository hygiene

- Do not commit secrets, `.env`, signing certificates, or personal Keychain material.
- Do not commit `dist/`, `macos/.derivedData/`, or `macos/.derivedData-release/`.
- Keep repository artifacts (docs, ADRs, specs) as the source of truth — not chat history.

## Trust / distribution

- Do not claim notarized / Gatekeeper-clean install until Developer ID signing + notarization are done.
- Current distribution is a **private** GitHub repo + invite-only Release until explicitly opened.
