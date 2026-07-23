import CoreAudio
import Foundation
import Network

/// Temporarily clears input mute for a dictation session and restores the prior state.
/// Hybrid: Wave Link JSON-RPC for Elgato-looking devices when Wave Link is up; else Core Audio HAL mute.
/// See ADR-007 and `docs/research-mic-unmute-spike.md`.
@MainActor
final class MicMuteController {
    private var activeSession: Session?

    private struct Session {
        let deviceUID: String
        let wasMuted: Bool
        let backend: Backend
        let waveDeviceId: String?
        let waveInputId: String?
    }

    private enum Backend {
        case coreAudio
        case waveLink
    }

    /// Snapshot mute and unmute if needed. No-op when already unmuted or unsupported.
    func beginDictationUnmute(deviceUID: String, deviceName: String) async {
        await endDictationRestore()

        guard !deviceUID.isEmpty else { return }

        // Prefer Wave Link whenever the selected capture path looks Elgato-related
        // (raw Wave:3, Stream Mix, MicrophoneFX, etc.) — hardware mute lives on commonWave.
        if looksLikeWaveFamily(deviceName: deviceName),
           let wave = await WaveLinkClient.shared.prepareUnmute(preferredName: deviceName) {
            activeSession = Session(
                deviceUID: deviceUID,
                wasMuted: wave.wasMuted,
                backend: .waveLink,
                waveDeviceId: wave.deviceId,
                waveInputId: wave.inputId
            )
            if wave.wasMuted {
                _ = await WaveLinkClient.shared.setInputMuted(
                    deviceId: wave.deviceId,
                    inputId: wave.inputId,
                    muted: false
                )
            }
            return
        }

        guard let wasMuted = CoreAudioInputMute.isMuted(deviceUID: deviceUID) else { return }
        activeSession = Session(
            deviceUID: deviceUID,
            wasMuted: wasMuted,
            backend: .coreAudio,
            waveDeviceId: nil,
            waveInputId: nil
        )
        if wasMuted {
            _ = CoreAudioInputMute.setMuted(deviceUID: deviceUID, muted: false)
        }
    }

    /// Restore mute state captured at session start. Safe to call multiple times.
    func endDictationRestore() async {
        guard let session = activeSession else { return }
        activeSession = nil

        guard session.wasMuted else { return }

        switch session.backend {
        case .coreAudio:
            _ = CoreAudioInputMute.setMuted(deviceUID: session.deviceUID, muted: true)
        case .waveLink:
            if let deviceId = session.waveDeviceId, let inputId = session.waveInputId {
                _ = await WaveLinkClient.shared.setInputMuted(
                    deviceId: deviceId,
                    inputId: inputId,
                    muted: true
                )
            }
        }
    }

    /// Best-effort restore on quit (async Wave Link may not finish; Core Audio is sync).
    func restoreSynchronouslyOnQuit() {
        guard let session = activeSession else { return }
        activeSession = nil
        guard session.wasMuted else { return }
        switch session.backend {
        case .coreAudio:
            _ = CoreAudioInputMute.setMuted(deviceUID: session.deviceUID, muted: true)
        case .waveLink:
            let deviceId = session.waveDeviceId
            let inputId = session.waveInputId
            Task {
                if let deviceId, let inputId {
                    _ = await WaveLinkClient.shared.setInputMuted(
                        deviceId: deviceId,
                        inputId: inputId,
                        muted: true
                    )
                }
            }
        }
    }

    private func looksLikeWaveFamily(deviceName: String) -> Bool {
        let lower = deviceName.lowercased()
        return lower.contains("wave") || lower.contains("elgato")
    }
}

// MARK: - Core Audio

