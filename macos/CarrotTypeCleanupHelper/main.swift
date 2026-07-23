import Foundation

/// CLI entry: one JSON request on stdin → one JSON response on stdout → exit (ADR-009).

func emit(_ response: CleanupHelperResponse) {
    let encoder = JSONEncoder()
    guard let data = try? encoder.encode(response) else {
        FileHandle.standardOutput.write(
            Data(#"{"v":1,"ok":false,"error":"invalidRequest"}"#.utf8)
        )
        return
    }
    FileHandle.standardOutput.write(data)
    FileHandle.standardOutput.write(Data("\n".utf8))
}

func failInvalid() -> Never {
    emit(.failure("invalidRequest"))
    exit(2)
}

let data = FileHandle.standardInput.readDataToEndOfFile()
guard !data.isEmpty else { failInvalid() }

let request: CleanupHelperRequest
do {
    request = try JSONDecoder().decode(CleanupHelperRequest.self, from: data)
} catch {
    failInvalid()
}

guard request.v == CleanupHelperProtocol.version,
      request.mode == "smart" || request.mode == "smartPlus"
else {
    failInvalid()
}

let directory = URL(fileURLWithPath: request.modelDirectory, isDirectory: true)
guard FileManager.default.fileExists(atPath: directory.appendingPathComponent("config.json").path) else {
    emit(.failure("modelMissing"))
    exit(0)
}

#if arch(arm64)
do {
    let text = try await QwenCleanupCore.cleanup(text: request.text, modelDirectory: directory)
    emit(.success(text))
    exit(0)
} catch QwenCleanupCore.CoreError.generationFailed {
    emit(.failure("generationFailed"))
    exit(0)
} catch {
    emit(.failure("generationFailed"))
    exit(0)
}
#else
emit(.failure("notAppleSilicon"))
exit(0)
#endif
