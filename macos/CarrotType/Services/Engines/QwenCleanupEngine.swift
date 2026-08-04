import Foundation

enum CleanupEngineError: LocalizedError {
    case modelMissing
    case generationFailed
    case notAppleSilicon
    case helperMissing

    var errorDescription: String? {
        switch self {
        case .modelMissing: return L10n.t("error.cleanup_model_missing")
        case .generationFailed: return L10n.t("error.cleanup_failed")
        case .notAppleSilicon: return L10n.t("error.cleanup_not_silicon")
        case .helperMissing: return L10n.t("error.cleanup_failed")
        }
    }
}

/// Spawns `CarrotTypeCleanupHelper` for Smart/Smart+/Gemma (ADR-009 / ADR-010). No in-process MLX.
actor QwenCleanupEngine: CleanupEngine {
    /// Wall-clock budget for cold load + generate (helper is killed on timeout).
    private static let timeoutNanoseconds: UInt64 = 120_000_000_000

    func cleanup(
        text: String,
        mode: CleanupMode,
        modelDirectory: URL?,
        instructions: String?
    ) async throws -> String {
        switch mode {
        case .off:
            return text
        case .light:
            return TextCleanup.apply(text, mode: .light)
        case .smart, .smartPlus, .gemma:
            break
        }

        #if arch(arm64)
        guard let modelDirectory else { throw CleanupEngineError.modelMissing }
        guard QwenCleanupPackage.isPackageReady(at: modelDirectory) else {
            throw CleanupEngineError.modelMissing
        }
        guard let helperURL = Self.helperExecutableURL() else {
            throw CleanupEngineError.helperMissing
        }

        let request = CleanupHelperRequest(
            text: text,
            mode: mode.rawValue,
            modelDirectory: modelDirectory.path,
            instructions: instructions
        )
        let requestData = try JSONEncoder().encode(request)
        let response = try await Self.runHelper(
            executable: helperURL,
            requestData: requestData,
            timeoutNanoseconds: Self.timeoutNanoseconds
        )
        if response.ok, let cleaned = response.text, !cleaned.isEmpty {
            return cleaned
        }
        switch response.error {
        case "modelMissing": throw CleanupEngineError.modelMissing
        case "notAppleSilicon": throw CleanupEngineError.notAppleSilicon
        default: throw CleanupEngineError.generationFailed
        }
        #else
        throw CleanupEngineError.notAppleSilicon
        #endif
    }

    func unload() async {
        // Helper exits after each request; nothing resident in the host.
    }

    private static func helperExecutableURL() -> URL? {
        if let url = Bundle.main.url(forAuxiliaryExecutable: "CarrotTypeCleanupHelper") {
            return url
        }
        guard let exec = Bundle.main.executableURL else { return nil }
        let sibling = exec.deletingLastPathComponent()
            .appendingPathComponent("CarrotTypeCleanupHelper", isDirectory: false)
        return FileManager.default.isExecutableFile(atPath: sibling.path) ? sibling : nil
    }

    private static func runHelper(
        executable: URL,
        requestData: Data,
        timeoutNanoseconds: UInt64
    ) async throws -> CleanupHelperResponse {
        let box = ProcessBox(executable: executable)
        return try await withThrowingTaskGroup(of: CleanupHelperResponse.self) { group in
            group.addTask {
                try box.run(requestData: requestData)
            }
            group.addTask {
                try await Task.sleep(nanoseconds: timeoutNanoseconds)
                box.terminate()
                throw CleanupEngineError.generationFailed
            }
            let first = try await group.next()!
            group.cancelAll()
            box.terminate()
            return first
        }
    }
}

/// `Process` is not Sendable; isolate for timeout + wait tasks.
private final class ProcessBox: @unchecked Sendable {
    private let process = Process()
    private let stdin = Pipe()
    private let stdout = Pipe()
    private let stderr = Pipe()
    private let lock = NSLock()

    init(executable: URL) {
        process.executableURL = executable
        process.standardInput = stdin
        process.standardOutput = stdout
        process.standardError = stderr
    }

    func run(requestData: Data) throws -> CleanupHelperResponse {
        try process.run()
        stdin.fileHandleForWriting.write(requestData)
        try stdin.fileHandleForWriting.close()
        process.waitUntilExit()
        let outData = stdout.fileHandleForReading.readDataToEndOfFile()
        _ = stderr.fileHandleForReading.readDataToEndOfFile()
        if process.terminationStatus != 0, outData.isEmpty {
            throw CleanupEngineError.generationFailed
        }
        let lineData: Data
        if let newline = outData.firstIndex(of: UInt8(ascii: "\n")) {
            lineData = outData.subdata(in: outData.startIndex..<newline)
        } else {
            lineData = outData
        }
        guard let response = try? JSONDecoder().decode(CleanupHelperResponse.self, from: lineData) else {
            throw CleanupEngineError.generationFailed
        }
        return response
    }

    func terminate() {
        lock.lock()
        defer { lock.unlock() }
        if process.isRunning {
            process.terminate()
        }
    }
}