enum CoreAudioInputMute {
    nonisolated static func isMuted(deviceUID: String) -> Bool? {
        guard let deviceID = audioDeviceID(forUID: deviceUID) else { return nil }
        guard isMuteSettable(deviceID: deviceID) else { return nil }
        var address = muteAddress()
        var muted: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &muted)
        guard status == noErr else { return nil }
        return muted != 0
    }

    @discardableResult
    nonisolated static func setMuted(deviceUID: String, muted: Bool) -> Bool {
        guard let deviceID = audioDeviceID(forUID: deviceUID) else { return false }
        guard isMuteSettable(deviceID: deviceID) else { return false }
        var address = muteAddress()
        var value: UInt32 = muted ? 1 : 0
        let size = UInt32(MemoryLayout<UInt32>.size)
        let status = AudioObjectSetPropertyData(deviceID, &address, 0, nil, size, &value)
        return status == noErr
    }

    nonisolated private static func isMuteSettable(deviceID: AudioDeviceID) -> Bool {
        var address = muteAddress()
        return AudioObjectHasProperty(deviceID, &address)
            && {
                var settable: DarwinBoolean = false
                let status = AudioObjectIsPropertySettable(deviceID, &address, &settable)
                return status == noErr && settable.boolValue
            }()
    }

    nonisolated private static func muteAddress() -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
    }

    nonisolated private static func audioDeviceID(forUID uid: String) -> AudioDeviceID? {
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
                return device
            }
        }
        return nil
    }
}

// MARK: - Wave Link (unofficial local JSON-RPC)

/// Minimal Wave Link client for hardware input mute. Protocol reverse-engineered from Stream Deck plugin.
/// Wave Link 3 on macOS rejects JSON-RPC requests with `"params": null` — omit the key or send `{}`.
actor WaveLinkClient {
    static let shared = WaveLinkClient()

    /// Prefer the live Wave Link 3 range first (observed open on 1884); keep 1824 as legacy fallback.
    private let ports: [UInt16] = Array(1884...1893) + [1824]

    struct UnmutePrep {
        let deviceId: String
        let inputId: String
        let wasMuted: Bool
    }

    func prepareUnmute(preferredName: String) async -> UnmutePrep? {
        guard let connection = await connectVerified() else { return nil }
        defer { connection.close() }

        _ = await connection.request(method: "setPluginInfo", params: ["connectedDevices": ["SD"]])

        guard let devicesValue = await connection.request(method: "getInputDevices", params: nil),
              let result = devicesValue as? [String: Any],
              let devices = result["inputDevices"] as? [[String: Any]]
        else {
            return nil
        }

        guard let match = pickWaveInput(devices: devices, preferredName: preferredName) else {
            return nil
        }
        return UnmutePrep(deviceId: match.deviceId, inputId: match.inputId, wasMuted: match.isMuted)
    }

    func setInputMuted(deviceId: String, inputId: String, muted: Bool) async -> Bool {
        guard let connection = await connectVerified() else { return false }
        defer { connection.close() }

        let params: [String: Any] = [
            "id": deviceId,
            "inputs": [
                [
                    "id": inputId,
                    "isMuted": muted,
                ],
            ],
        ]
        return await connection.request(method: "setInputDevice", params: params) != nil
    }

    private func pickWaveInput(
        devices: [[String: Any]],
        preferredName: String
    ) -> (deviceId: String, inputId: String, isMuted: Bool)? {
        let preferred = preferredName.lowercased()

        func score(_ device: [String: Any]) -> Int {
            let name = (device["name"] as? String ?? "").lowercased()
            let type = (device["deviceType"] as? String ?? "").lowercased()
            let isWave = (device["isWaveDevice"] as? Bool) == true
            var s = 0
            // Hardware Wave mute (LED) lives on commonWave — always prefer it.
            if type == "commonwave" || type.contains("wave") || isWave { s += 20 }
            if name.contains("wave:3") || name.hasPrefix("wave:") { s += 10 }
            if name.contains("wave") || name.contains("elgato") { s += 3 }
            // Deprioritize virtual mixes so we unmute the mic, not Stream/Main.
            if name.contains("stream") || name.contains("microphonefx") || name.contains(" main") {
                s -= 15
            }
            if !preferred.isEmpty, name.contains(preferred) || preferred.contains(name) { s += 2 }
            return s
        }

        let ranked = devices
            .map { ($0, score($0)) }
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }

        for (device, _) in ranked {
            guard let deviceId = device["id"] as? String,
                  let inputs = device["inputs"] as? [[String: Any]],
                  let input = inputs.first,
                  let inputId = input["id"] as? String
            else { continue }
            let isMuted = input["isMuted"] as? Bool ?? false
            return (deviceId, inputId, isMuted)
        }
        return nil
    }

    /// Connect only to a port that answers `getApplicationInfo` (Wave Link 3 rejects `params: null`).
    private func connectVerified() async -> WaveLinkConnection? {
        for port in ports {
            guard await tcpPortOpen(port) else { continue }
            guard let connection = await WaveLinkConnection.open(port: port) else { continue }
            if await connection.request(method: "getApplicationInfo", params: nil) != nil {
                return connection
            }
            connection.close()
        }
        return nil
    }

    private func tcpPortOpen(_ port: UInt16) async -> Bool {
        await withCheckedContinuation { cont in
            let queue = DispatchQueue(label: "carrottype.wavelink.portcheck")
            let connection = NWConnection(
                host: NWEndpoint.Host("127.0.0.1"),
                port: NWEndpoint.Port(rawValue: port)!,
                using: .tcp
            )
            var resumed = false
            let finish: (Bool) -> Void = { ok in
                guard !resumed else { return }
                resumed = true
                connection.cancel()
                cont.resume(returning: ok)
            }
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready: finish(true)
                case .failed, .cancelled: finish(false)
                default: break
                }
            }
            connection.start(queue: queue)
            queue.asyncAfter(deadline: .now() + 0.25) {
                finish(false)
            }
        }
    }
}

