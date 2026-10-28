# Live draft recorder-first Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Start the dictation WAV recorder before awaiting Parakeet live-draft model load, so speech during cold load is not lost.

**Architecture:** Reorder `AppState.startDictationSession`: mic + Listening chrome first; concurrent Task loads live draft and attaches `onConvertedBuffer` when ready; cancel that Task on Escape/stop/error.

**Tech Stack:** Swift / AVAudioEngine recorder / existing `DictationPipeline.startLiveDraftIfPossible`

## Global Constraints

- Branch: `feat/live-draft-recorder-first`
- Ship **v0.3.6**; no warm-keep / no Wave Link unmute reorder
- Spec: `docs/superpowers/specs/2026-10-28-live-draft-recorder-first-design.md`
- Final paste remains WAV → STT → cleanup (unchanged)

---

### Task 1: Reorder startDictationSession + cancel load Task

**Files:**
- Modify: `macos/CarrotType/AppState.swift`

**Interfaces:**
- Produces: recording starts before live-draft await; `liveDraftStartTask` cancelled on cancel/finish/error paths.

- [ ] **Step 1: Add task handle**

Near other private Task properties:

```swift
private var liveDraftStartTask: Task<Void, Never>?
```

- [ ] **Step 2: Rewrite live-draft branch in `startDictationSession`**

Replace the block that awaits `startLiveDraftIfPossible` **before** `recorder.start()` with roughly:

```swift
clearLiveDraftText()
liveDraftStartTask?.cancel()
liveDraftStartTask = nil
recorder.onConvertedBuffer = nil

_ = try recorder.start(deviceUID: audioInput.selectedDeviceID)
invalidateCapsuleSequence()
menuBarMode = .recording
capsulePhase = .listening
hotkey.setEscapeCancelRegistered(true)

if liveDraftEnabled, activeSTTSupportsStreaming {
    let languageCode = appLanguage.effectiveLanguageCode
    liveDraftStartTask = Task { @MainActor [weak self] in
        guard let self else { return }
        let started = await self.pipeline.startLiveDraftIfPossible(
            languageCode: languageCode
        ) { [weak self] update in
            Task { @MainActor in
                self?.liveDraftConfirmed = update.confirmed
                self?.liveDraftVolatile = update.volatile
            }
        }
        guard !Task.isCancelled else {
            if started {
                await self.pipeline.cancelLiveDraft()
            }
            return
        }
        if started, self.menuBarMode == .recording {
            self.recorder.onConvertedBuffer = { [weak self] buffer in
                self?.pipeline.feedLiveDraft(buffer)
            }
        } else if !started {
            NSLog("CarrotType: live draft requested but streaming did not start; using file STT path")
        }
    }
}

if pushToTalkEnabled {
    hotkey.startPushToTalkReleaseMonitor()
    if !pttKeyHeld {
        await cancelDictationSession()
        return
    }
}
```

Keep the existing Wave Link unmute **before** this block (unchanged). Keep the outer `do/catch` so `recorder.start` failures still restore mute and clear state.

Remove the old sequential `await startLiveDraftIfPossible` + then `recorder.start` path.

- [ ] **Step 3: Cancel load on teardown**

In `cancelDictationSession`, `finishDictationSession` (early, before/with `cancelLiveDraft`), and the `catch` of `startDictationSession`:

```swift
liveDraftStartTask?.cancel()
liveDraftStartTask = nil
```

Ensure cancel still clears `onConvertedBuffer` and awaits `pipeline.cancelLiveDraft()` as today.

- [ ] **Step 4: Debug build**

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
cd macos && xcodegen generate && xcodebuild -project CarrotType.xcodeproj -scheme CarrotType -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath .derivedData-verify COMPILER_INDEX_STORE_ENABLE=NO build
```

Expected: `** BUILD SUCCEEDED **`

Manual (owner): live draft on, cold start after idle — speak immediately on hotkey; first words appear in final paste; Capsule may lag briefly then catch up.

- [ ] **Step 5: Commit**

```bash
git add macos/CarrotType/AppState.swift
git commit -m "Start dictation recorder before live-draft model load."
```

---

### Task 2: Docs + version 0.3.6

**Files:**
- Modify: `macos/project.yml`, `macos/CarrotType/Info.plist` → `0.3.6` / bump `CFBundleVersion` to `19`
- Modify: `docs/decisions/ADR-014-live-dictation-streaming.md`, `docs/specs/features/live-dictation-streaming.md`
- Modify: `docs/roadmap.md`, `docs/product-intent.md`, `.ai/workflow.md`, `.ai/memory.md`
- Create: `docs/github-release-notes-v0.3.6.md` (SHA TBD)

- [ ] **Step 1:** Note in ADR-014 / F-004: mic/WAV starts before Parakeet load; preview attaches when ready; paste still WAV.
- [ ] **Step 2:** Roadmap / product-intent / workflow for v0.3.6 focus.
- [ ] **Step 3:** Release notes What’s new: recorder-first live draft start (no eaten words during cold load).
- [ ] **Step 4: Commit**

```bash
git add macos/project.yml macos/CarrotType/Info.plist docs/ .ai/
git commit -m "Docs and version bump for v0.3.6 recorder-first live draft."
```

---

## Spec coverage

| Spec | Task |
|------|------|
| recorder before load | Task 1 |
| concurrent load + attach feed | Task 1 |
| fail → file-only, keep recording | Task 1 |
| cancel mid-load | Task 1 |
| unmute unchanged | Task 1 (no change) |
| no warm-keep | — |
| docs / 0.3.6 | Task 2 |
