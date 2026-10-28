# Live draft cancel Copy + Settings hints Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** On Escape during a non-empty live-draft session, show a Copy/Close Capsule snapshot (5 s auto-dismiss or new session) instead of discarding the text; put General hotkey toggle hints under each toggle.

**Architecture:** Add `StatusCapsulePhase.liveDraftResult` that reuses transform result chrome. `AppState.cancelDictationSession` snapshots draft text before clearing, presents the result phase with a 5 s timer; Escape/Close/new dictation/transform dismiss it. General Settings captions move from section footer to per-toggle `Text` like Setup → Permissions.

**Tech Stack:** Swift / SwiftUI StatusCapsule / AppKit NSPasteboard / Localizable.xcstrings

## Global Constraints

- Branch: `feat/live-draft-cancel-copy` (from current `main` / v0.3.4).
- Ship as **v0.3.5** (bump `macos/project.yml` + `Info.plist` in docs/release task).
- Scope only: Escape + non-empty live draft → result Capsule; Settings hint layout; docs/notes. No mid-flight Copy, no cancel rescue without live draft, no prompt/LLM changes.
- Spec: `docs/superpowers/specs/2026-10-28-live-draft-cancel-copy-design.md`.

---

### Task 1: Capsule phase + clickable result UI

**Files:**
- Modify: `macos/CarrotType/Views/StatusCapsule.swift`

**Interfaces:**
- Produces: `StatusCapsulePhase.liveDraftResult`; panel accepts mouse when phase is `.transformResult` **or** `.liveDraftResult`; view shows `resultContent` for both; Copy/Close callbacks stay on AppState methods (wired in Task 2).

- [ ] **Step 1: Extend the phase enum**

```swift
enum StatusCapsulePhase: Equatable {
    case listening
    case understanding
    case writing
    case inserted
    case transformResult
    case liveDraftResult
}
```

Update the file header comment to mention both result phases.

- [ ] **Step 2: Make liveDraftResult clickable and sized like transform**

In `applyPanelInteraction`:

```swift
panel?.ignoresMouseEvents = !(phase == .transformResult || phase == .liveDraftResult)
```

In `StatusCapsuleGeometry.panelSize` / `origin`, treat `.liveDraftResult` the same as `.transformResult` (same fixed-ish result layout).

In `StatusCapsuleView.body`, show `resultContent` for both:

```swift
if phase == .transformResult || phase == .liveDraftResult {
    resultContent
} else if hasLiveDraft {
    liveDraftContent
} else {
    contentRow
    // ...
}
```

In `contentRow` `switch`, add `case .liveDraftResult: EmptyView()` (unreachable if body routes correctly) or omit by making switch exhaustive with a no-op label — prefer routing only via `resultContent` so switch never hits it; if compiler requires, use `EmptyView()`.

- [ ] **Step 3: Wire Copy/Close to draft-aware AppState APIs (stubs ok until Task 2)**

Change `onCopy` / `onClose` closures so the controller calls:

```swift
onCopy: { [weak self] in self?.appState?.copyCapsuleResult() },
onClose: { [weak self] in self?.appState?.dismissCapsuleResult() },
```

(`copyCapsuleResult` / `dismissCapsuleResult` will handle both transform and live-draft in Task 2; temporarily you may keep transform-only names and rename in Task 2 — pick one naming and use it consistently.)

Also subscribe Combine to any new `@Published` snapshot / feedback fields once Task 2 adds them (or reuse `transformResultText` + `transformResultCopiedFeedback` for the live-draft snapshot — **preferred for this mini-patch**: store live-draft cancel text in the same `transformResultText` / feedback fields while `phase == .liveDraftResult`, with `direction == nil`). If reusing those fields, Combine already updates; only phase + clickable changes are required in this task.

**Preferred reuse (YAGNI):** present live-draft cancel via existing `presentTransformResult`-style path but set `capsulePhase = .liveDraftResult` and `direction = nil`. Then Task 2 mostly changes cancel + dismiss Escape handling.