private final class WaveLinkConnection: @unchecked Sendable {
    private let task: URLSessionWebSocketTask
    private let session: URLSession
    private var nextID = 1
    private let lock = NSLock()

    private init(task: URLSessionWebSocketTask, session: URLSession) {
        self.task = task
        self.session = session
    }

    static func open(port: UInt16) async -> WaveLinkConnection? {
        guard let url = URL(string: "ws://127.0.0.1:\(port)") else { return nil }
        var request = URLRequest(url: url, timeoutInterval: 2)
        request.setValue("streamdeck://", forHTTPHeaderField: "Origin")

        let session = URLSession(configuration: .ephemeral)
        let task = session.webSocketTask(with: request)
        task.resume()
        // Brief settle so the handshake can complete before the first send.
        try? await Task.sleep(nanoseconds: 80_000_000)
        guard task.state == .running else {
            task.cancel(with: .goingAway, reason: nil)
            session.invalidateAndCancel()
            return nil
        }
        return WaveLinkConnection(task: task, session: session)
    }

    func close() {
        task.cancel(with: .goingAway, reason: nil)
        session.invalidateAndCancel()
    }

    func request(method: String, params: Any?) async -> Any? {
        lock.lock()
        let id = nextID
        nextID += 1
        lock.unlock()

        var payload: [String: Any] = [
            "id": id,
            "jsonrpc": "2.0",
            "method": method,
        ]
        // Wave Link 3: `"params": null` → -32602 Invalid params. Omit key or send {}.
        if let params {
            payload["params"] = params
        }

        guard JSONSerialization.isValidJSONObject(payload),
              let data = try? JSONSerialization.data(withJSONObject: payload),
              let text = String(data: data, encoding: .utf8)
        else {
            return nil
        }

        do {
            // Text frames match Stream Deck / community clients; binary often fails silently.
            try await task.send(.string(text))
        } catch {
            return nil
        }

        let deadline = Date().addingTimeInterval(1.5)
        while Date() < deadline {
            do {
                let message = try await task.receive()
                let data: Data
                switch message {
                case .data(let d): data = d
                case .string(let s): data = Data(s.utf8)
                @unknown default: continue
                }
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                else { continue }
                if json["error"] != nil {
                    return nil
                }
                if responseID(json["id"]) == id {
                    return json["result"] ?? [:]
                }
                if json["id"] == nil, json["method"] != nil {
                    continue
                }
            } catch {
                return nil
            }
        }
        return nil
    }

    private func responseID(_ value: Any?) -> Int? {
        if let i = value as? Int { return i }
        if let n = value as? NSNumber { return n.intValue }
        return nil
    }
}
