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
    private var snapshotTasks: [String: Task<Void, Never>] = [:]
    @Published private(set) var legacySTTPackages: [LegacySTTPackage] = []

    init(
        catalog: ModelCatalogFile = BundledModelCatalog.load(),
        fileManager: FileManager = .default,
        modelsRoot: URL? = nil
    ) {
        self.catalog = catalog
        self.fileManager = fileManager
        self.selectedSTTPackageID = BundledModelCatalog.recommendedSTTID

        let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        self.modelsRoot = modelsRoot ?? support
            .appendingPathComponent("carrottype", isDirectory: true)
            .appendingPathComponent("models", isDirectory: true)

        try? fileManager.createDirectory(at: self.modelsRoot, withIntermediateDirectories: true)
        refreshStatusesFromDisk()
        restoreSelection()
        refreshLegacySTTPackages()
    }

    // MARK: - Compatibility / Settings API

    var lastErrorMessage: String? { lastError }

    var activeSTTID: String { selectedSTTPackageID }

    var sttPackages: [CatalogPackage] {
        catalog.packages.filter { $0.role == .stt && $0.id == BundledModelCatalog.parakeetUltraSTTID }
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
        CleanupMode.allCases.filter { ($0 != .smartPlus || cleanupMode == .smartPlus) && isCleanupPackageReady(for: $0) }
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

    /// Hugging Face hub cache bytes for catalog repos only (Storage → Download cache).
    @Published private(set) var downloadCacheBytes: Int64 = 0

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

    /// Matches `deleteUnusedPackages`: active STT, dictation formatting package, or any transform-binding model.
    func isActiveInstalledPackage(_ packageID: String) -> Bool {
        guard let package = package(id: packageID) else { return false }
        switch package.role {
        case .stt:
            return packageID == selectedSTTPackageID
        case .cleanup:
            if cleanupMode.requiredPackageID == packageID { return true }
            return TransformBindingsStore.referencedCleanupPackageIDs().contains(packageID)
        }
    }

    var selectedSTTPackage: CatalogPackage? {
        catalog.packages.first { $0.id == selectedSTTPackageID }
    }

    /// Active STT package advertises live-draft streaming (Parakeet v3 / Ultra).
    var selectedSTTSupportsStreaming: Bool {
        selectedSTTPackage?.supportsStreaming == true
    }

    var isSelectedSTTReady: Bool { activeSTTStatus.isReady }

    var isDownloadingAnything: Bool {
        statuses.values.contains { $0.isDownloading }
    }

    func package(id: String) -> CatalogPackage? {
        catalog.packages.first { $0.id == id }
    }

    func status(for packageID: String) -> PackageInstallStatus {
        if statuses[packageID]?.isReady == true { return .ready }
        if let package = package(id: packageID), !package.downloadable {
            return .unavailable(reason: "Runtime ещё не подключён")
        }
        return statuses[packageID] ?? .notDownloaded
    }

    func refreshStatusesFromDisk() {
        var next: [String: PackageInstallStatus] = [:]
        for package in catalog.packages {
            if isReadyOnDisk(package) { next[package.id] = .ready; continue }
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
        guard (mode != .smartPlus || cleanupMode == .smartPlus), isCleanupPackageReady(for: mode) else {
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
        case "parakeet-fluidaudio":
            downloadParakeetSnapshot(package)
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
                    packageDirectory: packageDirectory(for: package),
                    packageID: package.id
                )
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

    func refreshLegacySTTPackages() {
        legacySTTPackages = LegacySTTStorage.inventory(modelsRoot: modelsRoot, fileManager: fileManager)
    }

    func deleteLegacySTTPackage(_ id: String) {
        do {
            try LegacySTTStorage.remove(id: id, modelsRoot: modelsRoot, fileManager: fileManager)
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
        refreshLegacySTTPackages()
    }

    /// Recompute catalog-scoped HF hub cache size (call when opening Storage).
    func refreshDownloadCacheBytes() {
        downloadCacheBytes = catalogHubCacheDirectories().reduce(Int64(0)) { sum, url in
            sum + (Self.directorySizeNonisolated(at: url, fileManager: fileManager) ?? 0)
        }
    }

    /// Removes only `~/.cache/huggingface/hub/models--*` folders for catalog Hub repos (not Application Support packages).
    func clearDownloadCache() {
        for url in catalogHubCacheDirectories() where fileManager.fileExists(atPath: url.path) {
            do {
                try fileManager.removeItem(at: url)
            } catch {
                lastError = String(
                    format: L10n.t("error.delete_failed"),
                    url.lastPathComponent,
                    error.localizedDescription
                )
                refreshDownloadCacheBytes()
                return
            }
        }
        lastError = nil
        refreshDownloadCacheBytes()
    }

    func deleteUnusedPackages() {
        for package in catalog.packages where package.role == .stt && package.id != selectedSTTPackageID {
            if case .ready = status(for: package.id) {
                remove(packageID: package.id)
            }
        }
        for package in catalog.packages where package.role == .cleanup {
            let needed = isActiveInstalledPackage(package.id)
            if !needed, case .ready = status(for: package.id) {
                remove(packageID: package.id)
            }
        }
    }

    /// Ultra CoreML directory, available only after an explicit download/previous installation.
    func selectedSTTModelPath() -> String? {
        guard let package = selectedSTTPackage,
              package.downloadable,
              case .ready = statuses[package.id]
        else { return nil }

        switch package.runtimeHint {
        case "parakeet-fluidaudio":
            let cache = ParakeetSTTEngine.fluidCacheDirectory(
                modelsRoot: modelsRoot,
                packageID: package.id
            )
            return ParakeetSTTEngine.isPackageReady(
                modelsRoot: modelsRoot,
                packageDirectory: packageDirectory(for: package),
                packageID: package.id
            ) ? cache.path : nil
        default:
            return nil
        }
    }

    /// Directory with MLX weights for the active Smart/Smart+/Gemma mode, if ready.
    func cleanupModelDirectory() -> URL? {
        cleanupModelDirectory(for: cleanupMode)
    }

    /// Directory with MLX weights for an explicit cleanup mode, if ready.
    func cleanupModelDirectory(for mode: CleanupMode) -> URL? {
        guard let packageID = mode.requiredPackageID,
              let package = package(id: packageID),
              case .ready = statuses[packageID]
        else { return nil }
        let dir = packageDirectory(for: package)
        return QwenCleanupPackage.isPackageReady(at: dir, expectedRevision: package.hubRevision) ? dir : nil
    }

    func isCleanupPackageReady(for mode: CleanupMode) -> Bool {
        guard let packageID = mode.requiredPackageID else { return true }
        return status(for: packageID).isReady
    }

    // MARK: - Private

    private func downloadParakeetSnapshot(_ package: CatalogPackage) {
        let packageID = package.id
        let destination = packageDirectory(for: package)
        let root = modelsRoot
        snapshotTasks[packageID] = Task { [weak self] in
            do {
                try await ParakeetSTTEngine.downloadPackage(
                    modelsRoot: root,
                    packageDirectory: destination,
                    packageID: packageID
                ) { fraction in
                    Task { @MainActor in
                        self?.applyDownloadProgress(packageID: packageID, fraction: fraction)
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
        let expectedBytes = max(package.approximateBytes, 1)
        let pinnedRevision: String = {
            if let trimmed = package.hubRevision?.trimmingCharacters(in: .whitespacesAndNewlines),
               !trimmed.isEmpty {
                return trimmed
            }
            return "main"
        }()

        // Mirror Parakeet: report progress via Task { @MainActor … }.
        // Hub's Progress.fractionCompleted often stays 0 for large LFS snapshots, so we also
        // pump an on-disk estimate (Application Support + HF hub cache) the same way.
        snapshotTasks[packageID] = Task { [weak self] in
            let report: @Sendable (Double) -> Void = { fraction in
                Task { @MainActor in
                    self?.applyDownloadProgress(packageID: packageID, fraction: fraction)
                }
            }

            let progressPump = Task.detached {
                while !Task.isCancelled {
                    let estimated = ModelManager.estimateMLXProgress(
                        repoID: repoID,
                        destination: destination,
                        expectedBytes: expectedBytes
                    )
                    report(estimated)
                    try? await Task.sleep(nanoseconds: 200_000_000)
                }
            }
            defer { progressPump.cancel() }

            do {
                try await QwenCleanupPackage.downloadPackage(
                    repoID: repoID,
                    to: destination,
                    revision: pinnedRevision
                ) { fraction in
                    // Same hop as Parakeet; ignore broken Hub 0% samples.
                    if fraction > 0.01 {
                        report(fraction)
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

    /// On-disk MLX progress from package dir + Hugging Face hub cache (Parakeet-style reporting source).
    nonisolated private static func estimateMLXProgress(
        repoID: String,
        destination: URL,
        expectedBytes: Int64
    ) -> Double {
        let fm = FileManager.default
        let destBytes = directorySizeNonisolated(at: destination, fileManager: fm) ?? 0
        let hubBytes = hubCacheBytes(forRepoID: repoID)
        let bytes = max(destBytes, hubBytes)
        guard bytes > 0, expectedBytes > 0 else { return 0 }
        return min(0.99, Double(bytes) / Double(expectedBytes))
    }

    /// Bytes already present under `~/.cache/huggingface/hub/models--org--name` (HubClient default cache).
    nonisolated private static func hubCacheBytes(forRepoID repoID: String) -> Int64 {
        guard let dir = hubCacheDirectory(forRepoID: repoID) else { return 0 }
        return directorySizeNonisolated(at: dir, fileManager: .default) ?? 0
    }

    nonisolated private static func directorySizeNonisolated(at url: URL, fileManager: FileManager) -> Int64? {
        guard fileManager.fileExists(atPath: url.path),
              let enumerator = fileManager.enumerator(
                at: url,
                includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey, .isSymbolicLinkKey],
                options: [.skipsHiddenFiles]
              )
        else { return nil }
        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(
                forKeys: [.fileSizeKey, .isRegularFileKey, .isSymbolicLinkKey]
            ) else { continue }
            // Count regular files only — skip symlinks (HF snapshots → blobs) to avoid double count.
            if values.isSymbolicLink == true { continue }
            guard values.isRegularFile == true, let size = values.fileSize else { continue }
            total += Int64(size)
        }
        return total
    }

    /// Publish download progress on the main actor; skip near-duplicate fractions to limit churn.
    private func applyDownloadProgress(packageID: String, fraction: Double) {
        let clamped = Self.clampedFraction(fraction)
        if case .downloading(let current) = statuses[packageID], abs(current - clamped) < 0.005 {
            return
        }
        setStatus(packageID, .downloading(progress: clamped))
    }

    nonisolated private static func clampedFraction(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(max(value, 0), 1)
    }

    private func isReadyOnDisk(_ package: CatalogPackage) -> Bool {
        let dir = packageDirectory(for: package)
        switch package.runtimeHint {
        case "parakeet-fluidaudio":
            return ParakeetSTTEngine.isPackageReady(
                modelsRoot: modelsRoot,
                packageDirectory: dir,
                packageID: package.id
            )
        case "mlx-lm":
            return QwenCleanupPackage.isPackageReady(at: dir, expectedRevision: package.hubRevision)
        default:
            return false
        }
    }

    private func installedBytes(for package: CatalogPackage) -> Int64 {
        let dir = packageDirectory(for: package)
        var total = directorySize(at: dir) ?? 0
        if package.runtimeHint == "parakeet-fluidaudio" {
            let fluid = ParakeetSTTEngine.fluidCacheDirectory(
                modelsRoot: modelsRoot,
                packageID: package.id
            )
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
        if package.role == .cleanup {
            let fallback = firstReadyCleanupMode(excludingPackageID: package.id) ?? .smart
            TransformBindingsStore.remapCleanupMode(
                removingPackageID: package.id,
                fallback: fallback
            )
        }
    }

    private func firstReadyCleanupMode(excludingPackageID: String) -> CleanupMode? {
        for mode in [CleanupMode.smart, .gemma] {
            guard let id = mode.requiredPackageID, id != excludingPackageID else { continue }
            if isCleanupPackageReady(for: mode) { return mode }
        }
        return nil
    }

    private func packageDirectory(for package: CatalogPackage) -> URL {
        ModelPackageLayout.directory(modelsRoot: modelsRoot, packageID: package.id)
    }

    private func hubRepoID(from downloadURL: String) -> String? {
        guard let url = URL(string: downloadURL) else { return nil }
        let parts = url.path.split(separator: "/").map(String.init)
        guard parts.count >= 2 else { return nil }
        return "\(parts[0])/\(parts[1])"
    }

    /// Unique Hub cache directories for packages with catalog `hubRepoID` (Parakeet / MLX snapshots).
    private func catalogHubCacheDirectories() -> [URL] {
        var seen = Set<String>()
        var urls: [URL] = []
        let repos = catalog.packages.compactMap(\.hubRepoID) + ["FluidInference/parakeet-tdt-0.6b-v3-coreml"]
        for repoID in repos where !repoID.isEmpty && seen.insert(repoID).inserted {
            if let dir = Self.hubCacheDirectory(forRepoID: repoID) { urls.append(dir) }
        }
        return urls
    }

    /// Existing on-disk hub folder for a repo, if present under default HF cache roots.
    nonisolated private static func hubCacheDirectory(forRepoID repoID: String) -> URL? {
        let repoFolder = "models--" + repoID.replacingOccurrences(of: "/", with: "--")
        var roots: [URL] = [
            FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".cache/huggingface/hub", isDirectory: true),
        ]
        if let hfHome = ProcessInfo.processInfo.environment["HF_HOME"], !hfHome.isEmpty {
            roots.insert(
                URL(fileURLWithPath: hfHome, isDirectory: true)
                    .appendingPathComponent("hub", isDirectory: true),
                at: 0
            )
        }
        let fm = FileManager.default
        for root in roots {
            let dir = root.appendingPathComponent(repoFolder, isDirectory: true)
            if fm.fileExists(atPath: dir.path) {
                return dir
            }
        }
        return nil
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
        // The only dictation runtime is Ultra. No download is triggered by migrating this preference.
        selectedSTTPackageID = DictationModelPolicy.restoreSelection()
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
