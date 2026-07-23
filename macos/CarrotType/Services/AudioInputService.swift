import AVFoundation
import CoreAudio
import Foundation

struct AudioInputDevice: Identifiable, Hashable {
    let id: String
    let name: String
    let isDefault: Bool
}

@MainActor
final class AudioInputService: ObservableObject {
    @Published private(set) var devices: [AudioInputDevice] = []
    @Published var selectedDeviceID: String

    private let defaults: UserDefaults
    private let selectedKey = "carrottype.selectedAudioInputID"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.selectedDeviceID = defaults.string(forKey: selectedKey) ?? ""
        refreshDevices()
    }

    var selectedDevice: AudioInputDevice? {
        devices.first(where: { $0.id == selectedDeviceID }) ?? devices.first
    }

    func refreshDevices() {
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.microphone, .external],
            mediaType: .audio,
            position: .unspecified
        )

        let defaultID = AVCaptureDevice.default(for: .audio)?.uniqueID
        let mapped = discovery.devices.map { device in
            AudioInputDevice(
                id: device.uniqueID,
                name: device.localizedName,
                isDefault: device.uniqueID == defaultID
            )
        }

        devices = mapped

        if selectedDeviceID.isEmpty || !mapped.contains(where: { $0.id == selectedDeviceID }) {
            if let defaultID, mapped.contains(where: { $0.id == defaultID }) {
                selectDevice(defaultID)
            } else if let first = mapped.first {
                selectDevice(first.id)
            } else {
                selectedDeviceID = ""
            }
        }
    }

    func selectDevice(_ id: String) {
        selectedDeviceID = id
        defaults.set(id, forKey: selectedKey)
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
