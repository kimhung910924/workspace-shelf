import Foundation
import XCTest
@testable import WorkspaceShelf

@MainActor
final class WorkspaceStoreTests: XCTestCase {
    func testSaveAndLoadPreservesRecordsAndNormalizesOrder() throws {
        let baseDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("WorkspaceShelfTests-\(UUID().uuidString)", isDirectory: true)
        defer {
            try? FileManager.default.removeItem(at: baseDirectory)
        }

        let store = WorkspaceStore(baseDirectory: baseDirectory)
        let records = [
            WorkspaceRecord(
                name: "Novel",
                bookmarkData: Data([1, 2, 3]),
                sortOrder: 8
            ),
            WorkspaceRecord(
                name: "Omni",
                bookmarkData: Data([4, 5, 6]),
                sortOrder: 2
            )
        ]

        try store.save(records)
        let loaded = try store.load()

        XCTAssertEqual(loaded.map(\.name), ["Novel", "Omni"])
        XCTAssertEqual(loaded.map(\.sortOrder), [0, 1])
        XCTAssertEqual(loaded.map(\.bookmarkData), [Data([1, 2, 3]), Data([4, 5, 6])])
    }

    func testMissingStoreLoadsAsEmpty() throws {
        let baseDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("WorkspaceShelfTests-\(UUID().uuidString)", isDirectory: true)
        let store = WorkspaceStore(baseDirectory: baseDirectory)

        XCTAssertEqual(try store.load(), [])
    }
}

