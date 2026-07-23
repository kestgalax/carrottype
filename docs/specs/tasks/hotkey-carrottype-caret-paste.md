# Hotkey CarrotType Caret Paste

## Metadata

- Task ID: T-001
- Title: Hotkey CarrotType Caret Paste — vertical slice

## Traceability

- Product Intent Link: docs/product-intent.md
- Roadmap Item: Milestone 2: First Feature
- Feature Spec: docs/specs/features/hotkey-carrottype-caret-paste.md
- Related ADRs: docs/decisions/ADR-001-initial-project-structure.md, docs/decisions/ADR-002-runtime-stack.md, docs/decisions/ADR-003-model-catalog-and-cleanup.md
- UX Spec: docs/specs/ux-setup-status.md

## Scope

Implement the first end-to-end vertical slice after ADR-002 / ADR-003:

1. Register a global hotkey.
2. Capture microphone audio for the recording window.
3. Run local STT (active catalog model).
4. Optional cleanup (Light / Qwen3 Smart).
5. Insert text at the caret of the frontmost app.

**Done (MVP vertical slice, ADR-004):** real ggml Whisper download, WhisperMetalKit STT, hotkey toggle → record → Light cleanup → caret paste.

**Remaining:** Flip `recommended` after `docs/stt-ru-en-quality-note.md`; notarized GitHub Release after Apple Developer purchase.

## Acceptance Criteria

- Vertical slice runs on a developer macOS machine with documented setup in `ops/environments.md`.
- At least one local model path is documented and reproducible.
- Caret insertion works in at least TextEdit and one third-party app (e.g. browser input).
- No audio leaves the machine on the default path.

## Verification

- Manual: hotkey → speak → text appears at caret.
- Manual: airplane mode / blocked network still succeeds for local model.
- `npm run aidos:validate` and `npm run aidos:review` pass for this change set.

## Documentation Updates

- Update `ops/environments.md` with install/run steps.
- Update `docs/architecture.md` after ADR-002 acceptance.
- Keep feature/task/review specs in sync.

## ADR Impact

Follows Accepted `ADR-002`, `ADR-003`, and `ADR-004` (WhisperMetalKit / ggml for runnable MVP).
