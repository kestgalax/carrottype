import AppKit
import Carbon
import Foundation

struct KeyChord: Equatable, Hashable, Codable {
    var keyCode: UInt16
    var carbonModifiers: UInt32

    static let `default` = KeyChord(keyCode: 44, carbonModifiers: UInt32(optionKey)) // ⌥/
    /// Default selection-transform chord (ADR-012): ⌥'
    static let defaultTransform = KeyChord(
        keyCode: 39,
        carbonModifiers: UInt32(optionKey)
    )

    var displayString: String {
        var parts: [String] = []
        if carbonModifiers & UInt32(controlKey) != 0 { parts.append("⌃") }
        if carbonModifiers & UInt32(optionKey) != 0 { parts.append("⌥") }
        if carbonModifiers & UInt32(shiftKey) != 0 { parts.append("⇧") }
        if carbonModifiers & UInt32(cmdKey) != 0 { parts.append("⌘") }
        parts.append(Self.keyLabel(for: keyCode))
        return parts.joined()
    }

    static func from(event: NSEvent) -> KeyChord? {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let hasModifier = flags.contains(.command)
            || flags.contains(.option)
            || flags.contains(.control)
            || flags.contains(.shift)
        guard hasModifier else { return nil }

        let keyCode = event.keyCode
        let modifierKeyCodes: Set<UInt16> = [54, 55, 56, 57, 58, 59, 60, 61, 62, 63]
        guard !modifierKeyCodes.contains(keyCode) else { return nil }

        return KeyChord(keyCode: keyCode, carbonModifiers: carbonModifiers(from: flags))
    }

    static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var carbon: UInt32 = 0
        if flags.contains(.command) { carbon |= UInt32(cmdKey) }
        if flags.contains(.option) { carbon |= UInt32(optionKey) }
        if flags.contains(.control) { carbon |= UInt32(controlKey) }
        if flags.contains(.shift) { carbon |= UInt32(shiftKey) }
        return carbon
    }

    /// True when this event ends the held chord (key-up of the key, or a required modifier dropped).
    func isReleased(by event: NSEvent) -> Bool {
        switch event.type {
        case .keyUp:
            return event.keyCode == keyCode
        case .flagsChanged:
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let current = Self.carbonModifiers(from: flags)
            return (current & carbonModifiers) != carbonModifiers
        default:
            return false
        }
    }

    private static func keyLabel(for keyCode: UInt16) -> String {
        switch keyCode {
        case 36: return "↩"
        case 48: return "⇥"
        case 49: return "Space"
        case 51: return "⌫"
        case 53: return "Esc"
        case 122: return "F1"
        case 120: return "F2"
        case 99: return "F3"
        case 118: return "F4"
        case 96: return "F5"
        case 97: return "F6"
        case 98: return "F7"
        case 100: return "F8"
        case 101: return "F9"
        case 109: return "F10"
        case 103: return "F11"
        case 111: return "F12"
        case 123: return "←"
        case 124: return "→"
        case 125: return "↓"
        case 126: return "↑"
        default:
            let source = TISCopyCurrentKeyboardLayoutInputSource().takeRetainedValue()
            guard let layoutDataRef = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else {
                return "Key\(keyCode)"
            }
            let data = Unmanaged<CFData>.fromOpaque(layoutDataRef).takeUnretainedValue() as Data
            return data.withUnsafeBytes { raw -> String in
                guard let layout = raw.bindMemory(to: UCKeyboardLayout.self).baseAddress else {
                    return "Key\(keyCode)"
                }
                var deadKeyState: UInt32 = 0
                var chars = [UniChar](repeating: 0, count: 4)
                var length = 0
                let err = UCKeyTranslate(
                    layout,
                    keyCode,
                    UInt16(kUCKeyActionDisplay),
                    0,
                    UInt32(LMGetKbdType()),
                    OptionBits(kUCKeyTranslateNoDeadKeysBit),
                    &deadKeyState,
                    chars.count,
                    &length,
                    &chars
                )
                guard err == noErr, length > 0 else { return "Key\(keyCode)" }
                return String(utf16CodeUnits: chars, count: length).uppercased()
            }
        }
    }
}

