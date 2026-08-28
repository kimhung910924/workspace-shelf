import AppKit
import ObjectiveC
import OSLog
import SwiftUI

/// What an outbound drag offers the receiving app. Configurable because the
/// answer is a matter of taste: Finder's own convention is to move within a
/// volume, but a shelf is also used as a place to drag copies out of.
enum OutboundDragOperation: String, CaseIterable, Sendable {
    case move
    case copy

    var menuTitle: String {
        switch self {
        case .move: L10n.t("이동 (Finder와 동일)", "Move (same as Finder)")
        case .copy: L10n.t("복사 (원본 유지)", "Copy (keep original)")
        }
    }

    /// For places that already say what the setting is, such as a tooltip
    /// naming the current choice.
    var shortTitle: String {
        switch self {
        case .move: L10n.t("이동", "Move")
        case .copy: L10n.t("복사", "Copy")
        }
    }

    /// `.move` offers both and lets the receiver pick, which is what makes it
    /// behave like Finder: a same-volume Finder drop moves, a different volume
    /// copies, and an upload area — which only accepts a copy — still leaves
    /// the original alone. `.copy` offers nothing else, so nothing can move
    /// the original.
    var dragOperationMask: NSDragOperation {
        switch self {
        case .move: [.move, .copy]
        case .copy: .copy
        }
    }
}

private let outboundDragLog = Logger(
    subsystem: "com.workspaceshelf.app",
    category: "outbound-drag"
)

extension Notification.Name {
    /// Posted on the main thread when a drag that began inside the app ends,
    /// however it ends — dropped, cancelled, or let go over nothing.
    static let outboundDragSessionDidEnd = Notification.Name(
        "com.workspaceshelf.outboundDragSessionDidEnd"
    )
}

/// Widens what an outbound drag offers other applications, which SwiftUI
/// otherwise pins to `.copy` with no API to change it.
///
/// Two more direct routes were tried first and neither works:
///
/// - `NSTableView.setDraggingSourceOperationMask`, since a `List` is
///   table-backed. Nothing changed, and why was never established. The drag
///   does come from the table view itself — `SwiftUIOutlineListView` is the
///   source AppKit reports — so the guess at the time, that the row drag
///   belonged to something else, was wrong. More likely the configurator
///   never found the table, or ran before it existed.
/// - Running the drag by hand from the panel's event monitor. The session
///   started and then died silently: not one `NSDraggingSource` callback
///   fired, because a drag has to begin from inside the view's own mouse
///   tracking, not from a monitor that sees the event before it is dispatched.
///
/// What is left is to keep SwiftUI's drag — which works — and change only the
/// answer it gives when the receiver asks what is permitted. Every drag begins
/// with `NSView.beginDraggingSession(with:event:source:)`, so that is hooked
/// once at launch and the source wrapped in a proxy that answers that one
/// question itself and forwards everything else untouched.
///
/// The failure mode is safe: if a future macOS starts its drags some other
/// way, the hook simply never fires and drags stay copies.
@MainActor
enum OutboundDragMaskHook {
    /// Read when a drag asks what it may do. Set at launch. Only ever
    /// touched on the main actor, where every drag callback arrives.
    static var maskProvider: (@MainActor () -> NSDragOperation)?

    /// The real files behind the drag now beginning. The pasteboard cannot
    /// answer this later: reading it back at session end returns AppKit's
    /// staged copy of the file, not the original — recycling that copy is
    /// what made a "move" leave the original in place. `fileDragItemProvider`
    /// registers each original here as the drag starts, and the session's
    /// proxy takes the whole list the moment it is created.
    static var pendingDragOriginals: [URL] = []

    private static var isInstalled = false

    /// Proxies have to outlive the call that creates them — AppKit holds the
    /// drag source weakly — so each is kept here until its session ends.
    fileprivate static var liveProxies: [DragSourceProxy] = []

    static func install(maskProvider: @escaping @MainActor () -> NSDragOperation) {
        Self.maskProvider = maskProvider
        guard !isInstalled else { return }
        isInstalled = true

        guard
            let original = class_getInstanceMethod(
                NSView.self,
                #selector(NSView.beginDraggingSession(with:event:source:))
            ),
            let replacement = class_getInstanceMethod(
                NSView.self,
                #selector(NSView.workspaceShelf_beginDraggingSession(with:event:source:))
            )
        else {
            // Worth saying out loud: the drag keeps working, it just silently
            // goes back to always copying.
            outboundDragLog.error("drag hook not installed; outbound drags will copy")
            return
        }
        method_exchangeImplementations(original, replacement)
    }

    fileprivate static func retain(_ proxy: DragSourceProxy) {
        liveProxies.append(proxy)
    }

    fileprivate static func release(_ proxy: DragSourceProxy) {
        liveProxies.removeAll { $0 === proxy }
    }
}

extension NSView {
    @objc
    fileprivate func workspaceShelf_beginDraggingSession(
        with items: [NSDraggingItem],
        event: NSEvent,
        source: NSDraggingSource
    ) -> NSDraggingSession {
        // The calls below look recursive but the implementations are
        // swapped: they go to the original method.
        guard !(source is DragSourceProxy),
              let maskProvider = MainActor.assumeIsolated({ OutboundDragMaskHook.maskProvider })
        else {
            return workspaceShelf_beginDraggingSession(with: items, event: event, source: source)
        }

        let proxy = DragSourceProxy(
            wrapping: source,
            maskProvider: maskProvider,
            itemCount: items.count
        )
        MainActor.assumeIsolated { OutboundDragMaskHook.retain(proxy) }
        return workspaceShelf_beginDraggingSession(with: items, event: event, source: proxy)
    }
}

