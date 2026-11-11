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

/// Same layout as `ModelManager.modelsRoot` (ADR-015 path jail).
func allowedModelsRoot() -> URL {
    let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
    return support
        .appendingPathComponent("carrottype", isDirectory: true)
        .appendingPathComponent("models", isDirectory: true)
}

/// True if `candidate` is the models root or a subdirectory (symlink-resolved, `/`-boundary safe).
func isAllowedModelDirectory(_ candidate: URL) -> Bool {
    let rootPath = allowedModelsRoot().resolvingSymlinksInPath().standardizedFileURL.path
    let candPath = candidate.resolvingSymlinksInPath().standardizedFileURL.path
    if candPath == rootPath { return true }
    let prefix = rootPath.hasSuffix("/") ? rootPath : rootPath + "/"
    return candPath.hasPrefix(prefix)
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
      request.purpose == "dictation" || request.purpose == "transform",
      !(request.purpose == "dictation" && request.instructions?.isEmpty == false),
      !(request.purpose == "transform" && (request.instructions?.isEmpty != false || request.dictationRules != nil)),
      (request.dictationRules?.customRules.count ?? 0) <= DictationRules.customLimit,
      (request.dictationRules?.removedWords.count ?? 0) <= 500,
      request.mode == "smart" || request.mode == "smartPlus" || request.mode == "gemma"
else {
    failInvalid()
}

let directory = URL(fileURLWithPath: request.modelDirectory, isDirectory: true)
guard isAllowedModelDirectory(directory) else {
    emit(.failure("modelPathRejected"))
    exit(0)
}
guard FileManager.default.fileExists(atPath: directory.appendingPathComponent("config.json").path) else {
    emit(.failure("modelMissing"))
    exit(0)
}

#if arch(arm64)
do {
    let text = try await QwenCleanupCore.cleanup(
        text: request.text,
        modelDirectory: directory,
        mode: request.mode,
        instructions: request.instructions,
        rules: request.dictationRules
    )
    emit(.success(text))
    exit(0)
} catch let failure as DictationModelFailure {
    emit(.failure(failure.rawValue))
    exit(0)
} catch {
    emit(.failure("generationFailed"))
    exit(0)
}
#else
emit(.failure("notAppleSilicon"))
exit(0)
#endif