enum HotkeyCaptureTarget: Equatable {
    case dictation
    case transformBinding(UUID)
}

/// Carbon callbacks cannot capture Swift context; bridge via unsafe pointer.
private func carrottypeHotKeyEventHandler(
    _ nextHandler: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let userData, let event else { return noErr }
    let service = Unmanaged<HotkeyService>.fromOpaque(userData).takeUnretainedValue()
    var hkID = EventHotKeyID()
    GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hkID
    )
    guard hkID.signature == OSType(0x43525450) else { return noErr } // 'CRTP'
    let isRelease = GetEventKind(event) == UInt32(kEventHotKeyReleased)
    DispatchQueue.main.async {
        switch hkID.id {
        case 1:
            if isRelease {
                service.handleCarbonHotkeyReleased()
            } else {
                service.handleCarbonHotkeyPressed()
            }
        case 2:
            if !isRelease {
                service.handleCarbonEscapeCancel()
            }
        default:
            if !isRelease, hkID.id >= 3 {
                service.handleCarbonTransformHotkey(carbonID: hkID.id)
            }
        }
    }
    return noErr
}

@MainActor
final class HotkeyService: ObservableObject {
    @Published private(set) var chord: KeyChord
    @Published private(set) var transformBindings: [TransformBinding] = []
    @Published var isRecording = false
    @Published private(set) var captureTarget: HotkeyCaptureTarget?
    @Published private(set) var lastCaptureConflict = false
    @Published private(set) var lastConflictTarget: HotkeyCaptureTarget?

    private let defaults: UserDefaults
    private var hotKeyRef: EventHotKeyRef?
    private var transformHotKeyRefs: [EventHotKeyRef?] = []
    private var transformCarbonIDByBindingID: [UUID: UInt32] = [:]
    private var escapeHotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var localMonitor: Any?
    private var pttGlobalReleaseMonitor: Any?
    private var pttLocalReleaseMonitor: Any?
    private var onHotkey: (() -> Void)?
    private var onHotkeyReleased: (() -> Void)?
    private var onTransformHotkey: ((UUID) -> Void)?
    private var onEscapeCancel: (() -> Void)?

