import Foundation
import UniformTypeIdentifiers
import XCTest
@testable import WorkspaceShelf

/// The types a drag advertises decide which drop target catches it, and the
/// sidebar has two nested ones: the sidebar itself registers a dropped folder,
/// while each workspace row reorders the list. A row cannot decline a drop and
/// leave it to the sidebar underneath — the innermost target wins whatever it
/// answers — so every drag the browser produces has to be resolvable to a URL
/// by both. That is why the row accepts `.fileURL` too.
@MainActor
final class DragPayloadTypeTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("DragPayloadTypeTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
        OutboundDragMaskHook.pendingDragOriginals = []
    }

    private func makeFolder(named name: String) throws -> URL {
        let url = directory.appendingPathComponent(name, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func makeFile(named name: String) throws -> URL {
        let url = directory.appendingPathComponent(name)
        try Data("hello".utf8).write(to: url)
        return url
    }

    func testAFolderDragCarriesAFileURLTheSidebarCanAccept() throws {
        let provider = fileDragItemProvider(for: try makeFolder(named: "prompts"))

        XCTAssertTrue(provider.registeredTypeIdentifiers.contains(UTType.fileURL.identifier))
        XCTAssertTrue(provider.canLoadObject(ofClass: URL.self))
    }

    /// Every drag out of the browser stays resolvable as a file URL, whatever
    /// else it also advertises, so a drop landing on a workspace row can still
    /// be turned back into the folder the user meant.
    func testEveryDragStaysResolvableAsAFileURL() throws {
        for url in [
            try makeFolder(named: "reports"),
            try makeFile(named: "notes.md"),
            try makeFile(named: "cover.png"),
            try makeFile(named: "Makefile")
        ] {
            let provider = fileDragItemProvider(for: url)
            XCTAssertTrue(
                provider.registeredTypeIdentifiers.contains(UTType.fileURL.identifier),
                "\(url.lastPathComponent) would arrive without a URL to register"
            )
        }
    }

    /// The reason the row has to accept file URLs at all: a Markdown file's
    /// drag conforms to `.text`, which is what the row listens for to reorder
    /// itself. Narrowing the row back to `.text` alone would make dropping a
    /// `.md` file onto it do nothing at all.
    func testAMarkdownDragMatchesTheRowsReorderType() throws {
        let provider = fileDragItemProvider(for: try makeFile(named: "notes.md"))
        let matchesText = provider.registeredTypeIdentifiers
            .compactMap(UTType.init)
            .contains { $0.conforms(to: .text) }

        XCTAssertTrue(matchesText)
    }

    /// The drag source finishes a move by trashing what it recorded here, so
    /// an empty registry would mean the pasteboard's staged copy gets trashed
    /// instead of the real file.
    func testTheDragRecordsItsOriginalForTheMoveToFinish() throws {
        OutboundDragMaskHook.pendingDragOriginals = []
        let folder = try makeFolder(named: "batches")

        _ = fileDragItemProvider(for: folder)

        XCTAssertEqual(OutboundDragMaskHook.pendingDragOriginals, [folder])
    }
}
