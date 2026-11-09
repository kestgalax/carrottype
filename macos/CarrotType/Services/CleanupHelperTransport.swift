import Foundation
import Darwin

enum CleanupHelperTransportError: Error {
    case timedOut, outputLimit, unsuccessfulExit
}

/// Session-scoped transport. Pipe readers run concurrently with the process and stdin writer.
enum CleanupHelperTransport {
    static func run(
        executable: URL,
        request: Data,
        timeout: TimeInterval = 120,
        outputLimit: Int = 4 * 1024 * 1024
    ) async throws -> Data {
        let session = HelperProcessSession(executable: executable, outputLimit: outputLimit)
        return try await withTaskCancellationHandler {
            try Task.checkCancellation()
            let data = try await withCheckedThrowingContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    let timer = DispatchWorkItem { session.stop(reason: .timedOut) }
                    DispatchQueue.global().asyncAfter(deadline: .now() + timeout, execute: timer)
                    defer { timer.cancel() }
                    do { continuation.resume(returning: try session.run(request: request)) }
                    catch { continuation.resume(throwing: error) }
                }
            }
            try Task.checkCancellation()
            return data
        } onCancel: {
            session.stop()
        }
    }
}

private final class HelperProcessSession: @unchecked Sendable {
    private let process = Process()
    private let input = Pipe()
    private let output = Pipe()
    private let diagnostic = Pipe()
    private let lock = NSLock()
    private let outputLimit: Int
    private let inputSuppressesSIGPIPE: Bool
    private var stopped = false
    private var failure: CleanupHelperTransportError?
    private var response = Data()

    init(executable: URL, outputLimit: Int) {
        self.outputLimit = outputLimit
        process.executableURL = executable
        process.standardInput = input
        process.standardOutput = output
        process.standardError = diagnostic
        // A helper can exit before reading stdin. Suppress SIGPIPE on this descriptor only,
        // so FileHandle reports EPIPE instead of terminating the menu-bar app.
        inputSuppressesSIGPIPE = fcntl(input.fileHandleForWriting.fileDescriptor, F_SETNOSIGPIPE, 1) == 0
    }

    func run(request: Data) throws -> Data {
        guard inputSuppressesSIGPIPE else { throw CleanupHelperTransportError.unsuccessfulExit }
        // Serialize launch with cancellation, so a cancellation before launch cannot orphan a child.
        lock.lock()
        if stopped {
            let error: Error = (failure as Error?) ?? CancellationError()
            lock.unlock()
            throw error
        }
        do { try process.run() }
        catch { lock.unlock(); throw error }
        lock.unlock()

        // Close parent copies of child-side descriptors so EOF is observable.
        try? output.fileHandleForWriting.close()
        try? diagnostic.fileHandleForWriting.close()
        try? input.fileHandleForReading.close()

        let readers = DispatchGroup()
        for (pipe, keep) in [(output, true), (diagnostic, false)] {
            readers.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                defer { readers.leave(); try? pipe.fileHandleForReading.close() }
                self.drain(pipe.fileHandleForReading, keep: keep)
            }
        }
        // Drain both output streams even if the helper exits before consuming all stdin.
        do { try input.fileHandleForWriting.write(contentsOf: request) }
        catch { stop(reason: .unsuccessfulExit) }
        try? input.fileHandleForWriting.close()
        process.waitUntilExit()
        readers.wait()

        lock.lock()
        defer { lock.unlock() }
        if let failure { throw failure }
        if stopped { throw CancellationError() }
        guard process.terminationStatus == 0 else { throw CleanupHelperTransportError.unsuccessfulExit }
        return response
    }

    private func drain(_ handle: FileHandle, keep: Bool) {
        var count = 0
        while let chunk = try? handle.read(upToCount: 16 * 1024), !chunk.isEmpty {
            count += chunk.count
            if count > outputLimit {
                stop(reason: .outputLimit)
                // Continue draining until termination, without retaining unbounded output.
                continue
            }
            if keep {
                lock.lock()
                response.append(chunk)
                lock.unlock()
            }
        }
    }

    func stop(reason: CleanupHelperTransportError? = nil) {
        lock.lock()
        defer { lock.unlock() }
        guard !stopped else { return }
        stopped = true
        failure = reason
        guard process.isRunning else { return }
        process.terminate()
        // SIGTERM is advisory; enforce the timeout even if the helper ignores it.
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) { [self] in
            lock.lock()
            defer { lock.unlock() }
            if process.isRunning { kill(process.processIdentifier, SIGKILL) }
        }
    }
}