/// Stands in for the drag source SwiftUI supplied, answering the operation
/// mask question itself and forwarding every other message to the original.
private final class DragSourceProxy: NSObject, NSDraggingSource {
    private let wrapped: NSDraggingSource
    private let maskProvider: @MainActor () -> NSDragOperation

    /// The originals this drag carries, taken from the registry the drag
    /// providers filled moments before the session began. Held here because
    /// only the source app knows them — the pasteboard's answer is a staged
    /// copy.
    private let originals: [URL]

    /// The context of the last mask question, which is where the drop
    /// landed. Guards the source-side half of a move from running for a
    /// drop the app handled itself.
    private var lastContext: NSDraggingContext = .withinApplication

    init(
        wrapping wrapped: NSDraggingSource,
        maskProvider: @escaping @MainActor () -> NSDragOperation,
        itemCount: Int
    ) {
        self.wrapped = wrapped
        self.maskProvider = maskProvider
        self.originals = MainActor.assumeIsolated {
            // Only the newest entries can belong to this session; anything
            // older is leftover from a drag that never became a session,
            // and trashing it here would hit a file the user never dragged.
            let taken = Array(OutboundDragMaskHook.pendingDragOriginals.suffix(itemCount))
            OutboundDragMaskHook.pendingDragOriginals = []
            return taken
        }
    }

    func draggingSession(
        _ session: NSDraggingSession,
        sourceOperationMaskFor context: NSDraggingContext
    ) -> NSDragOperation {
        // Drags landing back inside the app keep whatever SwiftUI intended:
        // the sidebar and the column browser have their own drop handling.
        guard context == .outsideApplication else {
            lastContext = .withinApplication
            return wrapped.draggingSession(session, sourceOperationMaskFor: context)
        }
        lastContext = .outsideApplication
        return MainActor.assumeIsolated { maskProvider() }
    }

    func draggingSession(
        _ session: NSDraggingSession,
        endedAt screenPoint: NSPoint,
        operation: NSDragOperation
    ) {
        completeMoveIfNeeded(session: session, operation: operation)
        wrapped.draggingSession?(session, endedAt: screenPoint, operation: operation)
        MainActor.assumeIsolated {
            OutboundDragMaskHook.release(self)
        }
        // SwiftUI's onDrag gives the dragged view no way to hear that its
        // drag is over, so a view holding per-drag state (the sidebar dims
        // the row being reordered) has no reliable point to clear it — a
        // drag cancelled with Esc or dropped nowhere ends without any drop
        // callback at all. This is the one place every in-app drag's ending
        // passes through.
        NotificationCenter.default.post(name: .outboundDragSessionDidEnd, object: nil)
    }

    /// Finishes a move. `NSDragOperationMove` does not mean the receiver
    /// relocated the file — it means the receiver has taken its own copy and
    /// the *source* is the one that owes the removal. Finder can move a file
    /// in one step only because it is on both ends of the drag; an app
    /// dragging a file out has to delete the original itself, which is why
    /// the file stayed put even once the mask and the chosen operation were
    /// both right.
    ///
    /// The original goes to the Trash rather than being unlinked. The
    /// receiver's report is taken on trust — there is no way to confirm what
    /// it did with the file — so the one irreversible step in the drag is
    /// left recoverable.
    private func completeMoveIfNeeded(session: NSDraggingSession, operation: NSDragOperation) {
        guard operation.contains(.move) else { return }
        // A drop the app handled itself (onto the sidebar, or between
        // columns) has already done whatever moving there was to do.
        guard lastContext == .outsideApplication else { return }

        // The originals recorded at drag start, not the pasteboard's URLs:
        // reading the pasteboard back returns AppKit's staged copy of each
        // file, so recycling those left every original untouched. The
        // pasteboard is only a fallback for a drag that somehow carried
        // files without passing through fileDragItemProvider.
        let carried = originals.isEmpty
            ? (session.draggingPasteboard.readObjects(
                forClasses: [NSURL.self],
                options: [.urlReadingFileURLsOnly: true]
            ) as? [URL] ?? [])
            : originals
        // Anything already gone was moved by whoever received it.
        let remaining = carried.filter { FileManager.default.fileExists(atPath: $0.path) }
        guard !remaining.isEmpty else { return }

        NSWorkspace.shared.recycle(remaining) { _, error in
            if let error {
                // The receiver has the file and the original did not make it
                // to the Trash, so the move quietly finished as a copy.
                outboundDragLog.error(
                    "could not trash the original after a move: \(error.localizedDescription)"
                )
            }
        }
    }

    // Everything not implemented above belongs to the original source.
    override func forwardingTarget(for selector: Selector!) -> Any? {
        wrapped.responds(to: selector) == true ? wrapped : nil
    }

    override func responds(to selector: Selector!) -> Bool {
        super.responds(to: selector) || wrapped.responds(to: selector) == true
    }
}
