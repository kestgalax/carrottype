import AppKit
import Carbon
import Combine
import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var menuBarMode: MenuBarMode = .needsSetup {
        didSet {
            updateLevelDecayTimer()
        }
    }
    /// Session chrome phase for Status Capsule (nil = hidden).
    @Published private(set) var capsulePhase: StatusCapsulePhase?
    /// Text shown while `capsulePhase == .transformResult` (ADR-012).
    @Published private(set) var transformResultText: String?
    /// Optional direction hint for Translate bindings (e.g. `EN → RU`).
    @Published private(set) var transformResultDirection: String?
    /// Brief Copy-button feedback while result capsule is open.
    @Published private(set) var transformResultCopiedFeedback = false
    @Published var showFirstRun: Bool
    @Published var lastSessionError: String?
    /// Live mic level while recording (level decay / future meters).
    @Published private(set) var recorderLiveLevel: Float = 0
    @Published private(set) var settingsVisible = false
    @Published var appLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(appLanguage.rawValue, forKey: AppLanguage.defaultsKey)
        }
    }
    /// When true, dictation result stays on the pasteboard after caret paste.
    @Published var retainDictationInClipboard: Bool {
        didSet {
            UserDefaults.standard.set(retainDictationInClipboard, forKey: Keys.retainClipboard)
        }
    }
    /// When true, the dictation hotkey is hold-to-talk (release commits). Default is toggle.
    @Published var pushToTalkEnabled: Bool {
        didSet {
            UserDefaults.standard.set(pushToTalkEnabled, forKey: Keys.pushToTalk)
        }
    }
    /// User opted into the live Settings mic meter (off by default to save energy).
    @Published var micMeterEnabled = false {
        didSet {
            if micMeterEnabled {
                startInputMeterIfPossible()
            } else {
                stopInputMeter()
            }
        }
    }
    /// When true, clear input mute for the dictation capture window and restore afterward (ADR-007).
    @Published var unmuteMicDuringDictation: Bool {
        didSet {
            UserDefaults.standard.set(unmuteMicDuringDictation, forKey: Keys.unmuteDuringDictation)
        }
    }
    var effectiveLocale: Locale { appLanguage.effectiveLocale }

    /// Selection-transform bindings (hotkey + kind + model); persisted via HotkeyService.
    var transformBindings: [TransformBinding] { hotkey.transformBindings }

    let modelManager: ModelManager
    let permissions: PermissionService
    let hotkey: HotkeyService
    let audioInput: AudioInputService
    let audioLevel: AudioLevelMonitor
    let pipeline: DictationPipeline

    private let recorder = AudioRecorder()
    private let micMute = MicMuteController()
    private let statusCapsule = StatusCapsuleController()
    private var cancellables = Set<AnyCancellable>()
    private var isProcessing = false
    private var levelDecayTimer: Timer?
    private var modelUnloadTask: Task<Void, Never>?
    /// Invalidates in-flight Writing → Inserted sleeps when a new session starts or cancels.
    private var capsuleSequenceToken = UUID()
    /// Clears the temporary "Copied" label on the transform result capsule.
    private var transformCopiedFeedbackTask: Task<Void, Never>?
    /// Counts nested Settings appearances so SwiftUI remounts do not clear the mic meter.
    private var settingsAppearanceCount = 0
    /// Walkie-talkie: true while the dictation chord is physically held (set on press, cleared on release).
    private var pttKeyHeld = false
    /// Walkie-talkie: guards against overlapping async starts on very fast press/release.
    private var pttStartInFlight = false

    init(
        modelManager: ModelManager? = nil,
        permissions: PermissionService? = nil,
        hotkey: HotkeyService? = nil,
        audioInput: AudioInputService? = nil,
        audioLevel: AudioLevelMonitor? = nil,
        defaults: UserDefaults = .standard
    ) {
        let modelManager = modelManager ?? ModelManager()
        let permissions = permissions ?? PermissionService()
        let hotkey = hotkey ?? HotkeyService()
        let audioInput = audioInput ?? AudioInputService()
        let audioLevel = audioLevel ?? AudioLevelMonitor()
        self.modelManager = modelManager
        self.permissions = permissions
        self.hotkey = hotkey
        self.audioInput = audioInput
        self.audioLevel = audioLevel
        self.pipeline = DictationPipeline(modelManager: modelManager)
        self.showFirstRun = !defaults.bool(forKey: "carrottype.didCompleteFirstRun")
        if let raw = defaults.string(forKey: AppLanguage.defaultsKey),
           let language = AppLanguage(rawValue: raw) {
            self.appLanguage = language
        } else {
            self.appLanguage = .system
        }
        self.retainDictationInClipboard = defaults.bool(forKey: Keys.retainClipboard)
        self.pushToTalkEnabled = defaults.bool(forKey: Keys.pushToTalk)
        self.unmuteMicDuringDictation = defaults.bool(forKey: Keys.unmuteDuringDictation)

        statusCapsule.attach(appState: self)
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.micMute.restoreSynchronouslyOnQuit()
            }
        }
        recorder.onLivePeak = { [weak self] peak in
            guard let self else { return }
            self.recorderLiveLevel = max(peak, self.recorderLiveLevel * 0.55)
        }

        modelManager.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
                self?.refreshMenuBarMode()
            }
            .store(in: &cancellables)

        permissions.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
                self?.refreshMenuBarMode()
            }
            .store(in: &cancellables)

        permissions.$accessibilityGranted
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
                self?.refreshMenuBarMode()
            }
            .store(in: &cancellables)

        permissions.$microphoneAuthorization
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
                self?.refreshMenuBarMode()
            }
            .store(in: &cancellables)

        audioInput.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        // Do NOT forward audioLevel.objectWillChange → AppState: the meter runs at ~30 Hz
        // and would keep MenuBarExtra / Settings recomputing while Settings is open.
        // Settings observes AudioLevelMonitor directly.

        hotkey.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        modelManager.$selectedSTTPackageID
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                Task { await self?.pipeline.unloadAll() }
            }
            .store(in: &cancellables)

        modelManager.$cleanupMode
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                Task { await self?.pipeline.unloadAll() }
            }
            .store(in: &cancellables)

        hotkey.setOnHotkey { [weak self] in
            self?.handleHotkeyPressed()
        }
        hotkey.setOnHotkeyReleased { [weak self] in
            self?.handleHotkeyReleased()
        }
        hotkey.setOnTransformHotkey { [weak self] bindingID in
            self?.handleTransformHotkeyPressed(bindingID: bindingID)
        }
        hotkey.setOnEscapeCancel { [weak self] in
            guard let self else { return }
            if self.capsulePhase == .transformResult {
                self.dismissTransformResult()
                return
            }
            Task { await self.cancelDictationSession() }
        }

        let preferredMode = Self.preferredTransformCleanupMode(modelManager: modelManager)
        let bindings = TransformBindingsStore.load(
            defaults: defaults,
            preferredCleanupMode: preferredMode
        )
        hotkey.replaceTransformBindings(bindings)

        refreshMenuBarMode()
    }

    var readiness: Readiness {
        Readiness.evaluate(
            microphoneGranted: permissions.microphoneGranted,
            accessibilityGranted: permissions.accessibilityGranted,
            sttReady: modelManager.activeSTTStatus == .ready,
            hasHardFailure: modelManager.hasHardFailure
        )
    }

    var remainingHints: [String] {
        let locale = effectiveLocale
        var hints: [String] = []
        if !permissions.microphoneGranted {
            hints.append(L10n.t("hint.microphone", locale: locale))
        }
        if !permissions.accessibilityGranted {
            hints.append(L10n.t("hint.accessibility", locale: locale))
        }
        if modelManager.activeSTTStatus != .ready {
            hints.append(L10n.t("hint.stt_model", locale: locale))
        }
        return hints
    }

    func refreshMenuBarMode() {
        if menuBarMode == .recording || menuBarMode == .processing || menuBarMode == .cleanup {
            return
        }
        switch readiness {
        case .ready:
            menuBarMode = .idle
        case .almost:
            menuBarMode = .needsSetup
        case .blocked:
            menuBarMode = .error
        }
    }

    func completeFirstRun(defaults: UserDefaults = .standard) {
        defaults.set(true, forKey: "carrottype.didCompleteFirstRun")
        showFirstRun = false
        refreshMenuBarMode()
    }

    func refreshPermissions() {
        permissions.refreshAndBumpUI()
        if permissions.microphoneGranted {
            audioInput.refreshDevices()
            if settingsVisible, micMeterEnabled {
                startInputMeterIfPossible()
            }
        } else if micMeterEnabled {
            micMeterEnabled = false
        } else {
            audioLevel.stop()
        }
        refreshMenuBarMode()
    }

    func settingsDidAppear() {
        settingsAppearanceCount += 1
        settingsVisible = true
        refreshPermissions()
        permissions.startMonitoring()
        if permissions.microphoneGranted {
            audioInput.refreshDevices()
        }
        // Restore meter if it was already on (e.g. Settings remount without a real close).
        if micMeterEnabled {
            startInputMeterIfPossible()
        }
        // Otherwise meter stays off until the user enables it — AVAudioEngine otherwise
        // keeps the input hardware awake for the whole Settings session.
    }

    func settingsDidDisappear() {
        settingsAppearanceCount = max(0, settingsAppearanceCount - 1)
        // Ignore intermediate disappear from SwiftUI remounts while Settings stays open.
        guard settingsAppearanceCount == 0 else { return }
        settingsVisible = false
        micMeterEnabled = false
        stopInputMeter()
    }

    func startInputMeterIfPossible() {
        guard settingsVisible, micMeterEnabled else {
            audioLevel.stop()
            return
        }
        guard permissions.microphoneGranted else {
            audioLevel.stop()
            return
        }
        guard menuBarMode != .recording, menuBarMode != .processing, menuBarMode != .cleanup else { return }
        audioLevel.start(deviceUID: audioInput.selectedDeviceID)
    }

    func stopInputMeter() {
        audioLevel.stop()
    }

    func selectAudioInput(_ id: String) {
        audioInput.selectDevice(id)
        if settingsVisible, micMeterEnabled {
            startInputMeterIfPossible()
        }
    }

    /// Toggle (default): press starts, press again commits.
    /// Walkie-talkie: hold records, release commits; repeat press while holding is ignored.
    private func handleHotkeyPressed() {
        if capsulePhase == .transformResult {
            dismissTransformResult()
        }

        if isProcessing || menuBarMode == .processing || menuBarMode == .cleanup {
            return
        }

        if pushToTalkEnabled {
            pttKeyHeld = true
            if menuBarMode == .recording || pttStartInFlight {
                return
            }
        }

        if menuBarMode == .recording {
            Task { await finishDictationSession() }
            return
        }

        guard readiness == .ready else {
            menuBarMode = .needsSetup
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        if pushToTalkEnabled {
            pttStartInFlight = true
            Task {
                await startDictationSession()
                pttStartInFlight = false
            }
        } else {
            Task { await startDictationSession() }
        }
    }

    /// Walkie-talkie only: release commits (or cancels if the session never got a hold).
    private func handleHotkeyReleased() {
        guard pushToTalkEnabled else { return }
        pttKeyHeld = false

        if isProcessing || menuBarMode == .processing || menuBarMode == .cleanup {
            return
        }
        guard menuBarMode == .recording else { return }
        Task { await finishDictationSession() }
    }

    /// Selection transform (ADR-012): read selection → LLM → show result in Capsule.
    private func handleTransformHotkeyPressed(bindingID: UUID) {
        if isProcessing || menuBarMode == .recording || menuBarMode == .processing || menuBarMode == .cleanup {
            return
        }
        guard let binding = hotkey.binding(id: bindingID) else { return }
        if capsulePhase == .transformResult {
            dismissTransformResult()
        }
        Task { await runSelectionTransform(binding: binding) }
    }

    /// Ready MLX modes for the transform model picker.
    var selectableTransformModes: [CleanupMode] {
        [.smart, .smartPlus, .gemma].filter { modelManager.isCleanupPackageReady(for: $0) }
    }

    var canAddTransformBinding: Bool {
        transformBindings.count < TransformBinding.maxCount
    }

    func preferredTransformCleanupMode() -> CleanupMode {
        Self.preferredTransformCleanupMode(modelManager: modelManager)
    }

    private static func preferredTransformCleanupMode(modelManager: ModelManager) -> CleanupMode {
        if modelManager.isCleanupPackageReady(for: .smartPlus) { return .smartPlus }
        for mode in [CleanupMode.smart, .gemma] where modelManager.isCleanupPackageReady(for: mode) {
            return mode
        }
        return .smart
    }

    func addTransformBinding() {
        guard canAddTransformBinding else { return }
        var binding = TransformBinding.makeDefault(cleanupMode: preferredTransformCleanupMode())
        binding.chord = nextAvailableTransformChord()
        var next = transformBindings
        next.append(binding)
        hotkey.replaceTransformBindings(next)
        objectWillChange.send()
    }

    func removeTransformBinding(id: UUID) {
        let next = transformBindings.filter { $0.id != id }
        hotkey.replaceTransformBindings(next)
        objectWillChange.send()
    }

    func updateTransformBinding(_ binding: TransformBinding) {
        var next = transformBindings
        guard let index = next.firstIndex(where: { $0.id == binding.id }) else { return }
        var updated = binding
        updated.ensureDistinctLanguages()
        if !updated.cleanupMode.usesMLXHelper {
            updated.cleanupMode = preferredTransformCleanupMode()
        }
        next[index] = updated
        hotkey.replaceTransformBindings(next)
        objectWillChange.send()
    }

    private func nextAvailableTransformChord() -> KeyChord {
        let used = Set(transformBindings.map(\.chord))
        let dictation = hotkey.chord
        let candidates: [KeyChord] = [
            .defaultTransform,
            KeyChord(keyCode: 39, carbonModifiers: UInt32(optionKey | shiftKey)),
            KeyChord(keyCode: 37, carbonModifiers: UInt32(optionKey)), // ⌥L
            KeyChord(keyCode: 35, carbonModifiers: UInt32(optionKey)), // ⌥P
            KeyChord(keyCode: 17, carbonModifiers: UInt32(optionKey)), // ⌥T
            KeyChord(keyCode: 16, carbonModifiers: UInt32(optionKey)), // ⌥Y
        ]
        for chord in candidates where chord != dictation && !used.contains(chord) {
            return chord
        }
        // Last resort: still assign default; capture UI will surface conflicts on change.
        return .defaultTransform
    }

    func presentTransformResult(_ text: String, direction: String? = nil) {
        invalidateCapsuleSequence()
        transformResultCopiedFeedback = false
        transformCopiedFeedbackTask?.cancel()
        transformResultText = text
        transformResultDirection = direction
        capsulePhase = .transformResult
        hotkey.setEscapeCancelRegistered(true)
    }

    func dismissTransformResult() {
        transformCopiedFeedbackTask?.cancel()
        transformCopiedFeedbackTask = nil
        transformResultCopiedFeedback = false
        transformResultText = nil
        transformResultDirection = nil
        if capsulePhase == .transformResult {
            capsulePhase = nil
        }
        // Escape is shared with dictation cancel — only keep it while recording.
        if menuBarMode != .recording {
            hotkey.setEscapeCancelRegistered(false)
        }
        statusCapsule.sync(phase: capsulePhase)
    }

    func copyTransformResult() {
        guard let text = transformResultText, !text.isEmpty else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        transformResultCopiedFeedback = true
        transformCopiedFeedbackTask?.cancel()
        transformCopiedFeedbackTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            guard let self, !Task.isCancelled else { return }
            self.transformResultCopiedFeedback = false
        }
    }

    private func runSelectionTransform(binding: TransformBinding) async {
        let locale = effectiveLocale

        guard permissions.accessibilityGranted else {
            lastSessionError = L10n.t("error.accessibility_denied", locale: locale)
            menuBarMode = .error
            refreshMenuBarMode()
            return
        }

        var mode = binding.cleanupMode
        if !mode.usesMLXHelper || !modelManager.isCleanupPackageReady(for: mode) {
            if let fallback = selectableTransformModes.first {
                mode = fallback
                var fixed = binding
                fixed.cleanupMode = fallback
                updateTransformBinding(fixed)
            } else {
                lastSessionError = L10n.t("error.transform_model_missing", locale: locale)
                menuBarMode = .error
                refreshMenuBarMode()
                return
            }
        }

        guard let modelDirectory = modelManager.cleanupModelDirectory(for: mode) else {
            lastSessionError = L10n.t("error.transform_model_missing", locale: locale)
            menuBarMode = .error
            refreshMenuBarMode()
            return
        }

        isProcessing = true
        lastSessionError = nil
        cancelScheduledModelUnload()
        invalidateCapsuleSequence()
        transformResultText = nil
        transformResultDirection = nil
        transformResultCopiedFeedback = false
        menuBarMode = .cleanup
        capsulePhase = .understanding
        defer {
            isProcessing = false
            if settingsVisible, micMeterEnabled { startInputMeterIfPossible() }
            refreshMenuBarMode()
            Task { await pipeline.unloadAll() }
        }

        do {
            let selected = try await SelectionTextService.readSelectedText()
            let instruction: String
            var direction: String?
            switch binding.kind {
            case .translate:
                let uiCode = locale.language.languageCode?.identifier ?? "en"
                let preferred = LanguagePairDetector.preferredTarget(
                    languageA: binding.languageA,
                    languageB: binding.languageB,
                    uiLanguageCode: uiCode
                )
                let flip = LanguagePairDetector.flip(
                    text: selected,
                    languageA: binding.languageA,
                    languageB: binding.languageB,
                    preferredTarget: preferred
                )
                instruction = LanguagePairDetector.translateInstruction(
                    targetCode: flip.targetCode,
                    uiLocale: locale
                )
                direction = LanguagePairDetector.directionLabel(
                    sourceCode: flip.sourceCode,
                    targetCode: flip.targetCode
                )
            case .custom:
                let trimmed = binding.customInstruction.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    lastSessionError = L10n.t("error.transform_empty_instruction", locale: locale)
                    clearCapsulePhase()
                    menuBarMode = .error
                    return
                }
                instruction = trimmed
            }

            let result = try await pipeline.transform(
                text: selected,
                mode: mode,
                modelDirectory: modelDirectory,
                instructions: instruction
            )
            lastSessionError = nil
            menuBarMode = .idle
            presentTransformResult(result, direction: direction)
        } catch {
            lastSessionError = error.localizedDescription
            clearCapsulePhase()
            menuBarMode = .error
        }
    }

    private func startDictationSession() async {
        guard readiness == .ready else {
            menuBarMode = .needsSetup
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        guard menuBarMode != .recording, !isProcessing else { return }

        if pushToTalkEnabled, !pttKeyHeld {
            return
        }

        lastSessionError = nil
        cancelScheduledModelUnload()
        audioLevel.stop()
        recorderLiveLevel = 0

        if unmuteMicDuringDictation {
            let name = audioInput.selectedDevice?.name ?? ""
            await micMute.beginDictationUnmute(
                deviceUID: audioInput.selectedDeviceID,
                deviceName: name
            )
        }

        if pushToTalkEnabled, !pttKeyHeld {
            await micMute.endDictationRestore()
            return
        }

        do {
            _ = try recorder.start(deviceUID: audioInput.selectedDeviceID)
            invalidateCapsuleSequence()
            menuBarMode = .recording
            capsulePhase = .listening
            hotkey.setEscapeCancelRegistered(true)
            if pushToTalkEnabled {
                hotkey.startPushToTalkReleaseMonitor()
                if !pttKeyHeld {
                    await cancelDictationSession()
                    return
                }
            }
        } catch {
            await micMute.endDictationRestore()
            lastSessionError = error.localizedDescription
            clearCapsulePhase()
            menuBarMode = .error
            if settingsVisible, micMeterEnabled { startInputMeterIfPossible() }
            refreshMenuBarMode()
        }
    }

    /// Escape (or soft silent stop): discard capture, no STT/paste.
    private func cancelDictationSession() async {
        guard menuBarMode == .recording, !isProcessing else { return }

        hotkey.stopPushToTalkReleaseMonitor()
        hotkey.setEscapeCancelRegistered(false)
        pttKeyHeld = false
        pttStartInFlight = false
        recorder.cancel()
        recorderLiveLevel = 0
        lastSessionError = nil
        await micMute.endDictationRestore()
        clearCapsulePhase()
        menuBarMode = .idle
        if settingsVisible, micMeterEnabled { startInputMeterIfPossible() }
        refreshMenuBarMode()
    }

    private func finishDictationSession() async {
        guard menuBarMode == .recording, !isProcessing else { return }

        isProcessing = true
        recorderLiveLevel = 0
        hotkey.stopPushToTalkReleaseMonitor()
        hotkey.setEscapeCancelRegistered(false)
        pttKeyHeld = false
        menuBarMode = .processing
        capsulePhase = .understanding
        defer {
            isProcessing = false
            recorderLiveLevel = 0
            if settingsVisible, micMeterEnabled { startInputMeterIfPossible() }
            refreshMenuBarMode()
            // Unload immediately: Parakeet/Qwen keep GB of RAM and FluidAudio worker state.
            Task { await pipeline.unloadAll() }
        }

        let audioURL: URL
        do {
            audioURL = try recorder.stop()
        } catch {
            await micMute.endDictationRestore()
            if case AudioRecorderError.silentOrTooShort = error {
                // Soft cancel: nothing useful was said — no red error, no paste.
                lastSessionError = nil
                clearCapsulePhase()
                menuBarMode = .idle
                return
            }
            lastSessionError = error.localizedDescription
            clearCapsulePhase()
            menuBarMode = .error
            return
        }

        // Remute as soon as capture ends — do not wait for STT/cleanup.
        await micMute.endDictationRestore()

        defer { try? FileManager.default.removeItem(at: audioURL) }

        do {
            let cleaned = try await pipeline.run(
                audioURL: audioURL,
                onPhase: { [weak self] phase in
                    Task { @MainActor in
                        guard let self else { return }
                        switch phase {
                        case .transcribing:
                            self.menuBarMode = .processing
                            self.capsulePhase = .understanding
                        case .cleaning:
                            self.menuBarMode = .cleanup
                            self.capsulePhase = .understanding
                        }
                    }
                }
            )
            try TextInsertionService.insertAtCaret(
                cleaned,
                retainInClipboard: retainDictationInClipboard
            )
            lastSessionError = nil
            menuBarMode = .idle
            await presentSuccessCapsuleSequence()
        } catch {
            lastSessionError = error.localizedDescription
            clearCapsulePhase()
            menuBarMode = .error
        }
    }

    private func clearCapsulePhase() {
        invalidateCapsuleSequence()
        transformCopiedFeedbackTask?.cancel()
        transformCopiedFeedbackTask = nil
        transformResultCopiedFeedback = false
        transformResultText = nil
        transformResultDirection = nil
        capsulePhase = nil
        if menuBarMode != .recording {
            hotkey.setEscapeCancelRegistered(false)
        }
        statusCapsule.sync(phase: nil)
    }

    private func invalidateCapsuleSequence() {
        capsuleSequenceToken = UUID()
    }

    /// Always Writing (~0.35s) → Inserted (~1s) → hide after a successful paste.
    private func presentSuccessCapsuleSequence() async {
        let token = UUID()
        capsuleSequenceToken = token
        capsulePhase = .writing
        try? await Task.sleep(nanoseconds: 350_000_000)
        guard capsuleSequenceToken == token else { return }
        capsulePhase = .inserted
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        guard capsuleSequenceToken == token else { return }
        capsulePhase = nil
    }

    private func updateLevelDecayTimer() {
        if menuBarMode == .recording {
            guard levelDecayTimer == nil else { return }
            let timer = Timer(timeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    guard let self, self.menuBarMode == .recording else { return }
                    self.recorderLiveLevel *= 0.88
                    if self.recorderLiveLevel < 0.02 { self.recorderLiveLevel = 0 }
                }
            }
            RunLoop.main.add(timer, forMode: .common)
            levelDecayTimer = timer
        } else {
            levelDecayTimer?.invalidate()
            levelDecayTimer = nil
            recorderLiveLevel = 0
        }
    }

    private func scheduleModelUnload() {
        cancelScheduledModelUnload()
        modelUnloadTask = Task { [weak self] in
            await self?.pipeline.unloadAll()
        }
    }

    private func cancelScheduledModelUnload() {
        modelUnloadTask?.cancel()
        modelUnloadTask = nil
    }

    /// Unload engines first so ggml / CoreML files are not locked on disk.
    func deleteModelPackage(_ packageID: String) {
        Task { @MainActor in
            await pipeline.unloadAll()
            modelManager.deletePackage(packageID)
            reloadTransformBindingsFromStore()
            if let message = modelManager.lastError {
                lastSessionError = message
            }
            refreshMenuBarMode()
        }
    }

    func deleteUnusedModelPackages() {
        Task { @MainActor in
            await pipeline.unloadAll()
            modelManager.deleteUnusedPackages()
            reloadTransformBindingsFromStore()
            if let message = modelManager.lastError {
                lastSessionError = message
            }
            refreshMenuBarMode()
        }
    }

    private func reloadTransformBindingsFromStore() {
        let preferred = preferredTransformCleanupMode()
        let bindings = TransformBindingsStore.load(
            defaults: .standard,
            preferredCleanupMode: preferred
        )
        hotkey.replaceTransformBindings(bindings)
        objectWillChange.send()
    }

    private enum Keys {
        static let retainClipboard = "carrottype.retainDictationInClipboard"
        static let pushToTalk = "carrottype.dictationPushToTalk"
        static let unmuteDuringDictation = "carrottype.unmuteMicDuringDictation"
    }
}

enum MenuBarMode {
    case idle
    case needsSetup
    case recording
    case processing
    case cleanup
    case error
}
