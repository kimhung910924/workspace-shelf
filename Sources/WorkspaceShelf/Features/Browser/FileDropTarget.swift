import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// The file URLs the drag now being dropped actually carries, read straight
/// off the drag pasteboard.
///
/// The item providers SwiftUI hands the drop callback are not enough on
/// their own: a drag out of the app's own browser carries a file promise
/// (`registerFileRepresentation` becomes an `NSFilePromiseProvider` on the
/// drag pasteboard), and the provider SwiftUI reconstructs for such a drag
/// cannot load a URL at all — `canLoadObject(ofClass: URL.self)` is false
/// even though the pasteboard itself still lists `public.file-url` with the
/// real path. SwiftUI's own targeting check reads the pasteboard types, so
/// the drop lights up and then hands over providers that resolve to
/// nothing. Reading the pasteboard directly gets the original URLs back.
///
/// Safe to call only from inside a drop callback, where the drag pasteboard
/// is guaranteed to belong to the drag being dropped.
@MainActor
func draggedFileURLs(from pasteboard: NSPasteboard = NSPasteboard(name: .drag)) -> [URL] {
    pasteboard.readObjects(
        forClasses: [NSURL.self],
        options: [.urlReadingFileURLsOnly: true]
    ) as? [URL] ?? []
}

/// Accepts files dragged in from Finder — or any other app — and puts them in
/// `destination`.
///
/// Holding Option while dropping copies instead of moving, which is Finder's
/// own convention for a drag within a volume. The default is a move so that
/// dragging a file in and dragging it back out are the same gesture in both
/// directions.
///
/// The panel takes these drops while another app is frontmost because it does
/// not hide on deactivation, so a drag from Finder lands on a pinned shelf
/// without the user having to click the shelf first.
private struct FileDropTarget: ViewModifier {
    let model: AppModel
    /// Nil while no folder is open, which is when there is nowhere to put a
    /// dropped file.
    let destination: URL?
    let highlight: DropHighlight

    @State private var isTargeted = false

    func body(content: Content) -> some View {
        content
            .background {
                if isTargeted, destination != nil {
                    highlightShape
                }
            }
            .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                guard let destination else { return false }
                return handleDrop(providers: providers, into: destination)
            }
    }

    @ViewBuilder
    private var highlightShape: some View {
        switch highlight {
        case .surface:
            Color.accentColor.opacity(0.1)
        case .row(let cornerRadius):
            // Stronger than the surface wash and outlined, because a row
            // has to say *which* folder is about to receive the files, not
            // merely that a drop is possible.
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.accentColor.opacity(0.22))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.accentColor.opacity(0.6), lineWidth: 1)
                }
        }
    }

    private func handleDrop(providers: [NSItemProvider], into destination: URL) -> Bool {
        // Read before the work goes async: by the time the URLs have loaded
        // the user has let go of the key.
        let copyRequested = NSEvent.modifierFlags.contains(.option)

        // Same reason as the sidebar: an in-app drag's providers cannot load
        // URLs, but the drag pasteboard has them.
        let pasteboardURLs = draggedFileURLs()
        if !pasteboardURLs.isEmpty {
            model.dropFiles(pasteboardURLs, into: destination, copy: copyRequested)
            return true
        }

        guard providers.contains(where: { $0.canLoadObject(ofClass: URL.self) }) else {
            return false
        }

        Task {
            var collected: [URL] = []
            for provider in providers {
                if let url = await loadURL(from: provider) {
                    collected.append(url)
                }
            }
            guard !collected.isEmpty else { return }
            model.dropFiles(collected, into: destination, copy: copyRequested)
        }
        return true
    }

    private func loadURL(from provider: NSItemProvider) async -> URL? {
        await withCheckedContinuation { continuation in
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                continuation.resume(returning: url)
            }
        }
    }
}

/// How a view about to receive a drop says so.
enum DropHighlight {
    /// A wash over a whole browsing area.
    case surface
    /// A single row or grid item, drawn to match its own selected look.
    case row(cornerRadius: CGFloat)
}

extension View {
    /// Makes this view a destination for files dragged in from other apps.
    func fileDropTarget(
        into destination: URL?,
        model: AppModel,
        highlight: DropHighlight = .surface
    ) -> some View {
        modifier(FileDropTarget(model: model, destination: destination, highlight: highlight))
    }

    /// Lets a folder row take a drop straight into that folder, the way
    /// Finder does.
    ///
    /// A row that is not a folder registers no drop target at all rather
    /// than one that refuses: the innermost registered view wins the drop
    /// whatever it then answers, so a refusing row would swallow the drop
    /// instead of letting it reach the folder being browsed underneath.
    @ViewBuilder
    func folderDropTarget(
        for entry: FileEntry,
        model: AppModel,
        cornerRadius: CGFloat
    ) -> some View {
        if entry.canNavigate {
            fileDropTarget(
                into: entry.url,
                model: model,
                highlight: .row(cornerRadius: cornerRadius)
            )
        } else {
            self
        }
    }
}
