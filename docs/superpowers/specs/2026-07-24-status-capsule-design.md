# Design: Status Capsule (session chrome)

## Traceability

- Product Intent: `docs/product-intent.md` (minimal friction hotkey → paste; process clarity without a voice studio)
- UX base: `docs/specs/ux-setup-status.md` (menu bar states; Escape cancel)
- Architecture: `docs/architecture.md` (menu bar / background app shell)
- Replaces runtime UI: `macos/CarrotType/Views/NotchRecordingOverlay.swift`

## Goal

Show what CarrotType is doing during a dictation session with one compact **Status Capsule** near the camera notch (or under the menu bar on non-notch displays). The capsule reports process state — listening, understanding, writing, inserted — not “the app is open.”

## Decisions

| Decision | Choice |
|----------|--------|
| Interaction scope | **A — status only**: no hover expand, no click actions, `ignoresMouseEvents = true` |
| Visual language | **B — Dot + label** (e.g. `● Listening`) |
| Module shape | **New `StatusCapsule*` module**; retire `NotchRecordingOverlay*` as public API; reuse notch panel geometry |
| Understanding | Single phase for STT **and** cleanup (`⋯ Understanding`) |
| Completion rhythm | Always `Writing` (~0.35s) → `Inserted` (~1.0s) → hide, even if paste is fast |
| Cancel / soft cancel | Hide immediately; never show Writing/Inserted |
| Errors | Hide capsule; keep menu bar / Settings error path |
| Localization | Labels via String Catalog / `L10n` (RU/EN) |
| ADR | Not required (session chrome / UX only; no runtime or trust-model change) |

## Module boundaries

| Type | Responsibility |
|------|----------------|
| `StatusCapsuleController` | Borderless `NSPanel`, show/hide, bind to phase + level if needed |
| `StatusCapsuleGeometry` | Notch / non-notch size and origin (evolved from `NotchGeometry`) |
| `StatusCapsuleView` | Compact Dot + label row and micro-animations |
| `StatusCapsulePhase` | `listening` / `understanding` / `writing` / `inserted` |

`AppState` owns the controller and drives phase transitions across the dictation session. Settings / Setup sidebar UI is unchanged.

### Panel policy (unchanged trust model)

- `NSPanel` style: borderless, nonactivating
- Level: status-window class (same band as current island)
- Collection: join all spaces / full-screen auxiliary / stationary
- `ignoresMouseEvents = true` (scope A)

## Phase mapping

| Capsule phase | UI | Pipeline / AppState trigger |
|---------------|----|-----------------------------|
| `listening` | `● Listening` | Microphone capture (today: `.recording`) |
| `understanding` | `⋯ Understanding` | STT + cleanup (today: `.processing` and `.cleanup`) |
| `writing` | `✍ Writing` | After successful pipeline result; short hold around caret insert |
| `inserted` | `✓ Inserted` | After successful paste; then auto-hide |
| hidden | — | Idle, needsSetup, Escape cancel, soft cancel, error |

Menu bar remains a second channel (SF Symbol + menu copy). Writing/Inserted are capsule-only (too brief for menu usefulness). Menu status copy may align to Listening / Understanding where it already surfaces session text.

## Visual constants

- Content height (drop): **36px** (target band 32–40)
- Width: intrinsic label width, clamp **96–148px**, horizontal padding ~14
- Fill: deep black capsule; corner radius ~16–18; notch brow merge retained
- One signal per state — remove waveform bars and `REC` / `STT` / `TXT` triple indicators
- Type: ~12pt medium/semibold system; near-white; no heavy ALL-CAPS tracking
- Listening: 7px red dot, soft glow, ~1.4s breathe
- Understanding: staggered dots ~1.2s (no `ProgressView` spinner)
- Writing: glyph + label, no bounce
- Inserted: check + label, fade ~150–200ms, visible ~1.0s total, then hide

On notched hardware the panel still flushes to the top and clears the camera with a content top inset. On non-notch displays the same capsule hangs just under the menu bar.

## Timing

| Transition | Duration |
|------------|----------|
| Writing hold | ~0.35s |
| Inserted visible | ~1.0s |
| Cross-fade between phases | ~150–200ms opacity |
| Listening pulse period | ~1.4s |
| Understanding dots period | ~1.2s |

Hotkey during Understanding continues to be ignored (same as today’s processing/cleanup guard). Commit remains hotkey; cancel remains Escape while listening.

## Out of scope

- Hover reveal (timer, Cancel)
- Click menu (Pause / Stop / Settings)
- Pause in the audio pipeline
- Replacing menu bar status entirely
- Literal Dynamic Island private APIs
- Changing STT / cleanup engines

## Implementation notes

- Prefer extracting geometry from the existing overlay rather than re-deriving notch math.
- Tear down hosting on hide so animations do not spin while idle (keep current discipline).
- Introduce capsule phase sequencing without forcing Writing/Inserted into long-lived `MenuBarMode` if a local post-success sequence in `AppState` is cleaner.
- Update docs: this spec, `docs/specs/ux-setup-status.md` (session indicator), `docs/architecture.md`, `docs/roadmap.md` after implementation.

## Verification

- Build macOS app target
- Manual: notched and non-notched layout — full Listening → Understanding → Writing → Inserted → hide
- Manual: Escape during Listening hides without Inserted
- Manual: soft cancel (silent / too short) hides without Inserted
- Manual: pipeline error hides capsule; menu bar / Settings still show failure
- Optional focused test: phase mapping + cancel does not emit Inserted
