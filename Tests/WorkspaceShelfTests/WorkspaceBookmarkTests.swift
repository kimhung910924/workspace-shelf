import Foundation
import XCTest
@testable import WorkspaceShelf

/// Registered folders have to survive a rebuild.
///
/// They once did not: the bookmarks were security-scoped, and such a bookmark
/// can only be reopened by the app that wrote it, identified by its code
/// signature. This app is signed ad-hoc, so a rebuild makes it a different app
/// by that measure, and every registered folder came back as "isn't in the
/// correct format" — with the stored data perfectly intact underneath.
@MainActor
final class WorkspaceBookmarkTests: XCTestCase {
    private var directory: URL!
    private var store: WorkspaceStore!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("WorkspaceBookmarkTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        store = WorkspaceStore(baseDirectory: directory)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    func testARegisteredFolderResolvesBackToItself() throws {
        let record = try store.makeRecord(for: directory, name: "Test", sortOrder: 0)

        let resolved = try store.resolve(record)

        XCTAssertEqual(resolved.url, directory.standardizedFileURL)
        XCTAssertFalse(resolved.isStale)
    }

    /// The actual guard: a security-scoped bookmark is the one kind that
    /// stops resolving when the signature changes, and it can be told apart
    /// because only that kind resolves when security scope is asked for.
    func testTheStoredBookmarkIsNotSecurityScoped() throws {
        let record = try store.makeRecord(for: directory, name: "Test", sortOrder: 0)

        var isStale = false
        XCTAssertThrowsError(
            try URL(
                resolvingBookmarkData: record.bookmarkData,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            ),
            "the bookmark is security-scoped, so a rebuild will orphan it"
        )
    }

    /// Folders registered by earlier builds are still in the old format, and
    /// they have to keep opening — there is no migration step.
    func testABookmarkWrittenInTheOldScopedFormatStillResolves() throws {
        let legacyRecord = WorkspaceRecord(
            name: "Legacy",
            bookmarkData: try directory.bookmarkData(
                options: [.withSecurityScope],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            ),
            sortOrder: 0
        )

        let resolved = try store.resolve(legacyRecord)

        XCTAssertEqual(resolved.url, directory.standardizedFileURL)
    }

    func testRefreshingAFolderKeepsItResolvableAndUnscoped() throws {
        let record = try store.makeRecord(for: directory, name: "Test", sortOrder: 0)

        let refreshed = try store.refreshedRecord(record, url: directory)

        XCTAssertEqual(try store.resolve(refreshed).url, directory.standardizedFileURL)
        var isStale = false
        XCTAssertThrowsError(
            try URL(
                resolvingBookmarkData: refreshed.bookmarkData,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
        )
    }
}
