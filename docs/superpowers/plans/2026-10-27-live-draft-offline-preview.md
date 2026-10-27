# Live draft offline preview Implementation Plan

> **For agentic workers:** implement task-by-task on `feat/live-dictation`.

**Goal:** OpenBot-style full-buffer offline live Capsule preview + dynamic Capsule sizing.

**Architecture:** Replace SlidingWindow live path with single-flight ~1s offline `AsrManager` passes over accumulated PCM; stop uses WAV file STT. Capsule height follows text with a max + scroll.

**Tech Stack:** Swift / FluidAudio AsrManager / SwiftUI StatusCapsule

## Global Constraints

- Stay on `feat/live-dictation`; update ADR-014 + F-004 + roadmap.
- One Parakeet model load; no cloud; paste only after stop.
- Live draft remains Settings default off.

---

### Task 1: Offline preview engine

- [x] Rewrite `ParakeetStreamingEngine` to accumulate samples, periodic offline transcribe, cosmetic last-2-word split; `finish` unused for paste (cancel on stop).
- [x] Wire `DictationPipeline` / `AppState` so stop always uses file STT after cancelling preview.
- [x] Debug build compiles.

### Task 2: Dynamic Capsule

- [x] Size panel from draft text; max height + ScrollView; remove lineLimit(3).
- [x] Debug build + manual check.

### Task 3: Docs

- [x] ADR-014, F-004, architecture/roadmap notes; owner verify checklist.
