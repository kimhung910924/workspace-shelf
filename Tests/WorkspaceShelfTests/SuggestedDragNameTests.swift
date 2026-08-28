import Foundation
import UniformTypeIdentifiers
import XCTest
@testable import WorkspaceShelf

/// The name a drag suggests is a base name, not a filename — a receiver that
/// takes the file representation appends the content type's own extension.
/// Getting this wrong is what put `기획서.md.md` on the Desktop.
final class SuggestedDragNameTests: XCTestCase {
    func testDropsTheExtensionTheContentTypeWillPutBack() {
        XCTAssertEqual(
            suggestedDragName(for: URL(fileURLWithPath: "/tmp/기획서.md"), contentType: .init("net.daringfireball.markdown")),
            "기획서"
        )
        XCTAssertEqual(
            suggestedDragName(for: URL(fileURLWithPath: "/tmp/photo.png"), contentType: .png),
            "photo"
        )
    }

    func testMatchIgnoresCase() {
        XCTAssertEqual(
            suggestedDragName(for: URL(fileURLWithPath: "/tmp/PHOTO.PNG"), contentType: .png),
            "PHOTO"
        )
    }

    /// Only the last extension belongs to the type, so the rest of the name
    /// has to survive.
    func testKeepsTheEarlierHalfOfADoubleExtension() {
        XCTAssertEqual(
            suggestedDragName(for: URL(fileURLWithPath: "/tmp/archive.tar.gz"), contentType: .gzip),
            "archive.tar"
        )
    }

    func testKeepsTheWholeNameWhenNothingWouldBeAppended() {
        // No extension to lose.
        XCTAssertEqual(
            suggestedDragName(for: URL(fileURLWithPath: "/tmp/Makefile"), contentType: .data),
            "Makefile"
        )
        // Type unknown, so there is no telling what a receiver would append.
        XCTAssertEqual(
            suggestedDragName(for: URL(fileURLWithPath: "/tmp/notes.md"), contentType: nil),
            "notes.md"
        )
    }

    /// A correct extension must not be traded for a guessed one: the type
    /// here prefers `.sh`, and stripping `.command` would rename the file.
    func testKeepsAnExtensionThatDisagreesWithTheType() {
        XCTAssertEqual(
            suggestedDragName(for: URL(fileURLWithPath: "/tmp/build.command"), contentType: .shellScript),
            "build.command"
        )
    }
}