- [ ] **Step 4: Debug build compiles**

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
cd macos && xcodegen generate && xcodebuild -project CarrotType.xcodeproj -scheme CarrotType -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath .derivedData-verify COMPILER_INDEX_STORE_ENABLE=NO build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add macos/CarrotType/Views/StatusCapsule.swift
git commit -m "Add liveDraftResult Capsule phase with Copy/Close chrome."
```

---

### Task 2: AppState cancel → snapshot + dismiss/timer

**Files:**
- Modify: `macos/CarrotType/AppState.swift`

**Interfaces:**
- Consumes: `StatusCapsulePhase.liveDraftResult`; existing `transformResultText`, `transformResultCopiedFeedback`, `copyTransformResult`, `dismissTransformResult`.
- Produces: Escape cancel with non-empty draft presents `.liveDraftResult`; 5 s auto-dismiss; second Escape / Close / new dictation / transform clears it; empty draft cancel unchanged.

- [ ] **Step 1: Helper to build draft snapshot**

Near `clearLiveDraftText()`:

```swift
private func liveDraftSnapshotText() -> String {
    [liveDraftConfirmed, liveDraftVolatile]
        .filter { !$0.isEmpty }
        .joined(separator: " ")
        .trimmingCharacters(in: .whitespacesAndNewlines)
}
```

- [ ] **Step 2: Present / dismiss live-draft result**

Add a dismiss timer property:

```swift
private var liveDraftResultDismissTask: Task<Void, Never>?
```

Add:

```swift
func presentLiveDraftResult(_ text: String) {
    invalidateCapsuleSequence()
    liveDraftResultDismissTask?.cancel()
    transformCopiedFeedbackTask?.cancel()
    transformResultCopiedFeedback = false
    transformResultText = text
    transformResultDirection = nil
    capsulePhase = .liveDraftResult
    hotkey.setEscapeCancelRegistered(true)
    liveDraftResultDismissTask = Task { @MainActor [weak self] in
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        guard let self, !Task.isCancelled else { return }
        if self.capsulePhase == .liveDraftResult {
            self.dismissLiveDraftResult()
        }
    }
}

