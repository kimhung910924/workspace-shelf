import AppKit
import Foundation
import UniformTypeIdentifiers
import XCTest
@testable import WorkspaceShelf

/// The sidebar and the browser's drop targets read the drag pasteboard
/// because the providers SwiftUI hands them for an in-app drag cannot load
/// URLs: the browser's drags carry a file promise, and the reconstructed
/// provider for a promise-flavored drag reports
/// `canLoadObject(ofClass: URL.self) == false` even though the pasteboard
/// still lists `public.file-url` with the real path. These tests pin the
/// pasteboard reading that recovers from that.
@MainActor
final class DraggedFileURLsTests: XCTestCase {
    private var pasteboard: NSPasteboard!

    override func setUp() {
        pasteboard = NSPasteboard(name: NSPasteboard.Name("DraggedFileURLsTests-\(UUID().uuidString)"))
        pasteboard.clearContents()
    }

    override func tearDown() {
        pasteboard.releaseGlobally()
    }

    /// A pasteboard item shaped like a real drag out of the browser: file
    /// promise metadata alongside a plain `public.file-url`.
    func testReadsURLsFromAFilePromiseFlavoredDrag() {
        let url = URL(fileURLWithPath: "/Users/someone/Desktop/game", isDirectory: true)

        let item = NSPasteboardItem()
        item.setString("game", forType: NSPasteboard.PasteboardType("com.apple.pasteboard.promised-suggested-file-name"))
        item.setString(UTType.folder.identifier, forType: NSPasteboard.PasteboardType("com.apple.pasteboard.promised-file-content-type"))
        item.setData(Data(url.absoluteString.utf8), forType: .fileURL)
        pasteboard.writeObjects([item])

        XCTAssertEqual(draggedFileURLs(from: pasteboard), [url])
    }

    func testReadsEveryURLOfAMultiItemDrag() {
        let urls = [
            URL(fileURLWithPath: "/Users/someone/Desktop/a", isDirectory: true),
            URL(fileURLWithPath: "/Users/someone/Desktop/b.md")
        ]
        let items = urls.map { url in
            let item = NSPasteboardItem()
            item.setData(Data(url.absoluteString.utf8), forType: .fileURL)
            return item
        }
        pasteboard.writeObjects(items)

        XCTAssertEqual(draggedFileURLs(from: pasteboard), urls)
    }

    /// A reorder drag (or anything else without file URLs) must read as
    /// empty so the drop handlers fall through to their provider path
    /// instead of claiming the drop.
    func testADragWithoutFileURLsReadsAsEmpty() {
        let item = NSPasteboardItem()
        item.setString(UUID().uuidString, forType: .string)
        pasteboard.writeObjects([item])

        XCTAssertEqual(draggedFileURLs(from: pasteboard), [])
    }
}
