import AppKit
import Carbon
import Foundation

struct KeyChord: Equatable, Codable {
    var keyCode: UInt16
    var carbonModifiers: UInt32

    static let `default` = KeyChord(keyCode: 49, carbonModifiers: UInt32(controlKey | optionKey)) // ⌃⌥Space

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

    private static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var carbon: UInt32 = 0
        if flags.contains(.command) { carbon |= UInt32(cmdKey) }
        if flags.contains(.option) { carbon |= UInt32(optionKey) }
        if flags.contains(.control) { carbon |= UInt32(controlKey) }
        if flags.contains(.shift) { carbon |= UInt32(shiftKey) }
        return carbon
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
    if hkID.signature == OSType(0x43525450), hkID.id == 1 { // 'CRTP'
        DispatchQueue.main.async {
            service.handleCarbonHotkey()
        }
    }
    return noErr
}

@MainActor
final class HotkeyService: ObservableObject {
    @Published private(set) var chord: KeyChord
    @Published var isRecording = false

    private let defaults: UserDefaults
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var localMonitor: Any?
    private var onHotkey: (() -> Void)?

    private let hotKeyID = EventHotKeyID(signature: OSType(0x43525450), id: 1) // 'CRTP'

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: "carrottype.hotkeyChord"),
           let saved = try? JSONDecoder().decode(KeyChord.self, from: data) {
            self.chord = saved
        } else {
            self.chord = .default
            persist(chord)
        }
    }

    var displayString: String { chord.displayString }

    func setOnHotkey(_ handler: @escaping () -> Void) {
        onHotkey = handler
    }

    func handleCarbonHotkey() {
        onHotkey?()
    }

    func startRecording() {
        stopRecordingMonitor()
        isRecording = true
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            if event.keyCode == 53 { // Esc
                Task { @MainActor in self.cancelRecording() }
                return nil
            }
            guard let chord = KeyChord.from(event: event) else { return event }
            Task { @MainActor in self.apply(chord) }
            return nil
        }
    }

    func cancelRecording() {
        stopRecordingMonitor()
        isRecording = false
    }

    func apply(_ chord: KeyChord) {
        stopRecordingMonitor()
        isRecording = false
        self.chord = chord
        persist(chord)
        registerGlobalHotkey()
    }

    func resetToDefault() {
        apply(.default)
    }

    func registerGlobalHotkey() {
        unregisterGlobalHotkey()
        installHandlerIfNeeded()

        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            UInt32(chord.keyCode),
            chord.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )
        if status == noErr {
            hotKeyRef = ref
        } else {
            NSLog("CarrotType: RegisterEventHotKey failed status=%d", status)
        }
    }

    func unregisterGlobalHotkey() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }

    private func persist(_ chord: KeyChord) {
        if let data = try? JSONEncoder().encode(chord) {
            defaults.set(data, forKey: "carrottype.hotkeyChord")
        }
        defaults.set(chord.displayString, forKey: "carrottype.hotkeyDisplay")
    }

    private func stopRecordingMonitor() {
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
    }

    private func installHandlerIfNeeded() {
        guard eventHandler == nil else { return }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let pointer = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(),
            carrottypeHotKeyEventHandler,
            1,
            &eventType,
            pointer,
            &eventHandler
        )
    }
}
