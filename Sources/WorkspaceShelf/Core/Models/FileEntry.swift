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
            return "패키지"
        }
        if isDirectory {
            return "폴더"
        }
        let extensionName = url.pathExtension
        return extensionName.isEmpty ? "파일" : extensionName.uppercased()
    }
}

enum FileSortOption: String, CaseIterable, Codable, Sendable {
    case name
    case modificationDate
    case type
    case size

    var title: String {
        switch self {
        case .name: "이름"
        case .modificationDate: "수정일"
        case .type: "종류"
        case .size: "크기"
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
        case .list: "목록 보기"
        case .column: "컬럼 보기"
        case .grid: "아이콘 보기"
        }
    }
}

