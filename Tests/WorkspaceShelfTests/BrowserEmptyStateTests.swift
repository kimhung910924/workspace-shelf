import Foundation
import XCTest
@testable import WorkspaceShelf

/// An empty listing has several possible reasons behind it and they overlap,
/// so the order they are checked in is the whole of the logic. Getting it
/// wrong is invisible in the common case and confusing in the rest: a search
/// that matched nothing used to show no message at all, leaving no way to
/// tell it apart from a search that had not run.
@MainActor
final class BrowserEmptyStateTests: XCTestCase {
    private func state(
        isLoading: Bool = false,
        entryCount: Int,
        matchCount: Int,
        searchQuery: String = ""
    ) -> FileBrowserView.BrowserEmptyState {
        FileBrowserView.emptyState(
            isLoading: isLoading,
            entryCount: entryCount,
            matchCount: matchCount,
            searchQuery: searchQuery
        )
    }

    func testAFolderWithVisibleItemsSaysNothing() {
        XCTAssertEqual(state(entryCount: 3, matchCount: 3), .none)
    }

    func testAnEmptyFolderSaysSo() {
        XCTAssertEqual(state(entryCount: 0, matchCount: 0), .folderIsEmpty)
    }

    func testASearchThatMatchedNothingSaysSoAndQuotesTheQuery() {
        XCTAssertEqual(
            state(entryCount: 12, matchCount: 0, searchQuery: "보고서"),
            .searchFoundNothing(query: "보고서")
        )
    }

    /// An empty folder is an empty folder whether or not something is typed
    /// in the search box — blaming the search there would be a lie.
    func testAnEmptyFolderWinsOverAnActiveSearch() {
        XCTAssertEqual(
            state(entryCount: 0, matchCount: 0, searchQuery: "보고서"),
            .folderIsEmpty
        )
    }

    /// The listing is only briefly empty while loading, and the spinner is
    /// already saying why.
    func testLoadingSaysNothingYet() {
        XCTAssertEqual(state(isLoading: true, entryCount: 0, matchCount: 0), .none)
        XCTAssertEqual(
            state(isLoading: true, entryCount: 12, matchCount: 0, searchQuery: "x"),
            .none
        )
    }

    func testTheQuotedQueryDropsSurroundingWhitespace() {
        XCTAssertEqual(
            state(entryCount: 5, matchCount: 0, searchQuery: "  보고서  "),
            .searchFoundNothing(query: "보고서")
        )
    }
}
