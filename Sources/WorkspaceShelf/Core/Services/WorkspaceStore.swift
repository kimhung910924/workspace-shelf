import Foundation

@MainActor
final class WorkspaceStore {
    enum StoreError: LocalizedError {
        case unsupportedVersion(Int)

        var errorDescription: String? {
            switch self {
            case .unsupportedVersion(let version):
                L10n.t("지원하지 않는 Workspace 저장 형식입니다: \(version)", "Unsupported Workspace storage format: \(version)")
            }
        }
    }

    let fileURL: URL

    init(baseDirectory: URL? = nil) {
        let fileManager = FileManager.default
        let rootDirectory: URL

        if let baseDirectory {
            rootDirectory = baseDirectory
        } else {
            let applicationSupport = fileManager.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first!
            rootDirectory = applicationSupport.appendingPathComponent(
                "WorkspaceShelf",
                isDirectory: true
            )
        }

        fileURL = rootDirectory.appendingPathComponent("workspaces.json")
    }

    func load() throws -> [WorkspaceRecord] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)
        let document = try JSONDecoder().decode(WorkspaceStoreDocument.self, from: data)
        guard document.version == WorkspaceStoreDocument.currentVersion else {
            throw StoreError.unsupportedVersion(document.version)
        }
        return document.workspaces.sorted { $0.sortOrder < $1.sortOrder }
    }

    func save(_ records: [WorkspaceRecord]) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        let normalized = records.enumerated().map { index, record in
            var copy = record
            copy.sortOrder = index
            return copy
        }
        let document = WorkspaceStoreDocument(
            version: WorkspaceStoreDocument.currentVersion,
            workspaces: normalized
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(document)
        try data.write(to: fileURL, options: .atomic)
    }

    /// Plain bookmarks, deliberately not security-scoped.
    ///
    /// A security-scoped bookmark can only be resolved by the app that
    /// created it, identified by its code signature. This app is signed
    /// ad-hoc, so every rebuild is a different app as far as that check is
    /// concerned, and one rebuild was enough to make every registered folder
    /// fail to reopen with "isn't in the correct format" — the stored data
    /// was fine, it had simply stopped belonging to us.
    ///
    /// The scoping bought nothing to begin with: it exists so a sandboxed
    /// app can reach outside its container, and this app is not sandboxed.
    /// Plain bookmarks resolve no matter who is asking, which is also why
    /// folders registered by earlier builds come back without any migration.
    func makeRecord(for url: URL, name: String, sortOrder: Int) throws -> WorkspaceRecord {
        let bookmarkData = try url.bookmarkData(
            options: [],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        return WorkspaceRecord(
            name: name,
            bookmarkData: bookmarkData,
            sortOrder: sortOrder
        )
    }

    func resolve(_ record: WorkspaceRecord) throws -> (url: URL, isStale: Bool) {
        var isStale = false
        let url = try URL(
            resolvingBookmarkData: record.bookmarkData,
            options: [],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
        return (url.standardizedFileURL, isStale)
    }

    func refreshedRecord(_ record: WorkspaceRecord, url: URL) throws -> WorkspaceRecord {
        var copy = record
        copy.bookmarkData = try url.bookmarkData(
            options: [],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        return copy
    }
}

