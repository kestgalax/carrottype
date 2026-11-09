import AppKit
import Foundation
import Darwin

/// Compiled against production ClipboardSnapshot and CleanupHelperTransport (no copied algorithms).
@main
struct DictationReliabilityChecks {
    static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else { fatalError(message) }
    }

    @MainActor
    static func clipboardChecks() {
        let board = NSPasteboard(name: .init("carrottype-tests-\(UUID().uuidString)"))
        defer { board.releaseGlobally() }
        board.clearContents()
        let empty = ClipboardSnapshot(board)
        board.setString("dictation", forType: .string)
        expect(empty.restore(board, ifUnchangedSince: board.changeCount), "restore empty")
        expect(board.pasteboardItems?.isEmpty ?? true, "clipboard must be empty")

        let first = NSPasteboardItem()
        first.setString("first", forType: .string)
        let rich = Data("{\\rtf1 rich}".utf8)
        first.setData(rich, forType: .rtf)
        let second = NSPasteboardItem()
        second.setString("second", forType: .string)
        board.clearContents()
        board.writeObjects([first, second])
        let snapshot = ClipboardSnapshot(board)
        board.clearContents()
        board.setString("dictation", forType: .string)
        expect(snapshot.restore(board, ifUnchangedSince: board.changeCount), "restore multi-item")
        expect(board.pasteboardItems?.count == 2, "preserve item count")
        expect(board.pasteboardItems?[0].data(forType: .rtf) == rich, "preserve rich type")
        expect(board.pasteboardItems?[1].string(forType: .string) == "second", "preserve second item")

        board.clearContents()
        board.setString("our temporary text", forType: .string)
        let owned = board.changeCount
        board.clearContents()
        board.setString("new user copy", forType: .string)
        expect(!snapshot.restore(board, ifUnchangedSince: owned), "do not restore over new copy")
        expect(board.string(forType: .string) == "new user copy", "preserve user copy")
        print("PASS clipboard: empty, rich/multiple items, concurrent copy")
    }

    @MainActor
    static func selectionChecks() async throws {
        let board = NSPasteboard(name: .init("carrottype-selection-tests-\(UUID().uuidString)"))
        defer { board.releaseGlobally() }
        board.clearContents()
        board.setString("previous", forType: .string)
        do {
            _ = try await SelectionTextService.readViaCopyFallback(pasteboard: board, postCopy: {})
            fatalError("no selection must not return previous clipboard")
        } catch SelectionTextError.noSelection {}
        expect(board.string(forType: .string) == "previous", "no copy leaves clipboard unchanged")
        let selected = try await SelectionTextService.readViaCopyFallback(pasteboard: board) {
            board.clearContents()
            board.setString("selection", forType: .string)
        }
        expect(selected == "selection", "return new selection")
        expect(board.string(forType: .string) == "previous", "restore after selection")

        let task = Task { @MainActor in
            try await SelectionTextService.readViaCopyFallback(pasteboard: board) {
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 30_000_000)
                    board.clearContents()
                    board.setString("late selection", forType: .string)
                }
            }
        }
        try await Task.sleep(nanoseconds: 10_000_000)
        task.cancel()
        do { _ = try await task.value; fatalError("selection cancellation must propagate") }
        catch is CancellationError {}
        expect(board.string(forType: .string) == "previous", "cancel cleans up delivered copy")
        print("PASS selection: no stale text, observed copy, delayed-copy cancellation cleanup")
    }

    static func protocolChecks() throws {
        let response = CleanupHelperResponse.success("text")
        let encoded = try JSONEncoder().encode(response)
        let decoded = try CleanupHelperResponse.decode(encoded)
        expect(decoded.text == "text", "decode response")
        do {
            _ = try CleanupHelperResponse.decode(Data("not json".utf8))
            fatalError("malformed response must fail")
        } catch is DecodingError {}
        do {
            _ = try CleanupHelperResponse.decode(Data(#"{"v":999,"ok":true,"text":"bad"}"#.utf8))
            fatalError("unknown protocol version must fail")
        } catch CleanupHelperResponse.DecodeError.incompatibleVersion {}
        print("PASS protocol: response, malformed JSON, incompatible version")
    }

    static func child() {
        let request = String(data: FileHandle.standardInput.readDataToEndOfFile(), encoding: .utf8) ?? ""
        switch request {
        case "large":
            let chunk = Data(repeating: 120, count: 256 * 1024)
            FileHandle.standardError.write(chunk)
            FileHandle.standardOutput.write(chunk)
        case "overflow":
            FileHandle.standardOutput.write(Data(repeating: 120, count: 256 * 1024))
        case "bad":
            FileHandle.standardOutput.write(Data("not json".utf8))
        case "exit": exit(7)
        default:
            if request.hasPrefix("hang:") {
                signal(SIGTERM, SIG_IGN)
                let path = String(request.dropFirst(5))
                try! String(getpid()).write(toFile: path, atomically: true, encoding: .utf8)
                Thread.sleep(forTimeInterval: 30)
            } else {
                FileHandle.standardOutput.write(Data("ok".utf8))
            }
        }
    }

    static func helper(_ request: String, timeout: TimeInterval = 5, limit: Int = 1024 * 1024) async throws -> Data {
        try await CleanupHelperTransport.run(
            executable: URL(fileURLWithPath: CommandLine.arguments[0]),
            request: Data(request.utf8), timeout: timeout, outputLimit: limit
        )
    }

    static func transportChecks() async throws {
        let normal = try await helper("normal")
        expect(normal == Data("ok".utf8), "normal output")
        let large = try await helper("large")
        expect(large.count == 256 * 1024, "drain stdout and stderr larger than pipe buffers")
        do {
            _ = try await helper("overflow", limit: 32 * 1024)
            fatalError("output limit must fail")
        } catch CleanupHelperTransportError.outputLimit {}
        do {
            _ = try await helper("exit")
            fatalError("nonzero exit must fail")
        } catch CleanupHelperTransportError.unsuccessfulExit {}
        do {
            _ = try await CleanupHelperTransport.run(executable: URL(fileURLWithPath: "/nonexistent-carrottype-test"), request: Data())
            fatalError("missing executable must fail")
        } catch {}

        do {
            _ = try await CleanupHelperTransport.run(executable: URL(fileURLWithPath: "/usr/bin/false"), request: Data(repeating: 120, count: 1024 * 1024))
            fatalError("early child exit must fail")
        } catch {}

        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("carrottype-ipc-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let timeoutPath = directory.appendingPathComponent("timeout.pid")
        let started = Date()
        do {
            _ = try await helper("hang:\(timeoutPath.path)", timeout: 1)
            fatalError("timeout must fail")
        } catch CleanupHelperTransportError.timedOut {}
        expect(Date().timeIntervalSince(started) < 4, "timeout must kill SIGTERM-ignoring child")
        checkExited(timeoutPath)

        let cancelPath = directory.appendingPathComponent("cancel.pid")
        let task = Task { try await helper("hang:\(cancelPath.path)") }
        // Wait for an actual child before testing cancellation; no clipboard/general UI involved.
        for _ in 0..<200 {
            if FileManager.default.fileExists(atPath: cancelPath.path) { break }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        expect(FileManager.default.fileExists(atPath: cancelPath.path), "child launched")
        task.cancel()
        do { _ = try await task.value; fatalError("cancel must fail") }
        catch is CancellationError {}
        checkExited(cancelPath)

        let beforeLaunch = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await helper("normal")
        }
        do { _ = try await beforeLaunch.value; fatalError("pre-cancel must fail") }
        catch is CancellationError {}
        print("PASS helper: concurrent drains, output limit, exit/start errors, timeout, cancellation, no orphan")
    }

    static func checkExited(_ pidFile: URL) {
        let pid = Int32(try! String(contentsOf: pidFile, encoding: .utf8))!
        errno = 0
        expect(kill(pid, 0) == -1 && errno == ESRCH, "child must have exited and been reaped")
    }

    static func main() async throws {
        if CommandLine.arguments.count == 1 { child(); return }
        clipboardChecks()
        try await selectionChecks()
        try await transportChecks()
        try protocolChecks()
    }
}
