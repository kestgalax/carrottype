import CryptoKit
import Foundation

@MainActor
final class ModelManager: ObservableObject {
    @Published private(set) var catalog: ModelCatalogFile
    @Published private(set) var statuses: [String: PackageInstallStatus] = [:]
    @Published var selectedSTTPackageID: String
    @Published var cleanupMode: CleanupMode = .light
    @Published var lastError: String?

    private let fileManager: FileManager
    private let modelsRoot: URL
    private var downloadTasks: [String: URLSessionDownloadTask] = [:]
    private var progressObservations: [String: NSKeyValueObservation] = [:]
    private var snapshotTasks: [String: Task<Void, Never>] = [:]
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        config.timeoutIntervalForResource = 60 * 60
        return URLSession(configuration: config)
    }()

    init(
        catalog: ModelCatalogFile = BundledModelCatalog.load(),
        fileManager: FileManager = .default
    ) {
        self.catalog = catalog
        self.fileManager = fileManager
        self.selectedSTTPackageID = BundledModelCatalog.recommendedSTTID

        let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        self.modelsRoot = support
            .appendingPathComponent("carrottype", isDirectory: true)
            .appendingPathComponent("models", isDirectory: true)

        try? fileManager.createDirectory(at: modelsRoot, withIntermediateDirectories: true)
        refreshStatusesFromDisk()
        restoreSelection()
    }

    // MARK: - Compatibility / Settings API

    var lastErrorMessage: String? { lastError }

    var activeSTTID: String { selectedSTTPackageID }

    var sttPackages: [CatalogPackage] {
        catalog.packages.filter { package in
            guard package.role == .stt else { return false }
            if package.runtimeHint == "apple-speechanalyzer" {
                return AppleSpeechSTTEngine.isPlatformSupported
            }
            return true
        }
    }

    /// STT packages that are on disk and can be selected as active.
    var selectableSTTPackages: [CatalogPackage] {
        sttPackages.filter { status(for: $0.id).isReady }
    }

    var cleanupPackages: [CatalogPackage] {
        catalog.packages.filter { $0.role == .cleanup }
    }

    /// Cleanup modes available for the active-mode picker (Off/Light always; Smart* when ready).
    var selectableCleanupModes: [CleanupMode] {
        CleanupMode.allCases.filter { isCleanupPackageReady(for: $0) }
    }

    var activeSTTStatus: PackageInstallStatus {
        status(for: selectedSTTPackageID)
    }

    var hasHardFailure: Bool {
        if case .failed = activeSTTStatus { return true }
        return false
    }

    var totalInstalledBytes: Int64 {
        catalog.packages.reduce(0) { sum, package in
            guard case .ready = status(for: package.id) else { return sum }
            return sum + installedBytes(for: package)
        }
    }

    /// Ready packages with non-zero on-disk size, largest first (Storage pane).
    var installedPackageFootprints: [InstalledPackageFootprint] {
        catalog.packages.compactMap { package in
            guard case .ready = status(for: package.id) else { return nil }
            let bytes = installedBytes(for: package)
            guard bytes > 0 else { return nil }
            return InstalledPackageFootprint(
                id: package.id,
                displayName: package.displayName,
                bytes: bytes
            )
        }
        .sorted { $0.bytes > $1.bytes }
    }

    /// Matches `deleteUnusedPackages`: active STT selection or required Smart/Smart+ package.
    func isActiveInstalledPackage(_ packageID: String) -> Bool {
        guard let package = package(id: packageID) else { return false }
        switch package.role {
        case .stt:
            return packageID == selectedSTTPackageID
        case .cleanup:
            return cleanupMode.requiredPackageID == packageID
        }
    }

    var selectedSTTPackage: CatalogPackage? {
        catalog.packages.first { $0.id == selectedSTTPackageID }
    }

    var isSelectedSTTReady: Bool { activeSTTStatus.isReady }

    var isDownloadingAnything: Bool {
        statuses.values.contains { $0.isDownloading }
    }

    func package(id: String) -> CatalogPackage? {
        catalog.packages.first { $0.id == id }
    }

    func status(for packageID: String) -> PackageInstallStatus {
        if let package = package(id: packageID), !package.downloadable {
            return .unavailable(reason: "Runtime ещё не подключён")
        }
        return statuses[packageID] ?? .notDownloaded
    }

    func refreshStatusesFromDisk() {
        var next: [String: PackageInstallStatus] = [:]
        for package in catalog.packages {
            if !package.downloadable {
                next[package.id] = .unavailable(reason: "Runtime ещё не подключён")
                continue
            }
            if case .downloading = statuses[package.id] {
                next[package.id] = statuses[package.id]!
                continue
            }
            next[package.id] = isReadyOnDisk(package) ? .ready : .notDownloaded
        }
        statuses = next
    }

    func selectSTT(_ packageID: String) {
        guard let package = package(id: packageID), package.role == .stt else { return }
        guard status(for: packageID).isReady else {
            lastError = String(
                format: L10n.t("error.select_stt_download_first"),
                package.displayName
            )
            return
        }
        selectedSTTPackageID = packageID
        UserDefaults.standard.set(packageID, forKey: Keys.selectedSTT)
        lastError = nil
    }

    func selectCleanup(_ mode: CleanupMode) {
        guard isCleanupPackageReady(for: mode) else {
            lastError = String(
                format: L10n.t("error.select_cleanup_download_first"),
                mode.title(locale: L10n.preferredLocale)
            )
            return
        }
        cleanupMode = mode
        persistCleanupMode()
        lastError = nil
    }

    func downloadRecommendedIfNeeded() {
        guard let recommended = catalog.packages.first(where: { $0.recommended && $0.downloadable })
            ?? catalog.packages.first(where: { $0.role == .stt && $0.downloadable })
        else { return }
        download(recommended.id)
    }

    func download(_ packageID: String) {
        download(packageID: packageID)
    }

    func download(packageID: String) {
        guard let package = package(id: packageID) else { return }
        guard package.downloadable else {
            lastError = String(
                format: L10n.t("error.package_not_downloadable"),
                package.displayName
            )
            return
        }
        if case .downloading = statuses[packageID] { return }
        if isReadyOnDisk(package) {
            setStatus(packageID, .ready)
            return
        }

        lastError = nil
        setStatus(packageID, .downloading(progress: 0))

        switch package.runtimeHint {
        case "whisper-cpp-ggml":
            downloadWhisperFile(package)
        case "parakeet-fluidaudio":
            downloadParakeetSnapshot(package)
        case "apple-speechanalyzer":
            prepareAppleSpeechAssets(package)
        case "mlx-lm":
            downloadMLXSnapshot(package)
        default:
            setStatus(
                packageID,
                .failed(message: String(format: L10n.t("error.unknown_runtime"), package.runtimeHint))
            )
        }
    }

    func cancelDownload(_ packageID: String) {
        cancelDownload(packageID: packageID)
    }

    func cancelDownload(packageID: String) {
        downloadTasks[packageID]?.cancel()
        downloadTasks[packageID] = nil
        progressObservations[packageID]?.invalidate()
        progressObservations[packageID] = nil
        snapshotTasks[packageID]?.cancel()
        snapshotTasks[packageID] = nil
        setStatus(packageID, .notDownloaded)
    }

    func deletePackage(_ packageID: String) {
        remove(packageID: packageID)
    }

    func remove(packageID: String) {
        cancelDownload(packageID: packageID)
        guard let package = package(id: packageID) else { return }
        do {
            if package.runtimeHint == "parakeet-fluidaudio" {
                try ParakeetSTTEngine.removeInstalled(
                    modelsRoot: modelsRoot,
                    packageDirectory: packageDirectory(for: package)
                )
            } else if package.runtimeHint == "apple-speechanalyzer" {
                let dir = packageDirectory(for: package)
                let locale = AppleSpeechSTTEngine.preferredAppLocale()
                snapshotTasks[packageID] = Task { [weak self] in
                    do {
                        try await AppleSpeechSTTEngine.removePrepared(packageDirectory: dir, locale: locale)
                        await MainActor.run {
                            guard let self else { return }
                            self.snapshotTasks[packageID] = nil
                            self.setStatus(packageID, .notDownloaded)
                            self.reconcileSelectionAfterRemoval(of: package)
                            self.lastError = nil
                        }
                    } catch {
                        await MainActor.run {
                            guard let self else { return }
                            self.snapshotTasks[packageID] = nil
                            self.lastError = String(
                                format: L10n.t("error.delete_failed"),
                                package.displayName,
                                error.localizedDescription
                            )
                            self.refreshStatusesFromDisk()
                        }
                    }
                }
                return
            } else {
                let dir = packageDirectory(for: package)
                if fileManager.fileExists(atPath: dir.path) {
                    try fileManager.removeItem(at: dir)
                }
            }
            setStatus(packageID, .notDownloaded)
            reconcileSelectionAfterRemoval(of: package)
            // Confirm gone on disk (catches partial deletes).
            if isReadyOnDisk(package) {
                lastError = String(
                    format: L10n.t("error.package_still_on_disk"),
                    package.displayName
                )
                setStatus(packageID, .ready)
            } else {
                lastError = nil
            }
        } catch {
            lastError = String(
                format: L10n.t("error.delete_failed"),
                package.displayName,
                error.localizedDescription
            )
            refreshStatusesFromDisk()
        }
    }

    func deleteUnusedPackages() {
        for package in catalog.packages where package.role == .stt && package.id != selectedSTTPackageID {
            if case .ready = status(for: package.id) {
                remove(packageID: package.id)
            }
        }
        for package in catalog.packages where package.role == .cleanup {
            let needed = cleanupMode.requiredPackageID == package.id
            if !needed, case .ready = status(for: package.id) {
                remove(packageID: package.id)
            }
        }
    }

    /// Path consumed by STT engines: ggml file for Whisper, package directory for Parakeet.
    func selectedSTTModelPath() -> String? {
        guard let package = selectedSTTPackage,
              package.downloadable,
              case .ready = statuses[package.id]
        else { return nil }

        switch package.runtimeHint {
        case "parakeet-fluidaudio":
            let cache = ParakeetSTTEngine.fluidCacheDirectory(modelsRoot: modelsRoot)
            return ParakeetSTTEngine.isPackageReady(
                modelsRoot: modelsRoot,
                packageDirectory: packageDirectory(for: package)
            ) ? cache.path : nil
        case "apple-speechanalyzer":
            // System assets; engine resolves locale itself.
            return nil
        default:
            guard let url = artifactURL(for: package),
                  fileManager.fileExists(atPath: url.path)
            else { return nil }
            return url.path
        }
    }

    /// Directory with MLX weights for the active Smart/Smart+ mode, if ready.
    func cleanupModelDirectory() -> URL? {
        guard let packageID = cleanupMode.requiredPackageID,
              let package = package(id: packageID),
              case .ready = statuses[packageID]
        else { return nil }
        let dir = packageDirectory(for: package)
        return QwenCleanupEngine.isPackageReady(at: dir) ? dir : nil
    }

    func isCleanupPackageReady(for mode: CleanupMode) -> Bool {
        guard let packageID = mode.requiredPackageID else { return true }
        return status(for: packageID).isReady
    }

    // MARK: - Private

    private func downloadWhisperFile(_ package: CatalogPackage) {
        let packageID = package.id
        guard let remoteURL = URL(string: package.downloadURL) else {
            setStatus(packageID, .failed(message: L10n.t("error.bad_url")))
            return
        }
        guard let destination = artifactURL(for: package) else {
            setStatus(packageID, .failed(message: L10n.t("error.missing_artifact")))
            return
        }

        var request = URLRequest(url: remoteURL)
        request.setValue("carrottype/0.1", forHTTPHeaderField: "User-Agent")

        let packageDir = destination.deletingLastPathComponent()
        let fileManager = self.fileManager

        let task = session.downloadTask(with: request) { [weak self] location, response, error in
            // URLSession deletes the temp file when this callback returns.
            // Persist it synchronously before any MainActor hop.
            var stagedURL: URL?
            var stageError: Error?

            if error == nil,
               let http = response as? HTTPURLResponse,
               (200...299).contains(http.statusCode),
               let location {
                do {
                    try fileManager.createDirectory(at: packageDir, withIntermediateDirectories: true)
                    let staging = packageDir.appendingPathComponent(
                        ".\(destination.lastPathComponent).download",
                        isDirectory: false
                    )
                    if fileManager.fileExists(atPath: staging.path) {
                        try fileManager.removeItem(at: staging)
                    }
                    try fileManager.moveItem(at: location, to: staging)
                    stagedURL = staging
                } catch {
                    stageError = error
                }
            }

            Task { @MainActor in
                guard let self else {
                    if let stagedURL {
                        try? fileManager.removeItem(at: stagedURL)
                    }
                    return
                }
                self.progressObservations[packageID]?.invalidate()
                self.progressObservations[packageID] = nil
                self.downloadTasks[packageID] = nil

                if let error {
                    let nsError = error as NSError
                    if nsError.code == NSURLErrorCancelled {
                        self.setStatus(packageID, .notDownloaded)
                        return
                    }
                    self.setStatus(packageID, .failed(message: error.localizedDescription))
                    self.lastError = error.localizedDescription
                    return
                }

                if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                    let message = "HTTP \(http.statusCode)"
                    self.setStatus(packageID, .failed(message: message))
                    self.lastError = message
                    return
                }

                if let stageError {
                    self.setStatus(packageID, .failed(message: stageError.localizedDescription))
                    self.lastError = stageError.localizedDescription
                    return
                }

                guard let stagedURL else {
                    self.setStatus(packageID, .failed(message: L10n.t("error.empty_download")))
                    return
                }

                do {
                    if self.fileManager.fileExists(atPath: destination.path) {
                        try self.fileManager.removeItem(at: destination)
                    }
                    try self.fileManager.moveItem(at: stagedURL, to: destination)
                    if let expected = package.sha256 {
                        let actual = try Self.sha256Hex(ofFileAt: destination)
                        guard actual.caseInsensitiveCompare(expected) == .orderedSame else {
                            try? self.fileManager.removeItem(at: destination)
                            let message = L10n.t("error.sha_mismatch")
                            self.setStatus(packageID, .failed(message: message))
                            self.lastError = message
                            return
                        }
                    }
                    self.setStatus(packageID, .ready)
                    if package.role == .stt {
                        self.selectSTT(package.id)
                    }
                } catch {
                    try? self.fileManager.removeItem(at: stagedURL)
                    self.setStatus(packageID, .failed(message: error.localizedDescription))
                    self.lastError = error.localizedDescription
                }
            }
        }

        progressObservations[packageID] = task.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
            Task { @MainActor in
                self?.setStatus(packageID, .downloading(progress: progress.fractionCompleted))
            }
        }

        downloadTasks[packageID] = task
        task.resume()
    }

    private func downloadParakeetSnapshot(_ package: CatalogPackage) {
        let packageID = package.id
        let destination = packageDirectory(for: package)
        let root = modelsRoot
        snapshotTasks[packageID] = Task { [weak self] in
            do {
                try await ParakeetSTTEngine.downloadPackage(
                    modelsRoot: root,
                    packageDirectory: destination
                ) { fraction in
                    Task { @MainActor in
                        guard let self, !Task.isCancelled else { return }
                        self.setStatus(packageID, .downloading(progress: fraction))
                    }
                }
                await MainActor.run {
                    guard let self, !Task.isCancelled else { return }
                    self.snapshotTasks[packageID] = nil
                    self.setStatus(packageID, .ready)
                    self.selectSTT(package.id)
                }
            } catch is CancellationError {
                await MainActor.run {
                    self?.snapshotTasks[packageID] = nil
                    self?.setStatus(packageID, .notDownloaded)
                }
            } catch {
                await MainActor.run {
                    self?.snapshotTasks[packageID] = nil
                    self?.setStatus(packageID, .failed(message: error.localizedDescription))
                    self?.lastError = error.localizedDescription
                }
            }
        }
    }

    private func prepareAppleSpeechAssets(_ package: CatalogPackage) {
        let packageID = package.id
        let destination = packageDirectory(for: package)
        let locale = AppleSpeechSTTEngine.preferredAppLocale()
        snapshotTasks[packageID] = Task { [weak self] in
            do {
                try await AppleSpeechSTTEngine.ensureAssets(
                    packageDirectory: destination,
                    locale: locale
                ) { fraction in
                    Task { @MainActor in
                        guard let self, !Task.isCancelled else { return }
                        self.setStatus(packageID, .downloading(progress: fraction))
                    }
                }
                await MainActor.run {
                    guard let self, !Task.isCancelled else { return }
                    self.snapshotTasks[packageID] = nil
                    self.setStatus(packageID, .ready)
                    self.selectSTT(package.id)
                }
            } catch is CancellationError {
                await MainActor.run {
                    self?.snapshotTasks[packageID] = nil
                    self?.setStatus(packageID, .notDownloaded)
                }
            } catch {
                let message = (error as? LocalizedError)?.errorDescription
                    ?? AppleSpeechPrepareError.from(
                        systemError: error,
                        languageCode: AppleSpeechSTTEngine.languageCode(for: locale)
                    ).errorDescription
                    ?? L10n.t("error.apple_speech_prepare_failed")
                await MainActor.run {
                    self?.snapshotTasks[packageID] = nil
                    self?.setStatus(packageID, .failed(message: message))
                    self?.lastError = message
                }
            }
        }
    }

    private func downloadMLXSnapshot(_ package: CatalogPackage) {
        let packageID = package.id
        let repoID = package.hubRepoID
            ?? hubRepoID(from: package.downloadURL)
            ?? ""
        guard !repoID.isEmpty else {
            setStatus(packageID, .failed(message: L10n.t("error.missing_hub_repo")))
            return
        }
        let destination = packageDirectory(for: package)
        snapshotTasks[packageID] = Task { [weak self] in
            do {
                try await QwenCleanupEngine.downloadPackage(repoID: repoID, to: destination) { fraction in
                    Task { @MainActor in
                        guard let self, !Task.isCancelled else { return }
                        self.setStatus(packageID, .downloading(progress: fraction))
                    }
                }
                await MainActor.run {
                    guard let self, !Task.isCancelled else { return }
                    self.snapshotTasks[packageID] = nil
                    self.setStatus(packageID, .ready)
                }
            } catch is CancellationError {
                await MainActor.run {
                    self?.snapshotTasks[packageID] = nil
                    self?.setStatus(packageID, .notDownloaded)
                }
            } catch {
                await MainActor.run {
                    self?.snapshotTasks[packageID] = nil
                    self?.setStatus(packageID, .failed(message: error.localizedDescription))
                    self?.lastError = error.localizedDescription
                }
            }
        }
    }

    private func isReadyOnDisk(_ package: CatalogPackage) -> Bool {
        let dir = packageDirectory(for: package)
        switch package.runtimeHint {
        case "parakeet-fluidaudio":
            return ParakeetSTTEngine.isPackageReady(modelsRoot: modelsRoot, packageDirectory: dir)
        case "apple-speechanalyzer":
            return AppleSpeechSTTEngine.isPackageReady(packageDirectory: dir)
        case "mlx-lm":
            return QwenCleanupEngine.isPackageReady(at: dir)
        default:
            guard let url = artifactURL(for: package),
                  fileManager.fileExists(atPath: url.path)
            else { return false }
            // Already-installed files without a catalog sha256 stay ready.
            // If sha256 is set and mismatches, treat as not ready (user can re-download).
            guard let expected = package.sha256 else { return true }
            guard let actual = try? Self.sha256Hex(ofFileAt: url) else { return false }
            return actual.caseInsensitiveCompare(expected) == .orderedSame
        }
    }

    private func installedBytes(for package: CatalogPackage) -> Int64 {
        let dir = packageDirectory(for: package)
        var total = directorySize(at: dir) ?? 0
        if package.runtimeHint == "parakeet-fluidaudio" {
            let fluid = ParakeetSTTEngine.fluidCacheDirectory(modelsRoot: modelsRoot)
            if fluid.path != dir.path {
                total += directorySize(at: fluid) ?? 0
            }
        }
        return total
    }

    private func reconcileSelectionAfterRemoval(of package: CatalogPackage) {
        if package.role == .stt, package.id == selectedSTTPackageID {
            if let fallback = selectableSTTPackages.first {
                selectSTT(fallback.id)
            }
            // If nothing else is ready, keep the saved id but readiness stays Almost.
        }
        if package.role == .cleanup, cleanupMode.requiredPackageID == package.id {
            cleanupMode = .light
            persistCleanupMode()
        }
    }

    /// Streaming SHA-256 of a file on disk (hex lowercase).
    nonisolated private static func sha256Hex(ofFileAt url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var hasher = SHA256()
        while autoreleasepool(invoking: {
            let chunk = handle.readData(ofLength: 1024 * 1024)
            if chunk.isEmpty { return false }
            hasher.update(data: chunk)
            return true
        }) {}
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    private func packageDirectory(for package: CatalogPackage) -> URL {
        ModelPackageLayout.directory(modelsRoot: modelsRoot, packageID: package.id)
    }

    private func artifactURL(for package: CatalogPackage) -> URL? {
        guard let name = package.artifactFileName, !name.isEmpty else { return nil }
        return packageDirectory(for: package).appendingPathComponent(name, isDirectory: false)
    }

    private func hubRepoID(from downloadURL: String) -> String? {
        guard let url = URL(string: downloadURL) else { return nil }
        let parts = url.path.split(separator: "/").map(String.init)
        guard parts.count >= 2 else { return nil }
        return "\(parts[0])/\(parts[1])"
    }

    private func directorySize(at url: URL) -> Int64? {
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return nil }
        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey]),
                  values.isRegularFile == true,
                  let size = values.fileSize
            else { continue }
            total += Int64(size)
        }
        return total
    }

    private func setStatus(_ packageID: String, _ status: PackageInstallStatus) {
        var next = statuses
        next[packageID] = status
        statuses = next
    }

    private func restoreSelection() {
        if let saved = UserDefaults.standard.string(forKey: Keys.selectedSTT),
           catalog.packages.contains(where: { $0.id == saved && $0.role == .stt }) {
            selectedSTTPackageID = saved
        } else if let recommended = catalog.packages.first(where: { $0.recommended && $0.role == .stt }) {
            selectedSTTPackageID = recommended.id
        }
        // Prefer a ready package when the saved selection is not on disk.
        if !status(for: selectedSTTPackageID).isReady,
           let ready = selectableSTTPackages.first {
            selectedSTTPackageID = ready.id
            UserDefaults.standard.set(ready.id, forKey: Keys.selectedSTT)
        }
        if let raw = UserDefaults.standard.string(forKey: Keys.cleanupMode),
           let mode = CleanupMode(rawValue: raw) {
            if isCleanupPackageReady(for: mode) {
                cleanupMode = mode
            } else {
                cleanupMode = .light
                persistCleanupMode()
            }
        }
    }

    func persistCleanupMode() {
        UserDefaults.standard.set(cleanupMode.rawValue, forKey: Keys.cleanupMode)
    }

    private enum Keys {
        static let selectedSTT = "carrottype.selectedSTT"
        static let cleanupMode = "carrottype.cleanupMode"
    }
}