func dismissLiveDraftResult() {
    liveDraftResultDismissTask?.cancel()
    liveDraftResultDismissTask = nil
    transformCopiedFeedbackTask?.cancel()
    transformCopiedFeedbackTask = nil
    transformResultCopiedFeedback = false
    transformResultText = nil
    transformResultDirection = nil
    if capsulePhase == .liveDraftResult {
        capsulePhase = nil
    }
    if menuBarMode != .recording {
        hotkey.setEscapeCancelRegistered(false)
    }
    statusCapsule.sync(phase: capsulePhase)
}
```

Update Escape handler:

```swift
hotkey.setOnEscapeCancel { [weak self] in
    guard let self else { return }
    if self.capsulePhase == .transformResult {
        self.dismissTransformResult()
        return
    }
    if self.capsulePhase == .liveDraftResult {
        self.dismissLiveDraftResult()
        return
    }
    Task { await self.cancelDictationSession() }
}
```

Reuse `copyTransformResult()` for Copy (same pasteboard + feedback) — both result phases share `transformResultText`.

Update `clearCapsulePhase()` to cancel `liveDraftResultDismissTask` as well.

- [ ] **Step 3: Branch `cancelDictationSession`**

Replace the tail that always clears the Capsule:

```swift
private func cancelDictationSession() async {
    guard menuBarMode == .recording, !isProcessing else { return }

    let draft = liveDraftSnapshotText()
    let showDraftResult = liveDraftEnabled && activeSTTSupportsStreaming && !draft.isEmpty

    hotkey.stopPushToTalkReleaseMonitor()
    // Keep Escape registered if we will show liveDraftResult.
    if !showDraftResult {
        hotkey.setEscapeCancelRegistered(false)
    }
    pttKeyHeld = false
    pttStartInFlight = false
    recorder.cancel()
    recorder.onConvertedBuffer = nil
    recorderLiveLevel = 0
    await pipeline.cancelLiveDraft()
    clearLiveDraftText()
    lastSessionError = nil
    await micMute.endDictationRestore()
    menuBarMode = .idle
    if settingsVisible, micMeterEnabled { startInputMeterIfPossible() }
    refreshMenuBarMode()

    if showDraftResult {
        presentLiveDraftResult(draft)
    } else {
        clearCapsulePhase()
    }
}
```

- [ ] **Step 4: Clear result when starting dictation or transform**

At the start of dictation start (where transform result is already dismissed) and transform start, also:

```swift
if capsulePhase == .liveDraftResult {
    dismissLiveDraftResult()
}
```

Search existing `dismissTransformResult()` call sites before recording/transform and mirror for live draft (or fold both into `dismissCapsuleResult()` that dismisses whichever result phase is active).

Recommended thin wrapper:

```swift
func dismissAnyResultCapsule() {
    if capsulePhase == .transformResult { dismissTransformResult() }
    if capsulePhase == .liveDraftResult { dismissLiveDraftResult() }
}
```

Call `dismissAnyResultCapsule()` wherever transform result was dismissed before a new session.

- [ ] **Step 5: Debug build + manual checklist**

Build as in Task 1. Manual (owner or agent with GUI):

1. Live draft on + Parakeet → speak → Escape with text → Capsule shows text + Copy/Close; no paste.
2. Copy → clipboard has snapshot; “Скопировано”.
3. Wait 5 s → Capsule hides.
4. Repeat → Close / Escape → hides immediately.
5. Escape with text → start new dictation → Listening replaces result.
6. Empty cancel / live draft off → no result Capsule (current behavior).

- [ ] **Step 6: Commit**

```bash
git add macos/CarrotType/AppState.swift macos/CarrotType/Views/StatusCapsule.swift
git commit -m "Show Copy capsule when Escape cancels a live draft."
```

---

### Task 3: General Settings per-toggle hints + Escape copy

**Files:**
- Modify: `macos/CarrotType/Views/Settings/GeneralSettingsPane.swift`
- Modify: `macos/CarrotType/Resources/Localizable.xcstrings` (retain / PTT / live-draft footers)

**Interfaces:**
- Consumes: existing L10n keys; Setup caption pattern (`.font(.caption)` + `.foregroundStyle(.secondary)`).

- [ ] **Step 1: Restructure Hotkey section**

Replace combined footer with per-control captions:

```swift
Section {
    HotkeySettingsRow(hotkey: hotkey, target: .dictation)
    if hotkey.isRecording, hotkey.captureTarget == .dictation {
        Text(L10n.t("hotkey.footer_recording", locale: locale))
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    Toggle(L10n.t("hotkey.push_to_talk", locale: locale), isOn: $appState.pushToTalkEnabled)
    Text(L10n.t("hotkey.push_to_talk_footer", locale: locale))
        .font(.caption)
        .foregroundStyle(.secondary)

    Toggle(L10n.t("hotkey.retain_clipboard", locale: locale), isOn: $appState.retainDictationInClipboard)
    Text(L10n.t("hotkey.retain_clipboard_footer", locale: locale))
        .font(.caption)
        .foregroundStyle(.secondary)

    Toggle(L10n.t("hotkey.live_draft", locale: locale), isOn: $appState.liveDraftEnabled)
        .disabled(!appState.activeSTTSupportsStreaming)
    Text(liveDraftFooter)
        .font(.caption)
        .foregroundStyle(.secondary)
} header: {
    Text(L10n.t("hotkey.section", locale: locale))
}
```

Remove unused `hotkeyFooter` computed property (or keep only if still referenced).

Always show PTT footer under PTT (not only when PTT is on). Retain footer always under retain toggle. Live draft footer always under live-draft toggle.

- [ ] **Step 2: Update Escape copy in footers (EN + RU)**

`hotkey.retain_clipboard_footer`:

- EN: keep clipboard / caret sentences; change Escape sentence to:  
  `While recording, Escape cancels without pasting. If live draft showed text, the status pill keeps it briefly so you can Copy.`
- RU:  
  `Во время записи Escape отменяет диктовку без вставки. Если в плашке уже был черновик, она ненадолго останется — можно Скопировать.`

`hotkey.push_to_talk_footer`: mention the same Escape + live-draft Copy briefly (one short clause), EN+RU.

`hotkey.live_draft_footer`: add one sentence that Escape keeps a Copy-able snapshot for a few seconds, EN+RU.

- [ ] **Step 3: Visual check in Settings**

Debug run → General → Hotkey: each toggle has its own caption underneath (like Permissions).

- [ ] **Step 4: Commit**

```bash
git add macos/CarrotType/Views/Settings/GeneralSettingsPane.swift macos/CarrotType/Resources/Localizable.xcstrings
git commit -m "Place General hotkey hints under each toggle."
```

---

### Task 4: Docs + version bump for v0.3.5

**Files:**
- Modify: `macos/project.yml` (`CFBundleShortVersionString` / marketing → `0.3.5`)
- Modify: `macos/CarrotType/Info.plist` if it still embeds version (keep in sync with yml)
- Modify: `docs/decisions/ADR-014-live-dictation-streaming.md` (Escape cancel → Copy capsule note)
- Modify: `docs/specs/features/live-dictation-streaming.md` (F-004)
- Modify: `docs/specs/ux-setup-status.md` (optional one-liner on Capsule cancel)
- Modify: `docs/roadmap.md`, `docs/product-intent.md`, `.ai/workflow.md`, `.ai/memory.md`
- Create: `docs/github-release-notes-v0.3.5.md` (SHA placeholder until DMG)

- [ ] **Step 1: Bump version to 0.3.5** in `project.yml` + `Info.plist`.

- [ ] **Step 2: ADR-014 / F-004** — document Escape with non-empty live draft presents Copy/Close Capsule, 5 s auto-dismiss, new session clears; paste still only on normal stop.

- [ ] **Step 3: Roadmap / product-intent / memory** — mark v0.3.5 focus; release notes draft with What’s new: cancel Copy capsule + Settings hint layout.

- [ ] **Step 4: Commit**

```bash
git add macos/project.yml macos/CarrotType/Info.plist docs/ .ai/
git commit -m "Docs and version bump for v0.3.5 live-draft cancel Copy."
```

---

## Spec coverage (self-review)

| Spec item | Task |
|-----------|------|
| Escape + non-empty live draft → Copy/Close Capsule | Task 2 |
| No paste on that cancel | Task 2 |
| 5 s auto-dismiss | Task 2 |
| New dictation clears | Task 2 |
| Soft empty cancel unchanged | Task 2 |
| Normal stop unchanged | (no code path change) |
| Reuse transform chrome | Task 1 |
| Mid-flight Copy out of scope | — |
| Per-toggle Settings hints | Task 3 |
| Escape copy in footers | Task 3 |
| v0.3.5 docs | Task 4 |
