import Foundation
import XCTest
@testable import WorkspaceShelf

final class FileOperationServiceTests: XCTestCase {
    func testRejectsUnsafeNames() throws {
        XCTAssertThrowsError(try FileOperationService.validateName(""))
        XCTAssertThrowsError(try FileOperationService.validateName(".."))
        XCTAssertThrowsError(try FileOperationService.validateName("a/b"))
        XCTAssertEqual(try FileOperationService.validateName("  notes.md  "), "notes.md")
    }

    func testCreatesFolderAndDoesNotOverwriteExistingFolder() throws {
        try withTemporaryDirectory { directoryURL in
            XCTAssertEqual(
                FileOperationService.createFolder(named: "Drafts", in: directoryURL),
                .success
            )
            XCTAssertTrue(
                FileManager.default.fileExists(
                    atPath: directoryURL.appendingPathComponent("Drafts").path
                )
            )

            let duplicate = FileOperationService.createFolder(
                named: "Drafts",
                in: directoryURL
            )
            XCTAssertTrue(isFailure(duplicate))
        }
    }

    func testRenameRejectsExistingDestination() throws {
        try withTemporaryDirectory { directoryURL in
            let firstURL = directoryURL.appendingPathComponent("first.txt")
            let secondURL = directoryURL.appendingPathComponent("second.txt")
            try Data("one".utf8).write(to: firstURL)
            try Data("two".utf8).write(to: secondURL)

            let result = FileOperationService.rename(firstURL, to: "second.txt")

            XCTAssertTrue(isFailure(result))
            XCTAssertTrue(FileManager.default.fileExists(atPath: firstURL.path))
            XCTAssertTrue(FileManager.default.fileExists(atPath: secondURL.path))
        }
    }

    func testCopyCreatesNewNameWithoutOverwriting() throws {
        try withTemporaryDirectory { directoryURL in
            let sourceDirectory = directoryURL.appendingPathComponent("source", isDirectory: true)
            let destinationDirectory = directoryURL.appendingPathComponent("destination", isDirectory: true)
            try FileManager.default.createDirectory(at: sourceDirectory, withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)

            let sourceURL = sourceDirectory.appendingPathComponent("note.txt")
            let existingURL = destinationDirectory.appendingPathComponent("note.txt")
            try Data("source".utf8).write(to: sourceURL)
            try Data("existing".utf8).write(to: existingURL)

            XCTAssertTrue(
                FileOperationService.hasConflicts(
                    sourceURLs: [sourceURL],
                    destinationDirectoryURL: destinationDirectory
                )
            )
            XCTAssertEqual(
                FileOperationService.copy(
                    [sourceURL],
                    to: destinationDirectory,
                    renameConflicts: true
                ),
                .success
            )

            let copiedURL = destinationDirectory.appendingPathComponent("note copy.txt")
            XCTAssertEqual(try String(contentsOf: existingURL), "existing")
            XCTAssertEqual(try String(contentsOf: copiedURL), "source")
        }
    }

    /// Copy-then-paste without leaving the folder used to be a silent
    /// no-op. It duplicates, the way Finder does.
    func testCopyIntoOwnFolderDuplicates() throws {
        try withTemporaryDirectory { directoryURL in
            let sourceURL = directoryURL.appendingPathComponent("note.txt")
            try Data("source".utf8).write(to: sourceURL)

            XCTAssertFalse(
                FileOperationService.hasConflicts(
                    sourceURLs: [sourceURL],
                    destinationDirectoryURL: directoryURL
                )
            )
            XCTAssertEqual(
                FileOperationService.copy(
                    [sourceURL],
                    to: directoryURL,
                    renameConflicts: false
                ),
                .success
            )

            let duplicateURL = directoryURL.appendingPathComponent("note copy.txt")
            XCTAssertEqual(try String(contentsOf: sourceURL), "source")
            XCTAssertEqual(try String(contentsOf: duplicateURL), "source")

            // A second paste keeps counting up instead of failing.
            XCTAssertEqual(
                FileOperationService.copy(
                    [sourceURL],
                    to: directoryURL,
                    renameConflicts: false
                ),
                .success
            )
            XCTAssertTrue(
                FileManager.default.fileExists(
                    atPath: directoryURL.appendingPathComponent("note copy 2.txt").path
                )
            )
        }
    }

    private func withTemporaryDirectory(
        _ body: (URL) throws -> Void
    ) throws {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("WorkspaceShelfTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directoryURL) }
        try body(directoryURL)
    }

    private func isFailure(_ result: FileOperationResult) -> Bool {
        if case .failure = result { return true }
        return false
    }
}
