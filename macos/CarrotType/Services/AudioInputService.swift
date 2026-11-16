import AVFoundation
import CoreAudio
import Foundation

struct AudioInputDevice: Identifiable, Hashable {
    let id: String
    let name: String
    let isDefault: Bool
    /// Present in Core Audio but not a usable capture target (e.g. orphan Wave Link virtual mix).
    let isUsable: Bool
    let transport: AudioInputTransport

    init(
        id: String,
        name: String,
        isDefault: Bool,
        isUsable: Bool = true,
        transport: AudioInputTransport = .other
    ) {
        self.id = id
        self.name = name
        self.isDefault = isDefault
        self.isUsable = isUsable
        self.transport = transport
    }
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

    /// Preferred order first, then other present devices that are not in the list yet, so the
    /// user can promote them. Disconnected / orphan-virtual preferences keep their cached names.
    var priorityEntries: [AudioInputPriorityEntry] {
        var entries = priorityUIDs.map { uid -> AudioInputPriorityEntry in
            let device = devices.first { $0.id == uid }
            let usable = device?.isUsable == true
            return AudioInputPriorityEntry(
                id: uid,
                name: device?.name ?? knownNames[uid],
                isAvailable: usable,
                isDefault: device?.isDefault ?? false,
                isActive: usable && uid == selectedDeviceID
            )
        }
        let listed = Set(entries.map(\.id))
        for device in devices where !listed.contains(device.id) {
            entries.append(
                AudioInputPriorityEntry(
                    id: device.id,
                    name: device.name,
                    isAvailable: device.isUsable,
                    isDefault: device.isDefault,
                    isActive: device.isUsable && device.id == selectedDeviceID
                )
            )
        }
        return entries
    }

    // MARK: - Discovery