    private let hotKeyID = EventHotKeyID(signature: OSType(0x43525450), id: 1) // 'CRTP'
    private let escapeHotKeyID = EventHotKeyID(signature: OSType(0x43525450), id: 2)

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let dictation: KeyChord
        if let data = defaults.data(forKey: Keys.dictationChord),
           let saved = try? JSONDecoder().decode(KeyChord.self, from: data) {
            dictation = saved
        } else {
            dictation = .default
        }
        self.chord = dictation
        if defaults.data(forKey: Keys.dictationChord) == nil {
            persistDictation(dictation)
        }
        // Bindings applied by AppState via `replaceTransformBindings` once preferred MLX mode is known.
        self.transformBindings = []
    }

    var displayString: String { chord.displayString }

    func setOnHotkey(_ handler: @escaping () -> Void) {
        onHotkey = handler
    }

    func setOnHotkeyReleased(_ handler: @escaping () -> Void) {
        onHotkeyReleased = handler
    }

    func setOnTransformHotkey(_ handler: @escaping (UUID) -> Void) {
        onTransformHotkey = handler
    }

    func setOnEscapeCancel(_ handler: @escaping () -> Void) {
        onEscapeCancel = handler
    }

    func handleCarbonHotkeyPressed() {
        onHotkey?()
    }

    func handleCarbonHotkeyReleased() {
        emitDictationReleased()
    }

    /// Hold-to-talk safety net: Carbon `kEventHotKeyReleased` is not always delivered.
    func startPushToTalkReleaseMonitor() {
        stopPushToTalkReleaseMonitor()
        pttGlobalReleaseMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.keyUp, .flagsChanged]
        ) { [weak self] event in
            Task { @MainActor in
                self?.handlePushToTalkReleaseEvent(event)
            }
        }
        pttLocalReleaseMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.keyUp, .flagsChanged]
        ) { [weak self] event in
            Task { @MainActor in
                self?.handlePushToTalkReleaseEvent(event)
            }
            return event
        }
    }

    func stopPushToTalkReleaseMonitor() {
        if let pttGlobalReleaseMonitor {
            NSEvent.removeMonitor(pttGlobalReleaseMonitor)
            self.pttGlobalReleaseMonitor = nil
        }
        if let pttLocalReleaseMonitor {
            NSEvent.removeMonitor(pttLocalReleaseMonitor)
            self.pttLocalReleaseMonitor = nil
        }
    }

    func handleCarbonTransformHotkey(carbonID: UInt32) {
        guard let bindingID = transformCarbonIDByBindingID.first(where: { $0.value == carbonID })?.key else {
            return
        }
        onTransformHotkey?(bindingID)
    }

    func handleCarbonEscapeCancel() {
        onEscapeCancel?()
    }

    func setEscapeCancelRegistered(_ enabled: Bool) {
        if enabled {
            registerEscapeCancelHotkey()
        } else {
            unregisterEscapeCancelHotkey()
        }
    }

    /// Replace bindings (from AppState) and re-register hotkeys.
    func replaceTransformBindings(_ bindings: [TransformBinding]) {
        transformBindings = Array(bindings.prefix(TransformBinding.maxCount))
        TransformBindingsStore.save(transformBindings, defaults: defaults)
        // Drop legacy single-chord key once bindings own chords.
        defaults.removeObject(forKey: Keys.legacyTransformChord)
        defaults.removeObject(forKey: Keys.legacyTransformDisplay)
        registerGlobalHotkey()
        objectWillChange.send()
    }

    func binding(id: UUID) -> TransformBinding? {
        transformBindings.first { $0.id == id }
    }

    func startRecording(for target: HotkeyCaptureTarget = .dictation) {
        stopRecordingMonitor()
        lastCaptureConflict = false
        lastConflictTarget = nil
        captureTarget = target
        isRecording = true
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            if event.keyCode == 53 { // Esc
                Task { @MainActor in self.cancelRecording() }
                return nil
            }
            guard let chord = KeyChord.from(event: event) else { return event }
            Task { @MainActor in self.apply(chord, for: target) }
            return nil
        }
    }

    func cancelRecording() {
        stopRecordingMonitor()
        isRecording = false
        captureTarget = nil
    }

    func apply(_ chord: KeyChord, for target: HotkeyCaptureTarget) {
        stopRecordingMonitor()
        isRecording = false
        captureTarget = nil

        switch target {
        case .dictation:
            if transformBindings.contains(where: { $0.chord == chord }) {
                lastCaptureConflict = true
                lastConflictTarget = .dictation
                return
            }
            lastCaptureConflict = false
            lastConflictTarget = nil
            self.chord = chord
            persistDictation(chord)
            registerGlobalHotkey()
        case .transformBinding(let id):
            if chord == self.chord || transformBindings.contains(where: { $0.id != id && $0.chord == chord }) {
                lastCaptureConflict = true
                lastConflictTarget = target
                return
            }
            lastCaptureConflict = false
            lastConflictTarget = nil
            guard let index = transformBindings.firstIndex(where: { $0.id == id }) else { return }
            transformBindings[index].chord = chord
            TransformBindingsStore.save(transformBindings, defaults: defaults)
            registerGlobalHotkey()
            objectWillChange.send()
        }
    }

    func resetToDefault() {
        apply(.default, for: .dictation)
    }

    func resetTransformBindingToDefault(id: UUID) {
        apply(.defaultTransform, for: .transformBinding(id))
    }

    func registerGlobalHotkey() {
        unregisterGlobalHotkey()
        installHandlerIfNeeded()

        var dictationRef: EventHotKeyRef?
        let dictationStatus = RegisterEventHotKey(
            UInt32(chord.keyCode),
            chord.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &dictationRef
        )
        if dictationStatus == noErr {
            hotKeyRef = dictationRef
        } else {
            NSLog("CarrotType: RegisterEventHotKey dictation failed status=%d", dictationStatus)
        }

        transformCarbonIDByBindingID.removeAll()
        transformHotKeyRefs = []
        for (offset, binding) in transformBindings.enumerated() {
            let carbonID = UInt32(3 + offset)
            let hotKeyID = EventHotKeyID(signature: OSType(0x43525450), id: carbonID)
            var ref: EventHotKeyRef?
            let status = RegisterEventHotKey(
                UInt32(binding.chord.keyCode),
                binding.chord.carbonModifiers,
                hotKeyID,
                GetApplicationEventTarget(),
                0,
                &ref
            )
            if status == noErr {
                transformHotKeyRefs.append(ref)
                transformCarbonIDByBindingID[binding.id] = carbonID
            } else {
                transformHotKeyRefs.append(nil)
                NSLog("CarrotType: RegisterEventHotKey transform[%d] failed status=%d", offset, status)
            }
        }
    }

    func unregisterGlobalHotkey() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        for ref in transformHotKeyRefs {
            if let ref {
                UnregisterEventHotKey(ref)
            }
        }
        transformHotKeyRefs = []
        transformCarbonIDByBindingID.removeAll()
    }

    private func registerEscapeCancelHotkey() {
        unregisterEscapeCancelHotkey()
        installHandlerIfNeeded()

        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            53,
            0,
            escapeHotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )
        if status == noErr {
            escapeHotKeyRef = ref
        } else {
            NSLog("CarrotType: RegisterEventHotKey Escape failed status=%d", status)
        }
    }

    private func unregisterEscapeCancelHotkey() {
        if let escapeHotKeyRef {
            UnregisterEventHotKey(escapeHotKeyRef)
            self.escapeHotKeyRef = nil
        }
    }

    private func persistDictation(_ chord: KeyChord) {
        if let data = try? JSONEncoder().encode(chord) {
            defaults.set(data, forKey: Keys.dictationChord)
        }
        defaults.set(chord.displayString, forKey: Keys.dictationDisplay)
    }

    private func stopRecordingMonitor() {
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
    }

    private func handlePushToTalkReleaseEvent(_ event: NSEvent) {
        guard chord.isReleased(by: event) else { return }
        emitDictationReleased()
    }

    private func emitDictationReleased() {
        stopPushToTalkReleaseMonitor()
        onHotkeyReleased?()
    }

    private func installHandlerIfNeeded() {
        guard eventHandler == nil else { return }

        var eventTypes: [EventTypeSpec] = [
            EventTypeSpec(
                eventClass: OSType(kEventClassKeyboard),
                eventKind: UInt32(kEventHotKeyPressed)
            ),
            EventTypeSpec(
                eventClass: OSType(kEventClassKeyboard),
                eventKind: UInt32(kEventHotKeyReleased)
            ),
        ]
        let pointer = Unmanaged.passUnretained(self).toOpaque()
        _ = eventTypes.withUnsafeMutableBufferPointer { buffer in
            guard let base = buffer.baseAddress else { return OSStatus(paramErr) }
            return InstallEventHandler(
                GetApplicationEventTarget(),
                carrottypeHotKeyEventHandler,
                2,
                base,
                pointer,
                &eventHandler
            )
        }
    }

    private enum Keys {
        static let dictationChord = "carrottype.hotkeyChord"
        static let dictationDisplay = "carrottype.hotkeyDisplay"
        static let legacyTransformChord = "carrottype.transformHotkeyChord"
        static let legacyTransformDisplay = "carrottype.transformHotkeyDisplay"
    }
}
