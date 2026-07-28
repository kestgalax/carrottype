import Foundation

enum ModelRole: String, Codable, CaseIterable {
    case stt
    case cleanup
}

enum PackageInstallStatus: Equatable {
    case notDownloaded
    case downloading(progress: Double)
    case ready
    case failed(message: String)
    case unavailable(reason: String)

    var downloadProgress: Double? {
        if case .downloading(let progress) = self { return progress }
        return nil
    }

    var isDownloading: Bool {
        if case .downloading = self { return true }
        return false
    }

    var isReady: Bool {
        if case .ready = self { return true }
        return false
    }
}

/// On-disk footprint for a Ready catalog package (Storage breakdown).
struct InstalledPackageFootprint: Identifiable, Equatable {
    let id: String
    let displayName: String
    let bytes: Int64
}

enum CleanupMode: String, CaseIterable, Identifiable, Hashable {
    case off
    case light
    case smart
    case smartPlus
    case gemma

    var id: String { rawValue }

    var title: String {
        title(locale: Locale.autoupdatingCurrent)
    }

    func title(locale: Locale) -> String {
        switch self {
        case .off: return L10n.t("cleanup.mode.off", locale: locale)
        case .light: return L10n.t("cleanup.mode.light", locale: locale)
        case .smart: return L10n.t("cleanup.mode.smart", locale: locale)
        case .smartPlus: return L10n.t("cleanup.mode.smart_plus", locale: locale)
        case .gemma: return L10n.t("cleanup.mode.gemma", locale: locale)
        }
    }

    var requiredPackageID: String? {
        switch self {
        case .off, .light: return nil
        case .smart: return "cleanup.qwen3-0.6b-4bit"
        case .smartPlus: return "cleanup.qwen3-1.7b-4bit"
        case .gemma: return BundledModelCatalog.gemmaCleanupID
        }
    }

    /// MLX helper modes (Qwen Smart/Smart+ and optional Gemma).
    var usesMLXHelper: Bool {
        switch self {
        case .smart, .smartPlus, .gemma: return true
        case .off, .light: return false
        }
    }
}

enum Readiness: Equatable {
    case ready
    case almost
    case blocked

    var title: String {
        title(locale: Locale.autoupdatingCurrent)
    }

    func title(locale: Locale) -> String {
        switch self {
        case .ready: return L10n.t("readiness.ready", locale: locale)
        case .almost: return L10n.t("readiness.almost", locale: locale)
        case .blocked: return L10n.t("readiness.blocked", locale: locale)
        }
    }

    static func evaluate(
        microphoneGranted: Bool,
        accessibilityGranted: Bool,
        sttReady: Bool,
        hasHardFailure: Bool
    ) -> Readiness {
        if hasHardFailure {
            return .blocked
        }
        if microphoneGranted && accessibilityGranted && sttReady {
            return .ready
        }
        return .almost
    }
}

struct CatalogPackage: Codable, Identifiable, Hashable {
    let id: String
    let role: ModelRole
    let displayName: String
    let approximateBytes: Int64
    let languagesBlurb: String
    let license: String
    let recommended: Bool
    let downloadURL: String
    let runtimeHint: String
    /// Filename stored under Application Support after download (e.g. ggml-base.bin).
    let artifactFileName: String?
    /// Hugging Face repo id for snapshot downloads (MLX / FluidAudio packages).
    let hubRepoID: String?
    /// If false, package is listed but cannot be downloaded/run yet.
    let downloadable: Bool
    /// Optional SHA-256 (hex) for single-file ggml downloads.
    let sha256: String?

    var approximateSizeLabel: String {
        ByteCountFormatter.string(fromByteCount: approximateBytes, countStyle: .file)
    }

    /// `languagesBlurb` stores an L10n key (`catalog.blurb…`) or legacy plain text.
    func localizedBlurb(locale: Locale) -> String {
        if languagesBlurb.hasPrefix("catalog.blurb.") {
            return L10n.t(languagesBlurb, locale: locale)
        }
        return languagesBlurb
    }

    enum CodingKeys: String, CodingKey {
        case id, role, displayName, approximateBytes, languagesBlurb, license
        case recommended, downloadURL, runtimeHint, artifactFileName, hubRepoID, downloadable, sha256
    }

    init(
        id: String,
        role: ModelRole,
        displayName: String,
        approximateBytes: Int64,
        languagesBlurb: String,
        license: String,
        recommended: Bool,
        downloadURL: String,
        runtimeHint: String,
        artifactFileName: String? = nil,
        hubRepoID: String? = nil,
        downloadable: Bool = true,
        sha256: String? = nil
    ) {
        self.id = id
        self.role = role
        self.displayName = displayName
        self.approximateBytes = approximateBytes
        self.languagesBlurb = languagesBlurb
        self.license = license
        self.recommended = recommended
        self.downloadURL = downloadURL
        self.runtimeHint = runtimeHint
        self.artifactFileName = artifactFileName
        self.hubRepoID = hubRepoID
        self.downloadable = downloadable
        self.sha256 = sha256
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        role = try container.decode(ModelRole.self, forKey: .role)
        displayName = try container.decode(String.self, forKey: .displayName)
        approximateBytes = try container.decode(Int64.self, forKey: .approximateBytes)
        languagesBlurb = try container.decode(String.self, forKey: .languagesBlurb)
        license = try container.decode(String.self, forKey: .license)
        recommended = try container.decode(Bool.self, forKey: .recommended)
        downloadURL = try container.decode(String.self, forKey: .downloadURL)
        runtimeHint = try container.decode(String.self, forKey: .runtimeHint)
        artifactFileName = try container.decodeIfPresent(String.self, forKey: .artifactFileName)
        hubRepoID = try container.decodeIfPresent(String.self, forKey: .hubRepoID)
        downloadable = try container.decodeIfPresent(Bool.self, forKey: .downloadable) ?? true
        sha256 = try container.decodeIfPresent(String.self, forKey: .sha256)
    }
}

struct ModelCatalogFile: Codable {
    let version: Int
    let packages: [CatalogPackage]
}
