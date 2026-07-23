import AVFoundation
import ApplicationServices
import AppKit
import Foundation

enum MicrophoneAuthorization: Equatable {
    case authorized
    case denied
    case notDetermined
    case restricted

    var isGranted: Bool { self == .authorized }
}

@MainActor
final class PermissionService: ObservableObject {
    @Published private(set) var microphoneAuthorization: MicrophoneAuthorization = .notDetermined
    @Published private(set) var accessibilityGranted = false
    /// Bumped on every refresh so SwiftUI always redraws after «Обновить».
    @Published private(set) var permissionCheckTick: Int = 0
    /// Previous session had AX; this binary is not trusted yet (Rebuild / needs relaunch).
    @Published private(set) var accessibilityNeedsRegrantAfterRebuild = false
    /// User opened Accessibility pane this session but process still untrusted — relaunch usually fixes it.
    @Published private(set) var accessibilityLikelyNeedsRelaunch = false

    private var becomeActiveObserver: NSObjectProtocol?
    private var workspaceObserver: NSObjectProtocol?
    private var pollTimer: Timer?
    private var sawAccessibilitySettingsOpen = false
    private let defaults: UserDefaults
    private let hadAccessibilityKey = "carrottype.hadAccessibilityGranted"

    var microphoneGranted: Bool { microphoneAuthorization.isGranted }

    /// Path shown in System Settings / for matching the correct TCC row.
    var runningAppPath: String {
        Bundle.main.bundleURL.path
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        refresh()
        startMonitoring()
    }

    /// Re-read TCC. Publishes only when values change (or after an explicit bump need).
    func refresh() {
        let mic = Self.currentMicrophoneAuthorization()
        let ax = Self.currentAccessibilityGranted()
        let changed = mic != microphoneAuthorization || ax != accessibilityGranted

        microphoneAuthorization = mic
        accessibilityGranted = ax

        if ax {
            defaults.set(true, forKey: hadAccessibilityKey)
            accessibilityNeedsRegrantAfterRebuild = false
            accessibilityLikelyNeedsRelaunch = false
        } else {
            if defaults.bool(forKey: hadAccessibilityKey) {
                accessibilityNeedsRegrantAfterRebuild = true
            }
            if sawAccessibilitySettingsOpen {
                accessibilityLikelyNeedsRelaunch = true
            }
        }

        if changed {
            permissionCheckTick &+= 1
            objectWillChange.send()
        }
        adjustPolling()
    }

    /// Force a UI tick (e.g. user tapped Refresh).
    func refreshAndBumpUI() {
        permissionCheckTick &+= 1
        refresh()
        objectWillChange.send()
    }

    func startMonitoring() {
        refresh()
        // Do NOT auto-prompt on launch: a dismissed prompt can leave TCC confusing.
        // Registration happens when the user clicks the Accessibility buttons.

        if becomeActiveObserver == nil {
            becomeActiveObserver = NotificationCenter.default.addObserver(
                forName: NSApplication.didBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.refresh() }
            }
        }

        if workspaceObserver == nil {
            workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.didActivateApplicationNotification,
                object: nil,
                queue: .main
            ) { [weak self] note in
                Task { @MainActor in
                    let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
                    let bundleID = app?.bundleIdentifier
                    if bundleID == "com.apple.systempreferences"
                        || bundleID == "com.apple.PreferencePanels"
                        || bundleID == "com.apple.Settings"
                        || bundleID == "com.apple.systempreferences.AppleIDSettings" {
                        self?.sawAccessibilitySettingsOpen = true
                    }
                    self?.refresh()
                }
            }
        }

        adjustPolling()
    }

    func stopMonitoring() {
        if let becomeActiveObserver {
            NotificationCenter.default.removeObserver(becomeActiveObserver)
            self.becomeActiveObserver = nil
        }
        if let workspaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(workspaceObserver)
            self.workspaceObserver = nil
        }
        stopPolling()
    }

    func requestOrOpenMicrophone() {
        switch microphoneAuthorization {
        case .notDetermined:
            Self.requestMicrophoneAccess { [weak self] granted in
                Task { @MainActor in
                    self?.microphoneAuthorization = granted ? .authorized : .denied
                    self?.refresh()
                }
            }
        case .denied, .restricted:
            openMicrophoneSettings()
        case .authorized:
            refresh()
        }
    }

    func openMicrophoneSettings() {
        openPrivacyPane("Privacy_Microphone")
        scheduleFollowUpRefreshes()
    }

    func openAccessibilitySettings() {
        sawAccessibilitySettingsOpen = true
        // Register *this* running binary (creates/updates the TCC row for current build).
        registerCurrentBinaryInAccessibilityList(prompt: true)
        openPrivacyPane("Privacy_Accessibility")
        scheduleFollowUpRefreshes()
    }

    /// Adds the current process to Privacy → Accessibility (system prompt when prompt == true).
    @discardableResult
    func registerCurrentBinaryInAccessibilityList(prompt: Bool) -> Bool {
        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt,
        ] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        refresh()
        return trusted
    }

    /// macOS often applies Accessibility only after the process restarts.
    func relaunchApp() {
        let bundleURL = Bundle.main.bundleURL
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: bundleURL, configuration: configuration) { _, _ in
            DispatchQueue.main.async {
                NSApp.terminate(nil)
            }
        }
        // Fallback if openApplication callback is slow.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            NSApp.terminate(nil)
        }
    }

    private func scheduleFollowUpRefreshes() {
        adjustPolling()
        Task { @MainActor in
            for delayMs in [300, 800, 1500, 3000, 5000, 8000] as [UInt64] {
                try? await Task.sleep(nanoseconds: delayMs * 1_000_000)
                refresh()
                if accessibilityGranted { break }
            }
            // Still false after waiting → strongly suggest relaunch.
            if !accessibilityGranted, sawAccessibilitySettingsOpen {
                accessibilityLikelyNeedsRelaunch = true
                objectWillChange.send()
            }
        }
    }

    private func openPrivacyPane(_ anchor: String) {
        let candidates = [
            "x-apple.systempreferences:com.apple.preference.security?\(anchor)",
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?\(anchor)",
        ]
        for candidate in candidates {
            if let url = URL(string: candidate), NSWorkspace.shared.open(url) {
                return
            }
        }
    }

    private func adjustPolling() {
        // When both permissions are granted, stop polling — event observers are enough.
        if microphoneGranted && accessibilityGranted {
            stopPolling()
            return
        }
        let interval: TimeInterval = 0.75
        if let pollTimer, abs(pollTimer.timeInterval - interval) < 0.05 {
            return
        }
        stopPolling()
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        pollTimer = timer
    }

    private func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    private static func currentMicrophoneAuthorization() -> MicrophoneAuthorization {
        if #available(macOS 14.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .granted: return .authorized
            case .denied: return .denied
            case .undetermined: return .notDetermined
            @unknown default: break
            }
        }
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .notDetermined
        @unknown default: return .denied
        }
    }

    private static func requestMicrophoneAccess(completion: @Sendable @escaping (Bool) -> Void) {
        if #available(macOS 14.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                completion(granted)
            }
            return
        }
        AVCaptureDevice.requestAccess(for: .audio, completionHandler: completion)
    }

    private static func currentAccessibilityGranted() -> Bool {
        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false,
        ] as CFDictionary
        if AXIsProcessTrustedWithOptions(options) { return true }
        if AXIsProcessTrusted() { return true }
        return false
    }
}
