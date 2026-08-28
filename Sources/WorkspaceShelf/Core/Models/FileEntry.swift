import Foundation

struct FileEntry: Identifiable, Hashable, Sendable {
    let url: URL
    let name: String
    let isDirectory: Bool
    let isPackage: Bool
    let isSymbolicLink: Bool
    let modificationDate: Date?
    let fileSize: Int64?

    var id: URL { url }

    var canNavigate: Bool {
        isDirectory && !isPackage
    }

    var typeDescription: String {
        if isPackage {
            return L10n.t("패키지", "Package")
        }
        if isDirectory {
            return L10n.t("폴더", "Folder")
        }
        let extensionName = url.pathExtension
        return extensionName.isEmpty ? L10n.t("파일", "File") : extensionName.uppercased()
    }
}

enum FileSortOption: String, CaseIterable, Codable, Sendable {
    case name
    case modificationDate
    case type
    case size

    var title: String {
        switch self {
        case .name: L10n.t("이름", "Name")
        case .modificationDate: L10n.t("수정일", "Date Modified")
        case .type: L10n.t("종류", "Kind")
        case .size: L10n.t("크기", "Size")
        }
    }
}

enum DirectoryLoadResult: Sendable {
    case success([FileEntry])
    case failure(String)
}

/// One column of the Miller-column ("컬럼 보기") browser: the contents of a
/// single ancestor directory, plus which of its children leads toward the
/// directory currently open in the final column.
struct BrowserColumn: Identifiable, Sendable {
    let directoryURL: URL
    var entries: [FileEntry] = []
    var isLoading = true
    var errorMessage: String?
    var highlightedChildURL: URL?

    var id: URL { directoryURL }
}

enum BrowserViewMode: String, CaseIterable, Codable, Sendable {
    case list
    case column
    case grid

    var symbolName: String {
        switch self {
        case .list: "list.bullet"
        case .column: "rectangle.split.3x1"
        case .grid: "square.grid.2x2"
        }
    }

    var label: String {
        switch self {
        case .list: L10n.t("목록 보기", "List View")
        case .column: L10n.t("컬럼 보기", "Column View")
        case .grid: L10n.t("아이콘 보기", "Icon View")
        }
    }
}

