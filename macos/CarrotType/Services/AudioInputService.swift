import AVFoundation
import CoreAudio
import Foundation

struct AudioInputDevice: Identifiable, Hashable {
    let id: String
    let name: String
    let isDefault: Bool
}

/// One row of the Setup priority list. `name` is `nil` only for a UID never seen connected.
struct AudioInputPriorityEntry: Identifiable, Hashable {
    let id: String
    let name: String?
    let isAvailable: Bool
    let isDefault: Bool
    let isActive: Bool
}

/// Microphone discovery, ordered failover preference and the resolved active input.
///
/// The active input is the first connected UID in `priorityUIDs`. Resolution is suspended for the
/// whole dictation session (`suspendAutoSwitch`/`resumeAutoSwitch`), so a hot-plug can never change
/// the microphone under a recording. See `AudioInputPriorityList`.
@MainActor
final class AudioInputService: ObservableObject {
    @Published private(set) var devices: [AudioInputDevice] = []
    /// Resolved active input. Kept in the pre-priority key for compatibility.
    @Published var selectedDeviceID: String
    /// Ordered preference, including microphones that are currently disconnected.
    @Published private(set) var priorityUIDs: [String] = []

    private let defaults: UserDefaults
    private let selectedKey = AudioInputPriorityList.legacySelectedKey
    private let namesKey = "carrottype.audioInputKnownDeviceNames"
    private var priority: AudioInputPriorityList
    /// Last known names so disconnected rows stay readable (UIDs are not human-friendly).
    private var knownNames: [String: String]
    private var systemDefaultDeviceID: String?
    private var autoSwitchSuspended = false
    private var refreshGeneration = 0
    private var listener: AudioInputDeviceListener?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.priority = AudioInputPriorityList.load(defaults: defaults)
        self.priorityUIDs = priority.uids
        self.selectedDeviceID = defaults.string(forKey: AudioInputPriorityList.legacySelectedKey) ?? ""
        self.knownNames = (defaults.dictionary(forKey: namesKey) as? [String: String]) ?? [:]
        // Persist the migrated list so the legacy single selection is read only once.
        priority.save(defaults: defaults)
        refreshDevices()
        listener = AudioInputDeviceListener { [weak self] in
            DispatchQueue.main.async {
                MainActor.assumeIsolated { self?.scheduleDeviceRefresh() }
            }
        }
    }

    /// Resolved active input. Never falls back to an unrelated device by itself: `refreshDevices`
    /// owns fallback resolution.
    var selectedDevice: AudioInputDevice? {
        devices.first { $0.id == selectedDeviceID }
    }

    /// Preferred order first, then other connected devices that are not in the list yet, so the
    /// user can promote them. Disconnected preferences keep their cached names.
    var priorityEntries: [AudioInputPriorityEntry] {
        var entries = priorityUIDs.map { uid -> AudioInputPriorityEntry in
            let device = devices.first { $0.id == uid }
            return AudioInputPriorityEntry(
                id: uid,
                name: device?.name ?? knownNames[uid],
                isAvailable: device != nil,
                isDefault: device?.isDefault ?? false,
                isActive: device != nil && uid == selectedDeviceID
            )
        }
        let listed = Set(entries.map(\.id))
        for device in devices where !listed.contains(device.id) {
            entries.append(
                AudioInputPriorityEntry(
                    id: device.id,
                    name: device.name,
                    isAvailable: true,
                    isDefault: device.isDefault,
                    isActive: device.id == selectedDeviceID
                )
            )
        }
        return entries
    }

    // MARK: - Discovery

    /// Refreshes the connected devices and, while idle, re-resolves the active input.
    /// The published device list always updates; only the active selection is frozen in a session.
    func refreshDevices() {
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.microphone, .external],
            mediaType: .audio,
            position: .unspecified
        )

        let defaultID = AVCaptureDevice.default(for: .audio)?.uniqueID
        systemDefaultDeviceID = defaultID
        let mapped = discovery.devices.map { device in
            AudioInputDevice(
                id: device.uniqueID,
                name: device.localizedName,
                isDefault: device.uniqueID == defaultID
            )
        }

        devices = mapped
        rememberNames(mapped)
        guard !autoSwitchSuspended else { return }
        resolveActiveDevice()
    }

    private func rememberNames(_ mapped: [AudioInputDevice]) {
        var changed = false
        for device in mapped where knownNames[device.id] != device.name {
            knownNames[device.id] = device.name
            changed = true
        }
        if changed {
            defaults.set(knownNames, forKey: namesKey)
        }
    }

    /// Preferred connected UID → macOS default → first discovered. An empty preference is seeded
    /// once with the resolved device so “first entry wins” always matches the UI; later fallbacks
    /// are used without being appended, and nothing is ever pruned.
    private func resolveActiveDevice() {
        guard !devices.isEmpty else {
            selectedDeviceID = ""
            return
        }
        guard let resolved = priority.resolveActiveUID(
            discoveredUIDs: devices.map(\.id),
            systemDefaultUID: systemDefaultDeviceID
        ) else { return }

        if priority.uids.isEmpty {
            priority.promote(resolved)
            publishPriority()
        }
        if selectedDeviceID != resolved || defaults.string(forKey: selectedKey) != resolved {
            selectedDeviceID = resolved
            defaults.set(resolved, forKey: selectedKey)
        }
    }

    // MARK: - Session freeze

    /// Called when a dictation/setup-trial session starts: the captured device must not change.
    func suspendAutoSwitch() {
        autoSwitchSuspended = true
    }

    /// Called when the session returns to idle; resolves the preference that may have changed.
    func resumeAutoSwitch() {
        guard autoSwitchSuspended else { return }
        autoSwitchSuspended = false
        refreshDevices()
    }

    // MARK: - Preference editing

    /// Menu quick-select: promotes the chosen microphone to the front of the priority list.
    func promoteDevice(_ id: String) {
        var order = priorityEntries.map(\.id)
        order.removeAll { $0 == id }
        order.insert(id, at: 0)
        applyPriorityOrder(order)
    }

    /// Setup row reorder. Returns false for an unknown UID or a move past either end.
    @discardableResult
    func movePriorityEntry(_ uid: String, by offset: Int) -> Bool {
        let displayed = priorityEntries.map(\.id)
        guard let order = AudioInputPriorityList.moving(uid, byOffset: offset, in: displayed) else {
            return false
        }
        applyPriorityOrder(order)
        return true
    }

    private func applyPriorityOrder(_ order: [String]) {
        priority.reorder(order)
        publishPriority()
        guard !autoSwitchSuspended else { return }
        resolveActiveDevice()
    }

    private func publishPriority() {
        priorityUIDs = priority.uids
        priority.save(defaults: defaults)
    }

    // MARK: - Hot-plug

    /// Core Audio can deliver a burst per change; keep only the last event in a short window.
    private func scheduleDeviceRefresh() {
        refreshGeneration += 1
        let generation = refreshGeneration
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard let self, self.refreshGeneration == generation else { return }
            self.refreshDevices()
        }
    }

    // MARK: - System default input

    /// Sets the system default input device so AVAudioEngine uses the chosen mic.
    nonisolated static func selectSystemInputDevice(uid: String) throws {
        guard let deviceID = audioDeviceID(forUID: uid) else {
            throw AudioRecorderError.engineFailed("Устройство ввода не найдено: \(uid)")
        }

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var mutableID = deviceID
        let size = UInt32(MemoryLayout<AudioDeviceID>.size)
        let status = AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            size,
            &mutableID
        )
        guard status == noErr else {
            throw AudioRecorderError.engineFailed("Не удалось выбрать микрофон (status \(status))")
        }
    }

    private nonisolated static func audioDeviceID(forUID uid: String) -> AudioDeviceID? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &dataSize
        ) == noErr else { return nil }

        let count = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var devices = [AudioDeviceID](repeating: 0, count: count)
        guard AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &dataSize,
            &devices
        ) == noErr else { return nil }

        for device in devices {
            var uidAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyDeviceUID,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            var cfUID: CFString? = nil as CFString?
            var uidSize = UInt32(MemoryLayout<CFString?>.size)
            let status = withUnsafeMutablePointer(to: &cfUID) { ptr in
                AudioObjectGetPropertyData(device, &uidAddress, 0, nil, &uidSize, ptr)
            }
            if status == noErr, let cfUID, (cfUID as String) == uid {
                // Prefer devices that have input channels.
                var streamAddress = AudioObjectPropertyAddress(
                    mSelector: kAudioDevicePropertyStreamConfiguration,
                    mScope: kAudioDevicePropertyScopeInput,
                    mElement: kAudioObjectPropertyElementMain
                )
                var streamSize: UInt32 = 0
                if AudioObjectGetPropertyDataSize(device, &streamAddress, 0, nil, &streamSize) == noErr,
                   streamSize > 0 {
                    let raw = UnsafeMutableRawPointer.allocate(
                        byteCount: Int(streamSize),
                        alignment: MemoryLayout<AudioBufferList>.alignment
                    )
                    defer { raw.deallocate() }
                    if AudioObjectGetPropertyData(device, &streamAddress, 0, nil, &streamSize, raw) == noErr {
                        let list = raw.assumingMemoryBound(to: AudioBufferList.self)
                        let buffers = UnsafeMutableAudioBufferListPointer(list)
                        let channels = buffers.reduce(0) { $0 + Int($1.mNumberChannels) }
                        if channels > 0 { return device }
                    }
                }
            }
        }
        return nil
    }
}

/// Core Audio listener for device-list and default-input changes.
///
/// Owns its listener blocks so they can be removed together with the service. Events arrive on a
/// private queue and are forwarded to the main actor by the service.
final class AudioInputDeviceListener {
    private let objectID = AudioObjectID(kAudioObjectSystemObject)
    private let queue = DispatchQueue(label: "app.carrottype.audio-device-events")
    private let handler: () -> Void
    private var addresses: [AudioObjectPropertyAddress] = []
    private var blocks: [AudioObjectPropertyListenerBlock] = []

    init(handler: @escaping () -> Void) {
        self.handler = handler
        attach(kAudioHardwarePropertyDevices)
        attach(kAudioHardwarePropertyDefaultInputDevice)
    }

    private func attach(_ selector: AudioObjectPropertySelector) {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let block: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            self?.handler()
        }
        guard AudioObjectAddPropertyListenerBlock(objectID, &address, queue, block) == noErr else {
            return
        }
        addresses.append(address)
        blocks.append(block)
    }

    deinit {
        for (index, address) in addresses.enumerated() {
            var mutableAddress = address
            AudioObjectRemovePropertyListenerBlock(objectID, &mutableAddress, queue, blocks[index])
        }
    }
}
