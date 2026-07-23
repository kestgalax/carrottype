import AppKit
import Combine
import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var menuBarMode: MenuBarMode = .needsSetup {
        didSet {
            notchOverlay.sync(mode: menuBarMode)
            updateLevelDecayTimer()
        }
    }
    @Published var showFirstRun: Bool
    @Published var lastSessionError: String?
    /// Live mic level while recording (drives notch waveform).
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

    let modelManager: ModelManager
    let permissions: PermissionService
    let hotkey: HotkeyService
    let audioInput: AudioInputService
    let audioLevel: AudioLevelMonitor
    let pipeline: DictationPipeline

    private let recorder = AudioRecorder()
    private let micMute = MicMuteController()
    private let notchOverlay = NotchRecordingOverlayController()
    private var cancellables = Set<AnyCancellable>()
    private var isProcessing = false
    private var levelDecayTimer: Timer?
    private var modelUnloadTask: Task<Void, Never>?
    /// Counts nested Settings appearances so SwiftUI remounts do not clear the mic meter.
    private var settingsAppearanceCount = 0

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
        self.unmuteMicDuringDictation = defaults.bool(forKey: Keys.unmuteDuringDictation)

        notchOverlay.attach(appState: self)
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

        hotkey.setOnHotkey { [weak self] in
            self?.handleHotkeyPressed()
        }
        hotkey.setOnEscapeCancel { [weak self] in
            Task { await self?.cancelDictationSession() }
        }
        hotkey.registerGlobalHotkey()

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

    /// Toggle: start recording → stop → transcribe → paste at caret.
    private func handleHotkeyPressed() {
        if isProcessing || menuBarMode == .processing || menuBarMode == .cleanup {
            return
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

        Task { await startDictationSession() }
    }

    private func startDictationSession() async {
        guard readiness == .ready else {
            menuBarMode = .needsSetup
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        guard menuBarMode != .recording, !isProcessing else { return }

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

        do {
            _ = try recorder.start(deviceUID: audioInput.selectedDeviceID)
            menuBarMode = .recording
            hotkey.setEscapeCancelRegistered(true)
        } catch {
            await micMute.endDictationRestore()
            lastSessionError = error.localizedDescription
            menuBarMode = .error
            if settingsVisible, micMeterEnabled { startInputMeterIfPossible() }
            refreshMenuBarMode()
        }
    }

    /// Escape (or soft silent stop): discard capture, no STT/paste.
    private func cancelDictationSession() async {
        guard menuBarMode == .recording, !isProcessing else { return }

        hotkey.setEscapeCancelRegistered(false)
        recorder.cancel()
        recorderLiveLevel = 0
        lastSessionError = nil
        await micMute.endDictationRestore()
        menuBarMode = .idle
        if settingsVisible, micMeterEnabled { startInputMeterIfPossible() }
        refreshMenuBarMode()
    }

    private func finishDictationSession() async {
        isProcessing = true
        recorderLiveLevel = 0
        hotkey.setEscapeCancelRegistered(false)
        menuBarMode = .processing
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
                menuBarMode = .idle
                return
            }
            lastSessionError = error.localizedDescription
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
                        switch phase {
                        case .transcribing: self?.menuBarMode = .processing
                        case .cleaning: self?.menuBarMode = .cleanup
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
        } catch {
            lastSessionError = error.localizedDescription
            menuBarMode = .error
        }
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
            if let message = modelManager.lastError {
                lastSessionError = message
            }
            refreshMenuBarMode()
        }
    }

    private enum Keys {
        static let retainClipboard = "carrottype.retainDictationInClipboard"
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