    /// Refreshes the connected devices and, while idle, re-resolves the active input.
    /// The published device list always updates; only the active selection is frozen in a session.
    func refreshDevices() {
        let enumerated = Self.enumerateInputDevices()
        let defaultID = enumerated.first(where: \.isDefaultSystemInput)?.uid
            ?? AVCaptureDevice.default(for: .audio)?.uniqueID
        systemDefaultDeviceID = defaultID

        let physicalWave = AudioInputUsability.physicalWaveHardwarePresent(
            in: enumerated.map { ($0.name, $0.manufacturer, $0.transport) }
        )

        let mapped = enumerated.map { device in
            let usable = AudioInputUsability.isUsable(
                name: device.name,
                manufacturer: device.manufacturer,
                transport: device.transport,
                physicalWaveHardwarePresent: physicalWave
            )
            return AudioInputDevice(
                id: device.uid,
                name: device.name,
                isDefault: device.uid == defaultID,
                isUsable: usable,
                transport: device.transport
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

    /// Preferred usable UID → usable macOS default → first usable discovered. An empty preference
    /// is seeded once with a **first-run friendly** mic (built-in preferred over Wave Link /
    /// Continuity system defaults) so the first dictation is unlikely to be silent; later
    /// fallbacks are used without being appended, and nothing is ever pruned.
    private func resolveActiveDevice() {
        let usable = devices.filter(\.isUsable)
        guard !usable.isEmpty else {
            selectedDeviceID = ""
            return
        }

        if priority.uids.isEmpty {
            let seed = AudioInputUsability.preferredFirstSeedUID(
                in: usable.map { ($0.id, $0.name, $0.transport) }
            ) ?? usable.first?.id
            if let seed {
                priority.promote(seed)
                publishPriority()
            }
        }

        let usableDefault = usable.first(where: { $0.id == systemDefaultDeviceID })?.id
        guard let resolved = priority.resolveActiveUID(
            discoveredUIDs: usable.map(\.id),
            systemDefaultUID: usableDefault
        ) else { return }

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

    /// Drag-and-drop reorder of the displayed priority list (including not-yet-preferred devices).
    func movePriorityEntries(from source: IndexSet, to destination: Int) {
        var order = priorityEntries.map(\.id)
        order.move(fromOffsets: source, toOffset: destination)
        applyPriorityOrder(order)
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

    // MARK: - Core Audio enumeration

    private struct EnumeratedInput {
        let uid: String
        let name: String
        let manufacturer: String
        let transport: AudioInputTransport
        let isDefaultSystemInput: Bool
    }

    /// All Core Audio inputs with channels; includes orphan Wave Link virtual mixes for the UI.
    private nonisolated static func enumerateInputDevices() -> [EnumeratedInput] {
        let defaultID = defaultSystemInputDeviceID()
        return audioDeviceIDs().compactMap { deviceID in
            guard inputChannelCount(deviceID) > 0 else { return nil }
            guard let uid = stringProperty(deviceID, kAudioDevicePropertyDeviceUID) else { return nil }
            let name = stringProperty(deviceID, kAudioDevicePropertyDeviceNameCFString) ?? uid
            let manufacturer = stringProperty(deviceID, kAudioObjectPropertyManufacturer) ?? ""
            return EnumeratedInput(
                uid: uid,
                name: name,
                manufacturer: manufacturer,
                transport: transport(of: deviceID),
                isDefaultSystemInput: deviceID == defaultID
            )
        }
    }

    private nonisolated static func defaultSystemInputDeviceID() -> AudioDeviceID? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        guard AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &deviceID
        ) == noErr, deviceID != 0 else { return nil }
        return deviceID
    }

    private nonisolated static func audioDeviceIDs() -> [AudioDeviceID] {
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
        ) == noErr else { return [] }

        let count = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var devices = [AudioDeviceID](repeating: 0, count: count)
        guard AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &dataSize,
            &devices
        ) == noErr else { return [] }
        return devices
    }

    private nonisolated static func transport(of deviceID: AudioDeviceID) -> AudioInputTransport {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyTransportType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var value: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        guard AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &value) == noErr else {
            return .other
        }
        switch value {
        case kAudioDeviceTransportTypeBuiltIn: return .builtIn
        case kAudioDeviceTransportTypeUSB: return .usb
        case kAudioDeviceTransportTypeBluetooth, kAudioDeviceTransportTypeBluetoothLE: return .bluetooth
        case kAudioDeviceTransportTypeVirtual: return .virtual
        case kAudioDeviceTransportTypeAggregate: return .aggregate
        default: return .other
        }
    }

    private nonisolated static func stringProperty(
        _ deviceID: AudioDeviceID,
        _ selector: AudioObjectPropertySelector
    ) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var cfValue: CFString? = nil
        var size = UInt32(MemoryLayout<CFString?>.size)
        let status = withUnsafeMutablePointer(to: &cfValue) { ptr in
            AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, ptr)
        }
        guard status == noErr else { return nil }
        return cfValue as String?
    }

    private nonisolated static func inputChannelCount(_ deviceID: AudioDeviceID) -> Int {
        var streamAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        var streamSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(deviceID, &streamAddress, 0, nil, &streamSize) == noErr,
              streamSize > 0 else { return 0 }
        let raw = UnsafeMutableRawPointer.allocate(
            byteCount: Int(streamSize),
            alignment: MemoryLayout<AudioBufferList>.alignment
        )
        defer { raw.deallocate() }
        guard AudioObjectGetPropertyData(deviceID, &streamAddress, 0, nil, &streamSize, raw) == noErr else {
            return 0
        }
        let list = raw.assumingMemoryBound(to: AudioBufferList.self)
        return UnsafeMutableAudioBufferListPointer(list).reduce(0) { $0 + Int($1.mNumberChannels) }
    }

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
        for device in audioDeviceIDs() {
            guard stringProperty(device, kAudioDevicePropertyDeviceUID) == uid else { continue }
            if inputChannelCount(device) > 0 { return device }
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
