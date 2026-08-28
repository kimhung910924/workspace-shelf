import Foundation

struct WorkspaceRecord: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var name: String
    var bookmarkData: Data
    var iconName: String
    var colorName: String
    var sortOrder: Int
    var lastRelativePath: String?

    init(
        id: UUID = UUID(),
        name: String,
        bookmarkData: Data,
        iconName: String = "folder.fill",
        colorName: String = "blue",
        sortOrder: Int,
        lastRelativePath: String? = nil
    ) {
        self.id = id
        self.name = name
        self.bookmarkData = bookmarkData
        self.iconName = iconName
        self.colorName = colorName
        self.sortOrder = sortOrder
        self.lastRelativePath = lastRelativePath
    }
}

struct WorkspaceStoreDocument: Codable, Sendable {
    var version: Int
    var workspaces: [WorkspaceRecord]

    static let currentVersion = 1
}

struct ResolvedWorkspace: Identifiable {
    var record: WorkspaceRecord
    var url: URL?
    var isAccessingSecurityScopedResource: Bool
    var errorDescription: String?

    var id: UUID { record.id }
}

