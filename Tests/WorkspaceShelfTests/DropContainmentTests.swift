import Foundation
import XCTest
@testable import WorkspaceShelf

/// Guards the one drop that can never work — putting a folder inside itself
/// — and, just as importantly, guards against that check being so eager it
/// rejects a perfectly good sibling folder.
@MainActor
final class DropContainmentTests: XCTestCase {
    private func url(_ path: String) -> URL {
        URL(fileURLWithPath: path)
    }

    func testRejectsAFolderDroppedOnItself() {
        XCTAssertTrue(
            AppModel.isSelfOrDescendant(url("/Users/me/Notes"), of: url("/Users/me/Notes"))
        )
    }

    func testRejectsAFolderDroppedInsideItself() {
        XCTAssertTrue(
            AppModel.isSelfOrDescendant(url("/Users/me/Notes/2026"), of: url("/Users/me/Notes"))
        )
    }

    /// The reason this compares path components instead of string prefixes:
    /// `/Users/me/Notebook` starts with the text `/Users/me/Notes` but is a
    /// different folder entirely, and dropping into it must be allowed.
    func testAllowsASiblingWhoseNameSharesAPrefix() {
        XCTAssertFalse(
            AppModel.isSelfOrDescendant(url("/Users/me/Notebook"), of: url("/Users/me/Notes"))
        )
    }

    func testAllowsAnUnrelatedFolder() {
        XCTAssertFalse(
            AppModel.isSelfOrDescendant(url("/Users/me/Desktop"), of: url("/Users/me/Notes"))
        )
    }

    /// A drop *upward* — moving a nested folder out to its ancestor — is an
    /// ordinary move and must not be caught.
    func testAllowsMovingAFolderUpToItsAncestor() {
        XCTAssertFalse(
            AppModel.isSelfOrDescendant(url("/Users/me"), of: url("/Users/me/Notes/2026"))
        )
    }

    func testIgnoresTrailingSlashesAndRelativeSegments() {
        XCTAssertTrue(
            AppModel.isSelfOrDescendant(url("/Users/me/Notes/"), of: url("/Users/me/Notes"))
        )
        XCTAssertTrue(
            AppModel.isSelfOrDescendant(url("/Users/me/Photos/../Notes/2026"), of: url("/Users/me/Notes"))
        )
    }

    /// Dropping an item into the folder it already lives in means nothing as
    /// a move — but with Option held it is Finder's duplicate gesture, and
    /// discarding it there made the drop look silently broken, exactly the
    /// judgment already made for paste-in-place.
    func testAnItemDroppedWhereItAlreadyLivesIsAMoveNoOpButACopyDuplicate() {
        let sources = [url("/Users/me/Notes/a.md")]
        let destination = url("/Users/me/Notes")

        XCTAssertEqual(
            AppModel.dropSources(from: sources, into: destination, copy: false),
            []
        )
        XCTAssertEqual(
            AppModel.dropSources(from: sources, into: destination, copy: true),
            sources
        )
    }

    /// The impossible drop stays discarded whichever key is held.
    func testAFolderDroppedIntoItselfIsDiscardedEvenAsACopy() {
        let folder = url("/Users/me/Notes")

        XCTAssertEqual(AppModel.dropSources(from: [folder], into: folder, copy: true), [])
        XCTAssertEqual(
            AppModel.dropSources(from: [folder], into: url("/Users/me/Notes/2026"), copy: true),
            []
        )
    }

    func testAMixedBatchKeepsOnlyTheActionableItems() {
        let destination = url("/Users/me/Notes")
        let kept = url("/Users/me/Desktop/b.md")

        XCTAssertEqual(
            AppModel.dropSources(
                from: [url("/Users/me/Notes/a.md"), kept, url("/Users/me/Notes")],
                into: destination,
                copy: false
            ),
            [kept]
        )
    }
}
