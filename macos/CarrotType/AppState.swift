import AppKit
import Carbon
import Combine
import Foundation

/// Everything pinned at dictation start. Mode and effective preview are captured here.
struct DictationSessionSettings {
    let pipeline: DictationPipelineConfiguration
    let destination: DictationDelivery
    let deviceUID: String
    let deviceName: String
    let unmute: Bool
    let liveDraft: Bool
    let holdToTalk: Bool
    let islandMode: DynamicIslandMode
}

typealias AppDictationSession = DictationSessionCoordinator<DictationSessionSettings, FormattedDictation>

@MainActor
final class AppState: ObservableObject {
    let launchAtLogin = LaunchAtLoginService()
    @Published var menuBarMode: MenuBarMode = .needsSetup {
        didSet {
            updateLevelDecayTimer()
        }
    }
    /// Session chrome phase for Status Capsule (nil = hidden). Logical even when a mode suppresses the panel.
    @Published private(set) var capsulePhase: StatusCapsulePhase?
    /// `.understanding` is shared by dictation and transform; results/presentation need the owner.
    @Published private(set) var capsuleOperation: DynamicIslandOperation = .dictation
    /// Mode captured at dictation start; settings changes apply to the next session.
    @Published private(set) var activeDictationMode: DynamicIslandMode = .full
    /// Text shown while `capsulePhase` is `.transformResult` or `.liveDraftResult`.
    @Published private(set) var transformResultText: String?
    /// Optional direction hint for Translate bindings (e.g. `EN → RU`).
    @Published private(set) var transformResultDirection: String?
    /// Brief Copy-button feedback while result capsule is open.
    @Published private(set) var transformResultCopiedFeedback = false
    @Published private(set) var isSetupTrialActive = false
    @Published var setupTrialText = ""
    @Published private(set) var setupTrialFormatting: FormattingOutcome?
    @Published private(set) var hasCompletedSetupTrial: Bool
    @Published private(set) var lastFormattingOutcome: FormattingOutcome?
    /// Presentation mode captured by the last completed caret dictation.
    @Published private(set) var lastDictationIslandMode: DynamicIslandMode?
    @Published private(set) var isSetupTrialCancelling = false
    private let setupDefaults: UserDefaults
    private var didPresentFirstRunThisLaunch = false
    @Published var showFirstRun: Bool
    @Published var lastSessionError: String?
    /// One completed dictation in RAM only; never persisted or cleared by a cancelled next session.
    @Published private(set) var lastDictationText: String?
    /// Live mic level while recording (level decay / future meters).
    @Published private(set) var recorderLiveLevel: Float = 0
    @Published private(set) var settingsVisible = false
    @Published var appLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(appLanguage.rawValue, forKey: AppLanguage.defaultsKey)
        }
    }
    @Published var appTheme: AppTheme {
        didSet {
            setupDefaults.set(appTheme.rawValue, forKey: AppTheme.defaultsKey)
            NSApplication.shared.appearance = appTheme.appearance
        }
    }
    /// Dictation status presentation: full capsule (default), minimal indicator, or menu bar only.
    @Published var dynamicIslandMode: DynamicIslandMode {
        didSet {
            dynamicIslandMode.save(defaults: setupDefaults)
        }
    }
    @Published var dictationRules: DictationRules {
        didSet {
            if dictationRules != dictationRules.normalized { dictationRules = dictationRules.normalized }
            dictationRules.save(defaults: setupDefaults)
        }
    }
    @Published private(set) var isFormattingTrialRunning = false
    @Published private(set) var formattingTrialResult: String?
    @Published private(set) var formattingTrialOutcome: FormattingOutcome?
    @Published private(set) var formattingTrialError: String?
    private var formattingTrialTask: Task<Void, Never>?

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
    /// Show confirmed + volatile draft in the Status Capsule while speaking (ADR-014). Default off.
    @Published var liveDraftEnabled: Bool {
        didSet {
            UserDefaults.standard.set(liveDraftEnabled, forKey: Keys.liveDraft)
        }
    }
    /// After live-draft stop, optionally re-run offline STT on the session WAV. Default off.
    @Published var offlineSecondPassAfterLiveDraft: Bool {
        didSet {
            UserDefaults.standard.set(offlineSecondPassAfterLiveDraft, forKey: Keys.offlineSecondPass)
        }
    }
    /// Live draft text for the capsule (confirmed = stable colour, volatile = faded tail).
    @Published private(set) var liveDraftConfirmed = ""
    @Published private(set) var liveDraftVolatile = ""
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
    /// Opt-in local usage counts (ADR-013). Default off — no writes until enabled.
    @Published var statsCollectionEnabled: Bool {
        didSet {
            UserDefaults.standard.set(statsCollectionEnabled, forKey: Keys.statsCollection)
        }
    }
    /// Typing speed used only to estimate time saved (not measured).
    @Published var typingSpeedWPM: Int {
        didSet {
            let clamped = UsageStatsEstimate.clampedWPM(typingSpeedWPM)
            if clamped != typingSpeedWPM {
                typingSpeedWPM = clamped
                return
            }
            UserDefaults.standard.set(clamped, forKey: Keys.typingSpeedWPM)
        }
    }
    var effectiveLocale: Locale { appLanguage.effectiveLocale }

    /// Selection-transform bindings (hotkey + kind + model); persisted via HotkeyService.
    var transformBindings: [TransformBinding] { hotkey.transformBindings }

    let updates = AppUpdateService()
    private let sessionDependenciesFactory: (@MainActor () -> AppDictationSession.Dependencies)?
    private lazy var session = makeSessionCoordinator()
    private var restoreMuteOnQuit: (() -> Void)?
    private var cancelledDraftToPresent: String?
    private var transformTask: Task<Void, Never>?
    private var terminationTask: Task<Void, Never>?
    private var isTerminating = false

    let modelManager: ModelManager
    let permissions: PermissionService
    let hotkey: HotkeyService
    let audioInput: AudioInputService
    let audioLevel: AudioLevelMonitor
    let pipeline: DictationPipeline
    let usageStats: UsageStatsStore

    private let statusCapsule = StatusCapsuleController()
    private var cancellables = Set<AnyCancellable>()
    private var isProcessing = false
    private var levelDecayTimer: Timer?
    /// Invalidates in-flight Writing → Inserted sleeps when a new session starts or cancels.
    private var capsuleSequenceToken = UUID()
    /// Clears the temporary "Copied" label on the transform result capsule.
    private var transformCopiedFeedbackTask: Task<Void, Never>?
    /// Hides the live-draft snapshot capsule after 5 seconds.
    private var liveDraftResultDismissTask: Task<Void, Never>?
    /// Counts nested Settings appearances so SwiftUI remounts do not clear the mic meter.
    private var settingsAppearanceCount = 0
    /// Walkie-talkie: true while the dictation chord is physically held (set on press, cleared on release).
    private var pttKeyHeld = false

    init(
        modelManager: ModelManager? = nil,
        permissions: PermissionService? = nil,
        hotkey: HotkeyService? = nil,
        audioInput: AudioInputService? = nil,
        audioLevel: AudioLevelMonitor? = nil,
        usageStats: UsageStatsStore? = nil,
        defaults: UserDefaults = .standard,
        sessionDependenciesFactory: (@MainActor () -> AppDictationSession.Dependencies)? = nil
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
        self.usageStats = usageStats ?? UsageStatsStore()
        self.setupDefaults = defaults
        self.sessionDependenciesFactory = sessionDependenciesFactory
        self.appTheme = AppTheme.load(defaults: defaults)
        self.dynamicIslandMode = DynamicIslandMode.load(defaults: defaults)
        self.dictationRules = DictationRules.load(defaults: defaults)
        self.hasCompletedSetupTrial = defaults.bool(forKey: "carrottype.didCompleteSetupTrial")
        self.showFirstRun = !defaults.bool(forKey: "carrottype.didCompleteFirstRun")
        if let raw = defaults.string(forKey: AppLanguage.defaultsKey),
           let language = AppLanguage(rawValue: raw) {
            self.appLanguage = language
        } else {
            self.appLanguage = .system
        }
        self.retainDictationInClipboard = defaults.bool(forKey: Keys.retainClipboard)
        self.pushToTalkEnabled = defaults.bool(forKey: Keys.pushToTalk)
        self.liveDraftEnabled = defaults.bool(forKey: Keys.liveDraft)
        self.offlineSecondPassAfterLiveDraft = defaults.bool(forKey: Keys.offlineSecondPass)
        self.unmuteMicDuringDictation = defaults.bool(forKey: Keys.unmuteDuringDictation)
        self.statsCollectionEnabled = defaults.bool(forKey: Keys.statsCollection)
        if defaults.object(forKey: Keys.typingSpeedWPM) != nil {
            self.typingSpeedWPM = UsageStatsEstimate.clampedWPM(defaults.integer(forKey: Keys.typingSpeedWPM))
        } else {
            self.typingSpeedWPM = UsageStatsEstimate.defaultWPM
        }

        NSApplication.shared.appearance = appTheme.appearance
        _ = session
        statusCapsule.attach(appState: self)
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.restoreMuteOnQuit?()
            }
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
                self?.session.unloadWhenIdle()
            }
            .store(in: &cancellables)

        modelManager.$cleanupMode
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.session.unloadWhenIdle()
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
            if self.capsulePhase == .transformResult || self.capsulePhase == .dictationRecovery {
                self.dismissTransformResult()
                return
            }
            if self.capsulePhase == .liveDraftResult {
                self.dismissLiveDraftResult()
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

    /// Active STT package can drive live draft (Parakeet v3 / Ultra).
    var activeSTTSupportsStreaming: Bool {
        modelManager.selectedSTTSupportsStreaming
    }

    /// Single presentation decision used by the capsule controller and native fixtures.
    var islandPresentation: DynamicIslandPresentation {
        DynamicIslandPolicy.presentation(
            phase: capsulePhase,
            operation: capsuleOperation,
            mode: activeDictationMode
        )
    }

    /// Light fallback must remain discoverable when the status panel is suppressed.
    var showsSuppressedFallbackWarning: Bool {
        DynamicIslandPolicy.showsFallbackWarning(
            mode: lastDictationIslandMode ?? dynamicIslandMode,
            usedFallback: lastFormattingOutcome?.usedFallback == true
        )
    }

    func refreshMenuBarMode() {
        if menuBarMode == .recording || menuBarMode == .processing || menuBarMode == .cleanup {
            return
        }
        switch readiness {
        case .ready:
            menuBarMode = lastSessionError == nil && modelManager.lastErrorMessage == nil ? .idle : .error
        case .almost:
            menuBarMode = .needsSetup
        case .blocked:
            menuBarMode = .error
        }
    }

    func takeFirstRunPresentationRequest() -> Bool {
        guard showFirstRun, !didPresentFirstRunThisLaunch else { return false }
        didPresentFirstRunThisLaunch = true
        return true
    }

    func completeFirstRun(defaults: UserDefaults? = nil) {
        (defaults ?? setupDefaults).set(true, forKey: "carrottype.didCompleteFirstRun")
        showFirstRun = false
        refreshMenuBarMode()
    }

    var setupProgress: SetupProgress {
        SetupProgress(microphone: permissions.microphoneGranted,
                      accessibility: permissions.accessibilityGranted,
                      model: modelManager.activeSTTStatus == .ready, trial: hasCompletedSetupTrial)
    }

    var canStartSetupTrial: Bool {
        readiness == .ready && !updates.installationGate.isBusy && !updates.installationGate.isInstalling
    }

    func startSetupTrial() {
        guard !isTerminating else { return }
        guard readiness == .ready else { return }
        _ = session.start(dictationSettings(destination: .setupTrial))
    }

    func finishSetupTrial() {
        guard isSetupTrialActive else { return }
        session.finish()
    }

    func cancelSetupTrial() {
        guard isSetupTrialActive else { return }
        session.cancel()
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
        cancelSetupTrial()
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
        guard !isTerminating else { return }
        if isSetupTrialActive { session.finish(); return }
        let hold = session.configuration?.holdToTalk ?? pushToTalkEnabled
        if session.isActive {
            if !hold { session.finish() }
            return
        }
        guard !isProcessing else { return }
        dismissAnyResultCapsule()
        guard readiness == .ready else {
            menuBarMode = .needsSetup
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        pttKeyHeld = hold
        _ = startDictationSession(destination: .caret)
    }

    /// Shared start path; tests bypass readiness with the same captured settings/coordinator.
    @discardableResult
    func startDictationSession(destination: DictationDelivery) -> Bool {
        let settings = dictationSettings(destination: destination)
        dismissAnyResultCapsule()
        pttKeyHeld = settings.holdToTalk
        return session.start(settings)
    }

    private func handleHotkeyReleased() {
        guard session.configuration?.holdToTalk == true else { return }
        pttKeyHeld = false
        if session.phase == .starting { session.cancel() }
        else { finishDictationSession() }
    }

    /// Shared finish path; tests use the real coordinator teardown with fake adapters.
    func finishDictationSession() {
        session.finish()
    }

    /// Selection transform (ADR-012): read selection → LLM → show result in Capsule.
    private func handleTransformHotkeyPressed(bindingID: UUID) {
        guard !isTerminating else { return }
        if isProcessing || menuBarMode == .recording || menuBarMode == .processing || menuBarMode == .cleanup {
            return
        }
        guard let binding = hotkey.binding(id: bindingID) else { return }
        dismissAnyResultCapsule()
        guard !updates.installationGate.isBusy, !session.isActive,
              let reservation = updates.installationGate.beginOperation() else { return }
        transformTask = Task { await runSelectionTransform(binding: binding, updateReservation: reservation) }
    }

    /// Ready MLX modes for the transform model picker.
    var selectableTransformModes: [CleanupMode] {
        [.smart, .gemma].filter { modelManager.isCleanupPackageReady(for: $0) }
    }

    /// Legacy is visible/runnable only for an existing binding already using it.
    func transformModes(for requested: CleanupMode) -> [CleanupMode] {
        var modes = selectableTransformModes
        if requested == .smartPlus, modelManager.isCleanupPackageReady(for: .smartPlus) { modes.append(.smartPlus) }
        return modes
    }

    var canAddTransformBinding: Bool {
        transformBindings.count < TransformBinding.maxCount
    }

    func preferredTransformCleanupMode() -> CleanupMode {
        Self.preferredTransformCleanupMode(modelManager: modelManager)
    }

    private static func preferredTransformCleanupMode(modelManager: ModelManager) -> CleanupMode {
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

    func presentLiveDraftResult(_ text: String) {
        invalidateCapsuleSequence()
        liveDraftResultDismissTask?.cancel()
        transformCopiedFeedbackTask?.cancel()
        transformResultCopiedFeedback = false
        transformResultText = text
        transformResultDirection = nil
        capsuleOperation = .dictation
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
        statusCapsule.sync()
    }

    func dismissAnyResultCapsule() {
        if capsulePhase == .transformResult || capsulePhase == .dictationRecovery { dismissTransformResult() }
        if capsulePhase == .liveDraftResult { dismissLiveDraftResult() }
    }

    func presentTransformResult(_ text: String, direction: String? = nil) {
        invalidateCapsuleSequence()
        transformResultCopiedFeedback = false
        transformCopiedFeedbackTask?.cancel()
        transformResultText = text
        transformResultDirection = direction
        capsuleOperation = .transform
        capsulePhase = .transformResult
        hotkey.setEscapeCancelRegistered(true)
    }

    /// Production paste-failure recovery; result chrome stays available in every island mode.
    func presentDictationRecovery(_ text: String) {
        presentTransformResult(text, direction: L10n.t("recovery.paste_failed", locale: effectiveLocale))
        capsuleOperation = .dictation
        capsulePhase = .dictationRecovery
    }

    func dismissTransformResult() {
        transformCopiedFeedbackTask?.cancel()
        transformCopiedFeedbackTask = nil
        transformResultCopiedFeedback = false
        transformResultText = nil
        transformResultDirection = nil
        if capsulePhase == .transformResult || capsulePhase == .dictationRecovery {
            capsulePhase = nil
        }
        // Escape is shared with dictation cancel — only keep it while recording.
        if menuBarMode != .recording {
            hotkey.setEscapeCancelRegistered(false)
        }
        statusCapsule.sync()
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

    /// Transform owns `.understanding`; its status must stay visible even in minimal/menu-only modes.
    func beginTransformPresentation() {
        isProcessing = true
        invalidateCapsuleSequence()
        transformResultText = nil
        transformResultDirection = nil
        transformResultCopiedFeedback = false
        menuBarMode = .cleanup
        capsuleOperation = .transform
        capsulePhase = .understanding
    }

    func endTransformPresentation() {
        isProcessing = false
        if settingsVisible, micMeterEnabled { startInputMeterIfPossible() }
        refreshMenuBarMode()
    }

    private func runSelectionTransform(binding: TransformBinding, updateReservation: UUID) async {
        defer {
            transformTask = nil
            updates.installationGate.endOperation(updateReservation)
        }
        let locale = effectiveLocale

        guard permissions.accessibilityGranted else {
            lastSessionError = L10n.t("error.accessibility_denied", locale: locale)
            menuBarMode = .error
            refreshMenuBarMode()
            return
        }

        guard let mode = TransformModelSelection.resolve(
            requested: binding.cleanupMode, available: transformModes(for: binding.cleanupMode)
        ) else {
            lastSessionError = L10n.t("error.transform_model_missing", locale: locale)
            menuBarMode = .error
            refreshMenuBarMode()
            return
        }
        if mode != binding.cleanupMode {
            var fixed = binding
            fixed.cleanupMode = mode
            updateTransformBinding(fixed)
        }

        guard let modelDirectory = modelManager.cleanupModelDirectory(for: mode) else {
            lastSessionError = L10n.t("error.transform_model_missing", locale: locale)
            menuBarMode = .error
            refreshMenuBarMode()
            return
        }

        beginTransformPresentation()
        defer {
            endTransformPresentation()
            // The transform owns the gate until its awaited unload below.
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
            recordTransformIfEnabled(binding: binding)
        } catch {
            lastSessionError = error.localizedDescription
            clearCapsulePhase()
            menuBarMode = .error
        }
        await pipeline.unloadAll()
    }

    private func dictationSettings(destination: DictationDelivery) -> DictationSessionSettings {
        var configuration = pipeline.snapshotConfiguration()
        configuration.rules = dictationRules.normalized
        let mode = dynamicIslandMode
        return DictationSessionSettings(
            pipeline: configuration,
            destination: destination,
            deviceUID: audioInput.selectedDeviceID,
            deviceName: audioInput.selectedDevice?.name ?? "",
            unmute: unmuteMicDuringDictation,
            liveDraft: DynamicIslandPolicy.effectivePreview(
                mode: mode,
                savedLiveDraft: liveDraftEnabled,
                supportsStreaming: configuration.supportsStreaming
            ),
            holdToTalk: destination == .caret && pushToTalkEnabled,
            islandMode: mode
        )
    }

    var canRunFormattingTrial: Bool {
        !updates.installationGate.isBusy && !updates.installationGate.isInstalling && !isTerminating
    }

    /// Text in RAM only. Holds exclusive operation lease through helper teardown.
    func runFormattingTrial(_ input: String) {
        guard canRunFormattingTrial, !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              input.count <= 6000, let lease = updates.installationGate.beginOperation() else { return }
        let mode = modelManager.cleanupMode
        let directory = modelManager.cleanupModelDirectory()
        let rules = dictationRules.normalized
        isFormattingTrialRunning = true
        formattingTrialResult = nil; formattingTrialError = nil; formattingTrialOutcome = nil
        formattingTrialTask = Task { [self] in
            do {
                let result = try await pipeline.formatText(input, mode: mode, directory: directory, rules: rules)
                try Task.checkCancellation()
                formattingTrialResult = result.text
                formattingTrialOutcome = result.formatting
            } catch is CancellationError {
                formattingTrialResult = nil
            } catch {
                formattingTrialError = L10n.t("error.cleanup_failed", locale: effectiveLocale)
            }
            await pipeline.unloadAll()
            isFormattingTrialRunning = false
            formattingTrialTask = nil
            updates.installationGate.endOperation(lease)
        }
    }

    func cancelFormattingTrial() { formattingTrialTask?.cancel() }
    func clearFormattingTrial() {
        cancelFormattingTrial()
        formattingTrialResult = nil; formattingTrialOutcome = nil; formattingTrialError = nil
    }

    private func makeSessionCoordinator() -> AppDictationSession {
        let dependencies: AppDictationSession.Dependencies
        if let sessionDependenciesFactory {
            dependencies = sessionDependenciesFactory()
        } else {
            let recorder = AudioRecorder()
            let mute = MicMuteController()
            let pipeline = pipeline
            let meter = audioLevel
            restoreMuteOnQuit = { mute.restoreSynchronouslyOnQuit() }
            dependencies = .init(
                startCapture: { configuration, peak in
                    meter.stop()
                    recorder.onLivePeak = peak
                    recorder.onConvertedBuffer = nil
                    _ = try recorder.start(deviceUID: configuration.deviceUID)
                },
                stopCapture: {
                    let stopped = try recorder.stop()
                    return DictationCapture(url: stopped.url, duration: stopped.duration)
                },
                cancelCapture: { recorder.cancel() },
                unmute: { configuration in
                    if configuration.unmute {
                        await mute.beginDictationUnmute(deviceUID: configuration.deviceUID, deviceName: configuration.deviceName)
                    }
                },
                restoreMute: { await mute.endDictationRestore() },
                wantsPreview: { $0.liveDraft },
                startPreview: { configuration, update in
                    await pipeline.startLiveDraftIfPossible(languageCode: nil, configuration: configuration.pipeline) { value in
                        Task { @MainActor in update(value.confirmed, value.volatile) }
                    }
                },
                attachPreview: { attach in
                    recorder.onConvertedBuffer = attach ? pipeline.liveDraftAudioHandler() : nil
                },
                stopPreview: { await pipeline.cancelLiveDraft() },
                process: { capture, configuration, phase in
                    try await pipeline.run(audioURL: capture.url, useLiveDraftResult: false,
                        offlineSecondPass: false, configuration: configuration.pipeline) { value in
                            phase(value == .transcribing ? .transcribing : .cleaning)
                        }
                },
                unload: { await pipeline.unloadAll() }
            )
        }
        let coordinator = AppDictationSession(gate: updates.installationGate, dependencies: dependencies)
        coordinator.onPeak = { [weak self] peak in
            guard let self else { return }
            self.recorderLiveLevel = max(peak, self.recorderLiveLevel * 0.55)
        }
        coordinator.onPreview = { [weak self] confirmed, volatile in
            self?.liveDraftConfirmed = confirmed
            self?.liveDraftVolatile = volatile
        }
        coordinator.onPhase = { [weak self] phase in self?.sessionPhaseChanged(phase) }
        coordinator.onResult = { [weak self] result, duration, configuration in
            await self?.deliverDictation(result, duration: duration, configuration: configuration)
        }
        coordinator.onFailure = { [weak self] error in
            guard let self else { return }
            self.clearLiveDraftText()
            self.clearCapsulePhase()
            if case AudioRecorderError.silentOrTooShort = error {
                self.menuBarMode = .idle
            } else {
                self.lastSessionError = error.localizedDescription
                self.menuBarMode = .error
            }
        }
        coordinator.onCancelled = { [weak self] in
            guard let self else { return }
            self.clearLiveDraftText()
            self.menuBarMode = .idle
            if let draft = self.cancelledDraftToPresent { self.presentLiveDraftResult(draft) }
            else { self.clearCapsulePhase() }
            self.cancelledDraftToPresent = nil
        }
        return coordinator
    }

    private func sessionPhaseChanged(_ phase: DictationSessionPhase) {
        switch phase {
        case .starting:
            if let configuration = session.configuration {
                activeDictationMode = configuration.islandMode
                capsuleOperation = .dictation
            }
            isSetupTrialActive = session.configuration?.destination == .setupTrial
            isSetupTrialCancelling = false
            if isSetupTrialActive { setupTrialText = ""; setupTrialFormatting = nil }
            cancelledDraftToPresent = nil
            dismissAnyResultCapsule()
            clearLiveDraftText()
            invalidateCapsuleSequence()
            recorderLiveLevel = 0
        case .recording:
            invalidateCapsuleSequence()
            menuBarMode = .recording
            capsulePhase = .listening
            hotkey.setEscapeCancelRegistered(true)
            if session.configuration?.holdToTalk == true {
                hotkey.startPushToTalkReleaseMonitor()
                if !pttKeyHeld { session.cancel() }
            }
        case .transcribing, .cleaning:
            hotkey.stopPushToTalkReleaseMonitor()
            hotkey.setEscapeCancelRegistered(false)
            recorderLiveLevel = 0
            clearLiveDraftText()
            menuBarMode = phase == .cleaning ? .cleanup : .processing
            capsulePhase = .understanding
        case .cancelling:
            isSetupTrialCancelling = isSetupTrialActive
            hotkey.stopPushToTalkReleaseMonitor()
            hotkey.setEscapeCancelRegistered(false)
            recorderLiveLevel = 0
        case .finishing: break
        case .idle:
            isSetupTrialActive = false
            isSetupTrialCancelling = false
            pttKeyHeld = false
            recorderLiveLevel = 0
            hotkey.stopPushToTalkReleaseMonitor()
            if settingsVisible, micMeterEnabled { startInputMeterIfPossible() }
            refreshMenuBarMode()
        }
    }

    func cancelDictationSession() async {
        guard session.phase == .recording || session.phase == .starting else { return }
        let draft = liveDraftSnapshotText()
        let capturedPreview = session.configuration?.liveDraft == true
        cancelledDraftToPresent = !isSetupTrialActive && capturedPreview && !draft.isEmpty ? draft : nil
        session.cancel()
    }

    var isStatusPanelVisible: Bool { statusCapsule.isVisibleForTesting }

    var dictationSessionPhase: DictationSessionPhase { session.phase }

    private func deliverDictation(_ result: FormattedDictation, duration: TimeInterval, configuration: DictationSessionSettings) async {
        clearLiveDraftText()
        let text = result.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty {
            if configuration.destination == .setupTrial { setupTrialText = ""; setupTrialFormatting = result.formatting }
            else {
                lastFormattingOutcome = result.formatting
                lastDictationIslandMode = configuration.islandMode
            }
            menuBarMode = .idle
            clearCapsulePhase()
            return
        }
        do {
            try configuration.destination.deliver(result, atCaret: { completed in
                if !text.isEmpty { lastDictationText = text }
                lastFormattingOutcome = completed.formatting
                lastDictationIslandMode = configuration.islandMode
                try TextInsertionService.insertAtCaret(completed.text, retainInClipboard: retainDictationInClipboard)
                recordUsageIfEnabled(text: completed.text, recordingDuration: duration)
            }, inTrial: { completed in
                setupTrialText = completed.text
                setupTrialFormatting = completed.formatting
                if !text.isEmpty {
                    hasCompletedSetupTrial = true
                    setupDefaults.set(true, forKey: "carrottype.didCompleteSetupTrial")
                }
            })
        } catch {
            lastSessionError = error.localizedDescription
            clearCapsulePhase()
            menuBarMode = .error
            if !text.isEmpty {
                presentDictationRecovery(text)
            }
            return
        }
        lastSessionError = nil
        menuBarMode = .idle
        if configuration.destination == .setupTrial { clearCapsulePhase() }
        else { await presentSuccessCapsuleSequence(usedFormattingFallback: result.formatting.usedFallback) }
    }

    /// Ordinary Quit drains capture/helper/maintenance before replying to AppKit.
    /// Sparkle's existing termination guard runs first and keeps its install policy.
    func prepareForQuit() -> NSApplication.TerminateReply {
        if terminationTask != nil { return .terminateLater }
        guard updates.installationGate.isBusy else { return .terminateNow }
        isTerminating = true
        session.stopAcceptingOperations()
        session.cancel()
        transformTask?.cancel()
        formattingTrialTask?.cancel()
        let formattingTrial = formattingTrialTask
        let transform = transformTask
        terminationTask = Task {
            await session.waitUntilIdle()
            await transform?.value
            await formattingTrial?.value
            NSApp.reply(toApplicationShouldTerminate: updates.installationGate.prepareForTermination())
        }
        return .terminateLater
    }

    func copyLastDictation() {
        guard let text = lastDictationText else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    func clearLastDictation() {
        lastDictationText = nil
        if capsulePhase == .dictationRecovery { dismissTransformResult() }
    }

    func dismissSessionError() {
        lastSessionError = nil
        refreshMenuBarMode()
    }

    private func clearLiveDraftText() {
        liveDraftConfirmed = ""
        liveDraftVolatile = ""
    }

    private func liveDraftSnapshotText() -> String {
        [liveDraftConfirmed, liveDraftVolatile]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func clearCapsulePhase() {
        invalidateCapsuleSequence()
        liveDraftResultDismissTask?.cancel()
        liveDraftResultDismissTask = nil
        transformCopiedFeedbackTask?.cancel()
        transformCopiedFeedbackTask = nil
        transformResultCopiedFeedback = false
        transformResultText = nil
        transformResultDirection = nil
        capsulePhase = nil
        if menuBarMode != .recording {
            hotkey.setEscapeCancelRegistered(false)
        }
        statusCapsule.sync()
    }

    private func invalidateCapsuleSequence() {
        capsuleSequenceToken = UUID()
    }

    /// Command dispatched, then Done. CGEvent cannot acknowledge insertion in another app.
    func presentSuccessCapsuleSequence(usedFormattingFallback: Bool) async {
        let token = UUID()
        capsuleSequenceToken = token
        capsulePhase = .writing
        try? await Task.sleep(nanoseconds: 350_000_000)
        guard capsuleSequenceToken == token else { return }
        capsulePhase = usedFormattingFallback ? .formattingFallback : .inserted
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

    /// Deletion and unload share the same synchronous reservation as session starts.
    func deleteModelPackage(_ packageID: String) {
        performModelMaintenance { self.modelManager.deletePackage(packageID) }
    }

    func deleteUnusedModelPackages() {
        performModelMaintenance { self.modelManager.deleteUnusedPackages() }
    }

    private func performModelMaintenance(_ body: @escaping () -> Void) {
        guard session.maintain({
            await self.pipeline.unloadAll()
            body()
            self.reloadTransformBindingsFromStore()
            if let message = self.modelManager.lastError { self.lastSessionError = message }
            self.refreshMenuBarMode()
        }) else {
            lastSessionError = L10n.t("error.models_in_use", locale: effectiveLocale)
            return
        }
    }

    /// Clears catalog-scoped Hugging Face hub cache only (not Application Support packages).
    func clearModelDownloadCache() {
        modelManager.clearDownloadCache()
        if let message = modelManager.lastError {
            lastSessionError = message
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

    private func recordUsageIfEnabled(text: String, recordingDuration: TimeInterval) {
        guard statsCollectionEnabled else { return }
        let characters = text.trimmingCharacters(in: .whitespacesAndNewlines).count
        let recordingMilliseconds = Int((recordingDuration * 1000).rounded())
        usageStats.record(characters: characters, recordingMilliseconds: recordingMilliseconds)
    }

    private func recordTransformIfEnabled(binding: TransformBinding) {
        guard statsCollectionEnabled else { return }
        usageStats.recordTransform(bindingID: binding.id, kind: binding.kind)
    }

    func clearUsageStatistics() {
        usageStats.clear()
    }

    private enum Keys {
        static let retainClipboard = "carrottype.retainDictationInClipboard"
        static let pushToTalk = "carrottype.dictationPushToTalk"
        static let liveDraft = "carrottype.liveDraftEnabled"
        static let offlineSecondPass = "carrottype.offlineSecondPassAfterLiveDraft"
        static let unmuteDuringDictation = "carrottype.unmuteMicDuringDictation"
        static let statsCollection = "carrottype.statsCollectionEnabled"
        static let typingSpeedWPM = "carrottype.typingSpeedWPM"
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
