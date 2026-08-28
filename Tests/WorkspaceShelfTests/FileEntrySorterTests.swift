import Foundation
import XCTest
@testable import WorkspaceShelf

final class FileEntrySorterTests: XCTestCase {
    func testDirectoriesStayBeforeFilesAndNamesUseNaturalOrder() {
        let entries = [
            makeEntry(name: "file10.txt"),
            makeEntry(name: "Folder", isDirectory: true),
            makeEntry(name: "file2.txt")
        ]

        let sorted = FileEntrySorter.sort(entries, by: .name)

        XCTAssertEqual(sorted.map(\.name), ["Folder", "file2.txt", "file10.txt"])
    }

    func testDescendingSortKeepsDirectoriesFirst() {
        let entries = [
            makeEntry(name: "A.txt", size: 10),
            makeEntry(name: "Folder", isDirectory: true),
            makeEntry(name: "B.txt", size: 20)
        ]

        let sorted = FileEntrySorter.sort(entries, by: .size, ascending: false)

        XCTAssertEqual(sorted.first?.name, "Folder")
        XCTAssertEqual(sorted.dropFirst().map(\.name), ["B.txt", "A.txt"])
    }

    private func makeEntry(
        name: String,
        isDirectory: Bool = false,
        size: Int64? = nil
    ) -> FileEntry {
        FileEntry(
            url: URL(fileURLWithPath: "/tmp/\(name)"),
            name: name,
            isDirectory: isDirectory,
            isPackage: false,
            isSymbolicLink: false,
            modificationDate: nil,
            fileSize: size
        )
    }
}

