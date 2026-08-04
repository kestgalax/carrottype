# ADR-012: Selection Transform (Bindings + Bidirectional Translate)

## Status

Accepted

## Context

CarrotType’s primary loop is dictation: hotkey → mic → on-device STT → optional literal cleanup → caret paste (ADR-003 / ADR-009). Users also want to transform **already selected text** in any app (translate, summarize, restyle) via global hotkeys, without leaving the keyboard flow and without cloud APIs.

The out-of-process MLX helper (`CarrotTypeCleanupHelper`, ADR-009) already runs Smart / Smart+ / Gemma on arbitrary text. Dictation cleanup uses a hardened **literal** prompt that forbids translation and paraphrase (ADR-003). Selection transform needs **different instructions** and must work even when post-dictation formatting is Off/Light.

Auto-replacing the selection is wrong for read-only contexts (browser pages, PDFs). Results must be shown without destroying the source selection.

Users need **multiple** shortcuts (e.g. translate on one chord, summarize on another), each with its own action kind and model — not a single shared instruction field.

## Decision

1. **Secondary product loop** (does not replace dictation):
   ```text
   binding hotkey → read selection → on-device LLM → Status Capsule result (Copy / Close)
   ```
2. **Reuse** `CarrotTypeCleanupHelper` and existing cleanup packages (`smart` / `smartPlus` / `gemma`). No new runtime, no Translate-only models, no cloud path.
3. **Transform bindings** (max 5), persisted as `carrottype.transformBindings`:
   - Each binding: hotkey (`KeyChord`) + kind (`translate` | `custom`) + MLX `cleanupMode` + optional `customInstruction` + language pair (`languageA` / `languageB`) for Translate
   - Fresh default: one Translate binding, chord **⌥'**, pair **ru ↔ en**, preferred Ready mode (Smart+ if Ready, else first Ready MLX, else Smart)
   - Legacy single keys (`transformHotkeyChord` / `transformInstruction` / `transformCleanupMode`) migrate to one binding
4. **Translate kind:** detect source with `NLLanguageRecognizer` against the user-configured pair; target = the other side. When unsure (low confidence / outside pair / short text), preferred target = UI locale if it matches a pair side, else `languageB`. Curated codes: `en`, `ru`, `de`, `fr`, `es`, `it`, `pt`, `zh-Hans`, `ja`, `ko`. Capsule may show direction (`EN → RU`).
5. **Custom kind:** uses `customInstruction` as helper instructions (empty → error). No language detect.
6. **Helper protocol:** optional `instructions` on `CleanupHelperRequest`. Nil/empty → literal cleanup; non-empty → custom instructions. Max tokens **2048** for custom-instruction runs; literal cleanup keeps **1024**.
7. **Read path:** Accessibility `AXSelectedText`; fallback ⌘C with pasteboard restore.
8. **Output path:** expanded Status Capsule — **Copy** / **Close** / **Escape**. Does **not** auto-replace. Dictation phases stay click-through.
9. **Hotkeys:** dictation Carbon id `1`, Escape `2`, transform bindings `3…`. Chords must not collide with dictation or each other.
10. **Out of scope:** Replace button; per-binding paste mode; new models (TranslateGemma / Hy-MT); arbitrary BCP-47 outside curated list; cloud LLM.

## Consequences

- Product intent / architecture document a secondary loop; Ready state still does **not** require a transform model.
- `HotkeyService` registers N transform chords; Settings → General shows a bindings list.
- Transform fails clearly when Custom instruction empty, no selection, Accessibility denied, or no Ready MLX package for the binding.
- Dictation path passes `instructions: nil` so literal cleanup behavior is unchanged.

## Alternatives considered

- **Single shared instruction + one hotkey:** rejected; users need multiple actions.
- **Dedicated Translate-only models:** deferred; reuse Smart / Smart+ / Gemma.
- **Hard-coded RU↔EN only:** rejected; pair is user-configurable (default still ru↔en).
- **Reuse dictation cleanup mode for transform:** rejected; Off/Light would block transform.
- **Default ⌥⌘T:** rejected; conflicts with browser Reopen Closed Tab.
- **Auto-replace selection:** rejected for v1; breaks translate-while-reading.
