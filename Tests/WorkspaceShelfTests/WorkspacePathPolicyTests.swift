import Foundation
import XCTest
@testable import WorkspaceShelf

final class WorkspacePathPolicyTests: XCTestCase {
    func testRootAndDescendantAreContained() {
        let root = URL(fileURLWithPath: "/tmp/workspace-shelf-root", isDirectory: true)
        let descendant = root
            .appendingPathComponent("Folder", isDirectory: true)
            .appendingPathComponent("file.txt")

        XCTAssertTrue(WorkspacePathPolicy.contains(root, within: root))
        XCTAssertTrue(WorkspacePathPolicy.contains(descendant, within: root))
        XCTAssertEqual(
            WorkspacePathPolicy.relativePath(from: root, to: descendant),
            "Folder/file.txt"
        )
    }

    func testSiblingWithSamePrefixIsNotContained() {
        let root = URL(fileURLWithPath: "/tmp/workspace", isDirectory: true)
        let sibling = URL(fileURLWithPath: "/tmp/workspace-copy/file.txt")

        XCTAssertFalse(WorkspacePathPolicy.contains(sibling, within: root))
        XCTAssertNil(WorkspacePathPolicy.relativePath(from: root, to: sibling))
    }
}

