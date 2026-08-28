import AppKit
import QuartzCore
import SwiftUI

@MainActor
final class ShelfPanelController {
    private enum DefaultsKey {
        static let panelWidth = "panel.width"
        static let panelHeight = "panel.height"
    }

    private(set) var panel: ShelfPanel
    private let model: AppModel
    private let previewAction: @MainActor () -> Void
    private var localEventMonitor: Any?
    private var globalEventMonitor: Any?
    private var resizeObserver: NSObjectProtocol?

    var isVisible: Bool {
        panel.isVisible
    }

    init(
        model: AppModel,
        previewAction: @escaping @MainActor () -> Void
    ) {
        self.model = model
        self.previewAction = previewAction

        let storedWidth = UserDefaults.standard.double(forKey: DefaultsKey.panelWidth)
        let storedHeight = UserDefaults.standard.double(forKey: DefaultsKey.panelHeight)
        let size = NSSize(
            width: storedWidth >= 620 ? storedWidth : 780,
            height: storedHeight >= 340 ? storedHeight : 500
        )

        panel = ShelfPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        configurePanel()
        OutboundDragMaskHook.install { model.dragOperation.dragOperationMask }
        installEventMonitors()
        installResizeObserver()
    }

    func toggle() {
        isVisible ? hide() : show()
    }

    func show() {
        guard !panel.isVisible else {
            panel.makeKeyAndOrderFront(nil)
            return
        }

        positionPanel()
        model.refresh()
        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(nil)
        panel.makeFirstResponder(nil)
        NSApp.activate(ignoringOtherApps: true)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.14
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
        }
    }

    func hide() {
        guard panel.isVisible else { return }
        panel.orderOut(nil)
    }

    func invalidate() {
        if let localEventMonitor {
            NSEvent.removeMonitor(localEventMonitor)
            self.localEventMonitor = nil
        }
        if let globalEventMonitor {
            NSEvent.removeMonitor(globalEventMonitor)
            self.globalEventMonitor = nil
        }
        if let resizeObserver {
            NotificationCenter.default.removeObserver(resizeObserver)
            self.resizeObserver = nil
        }
    }

    func positionPanel() {
        let screen = Self.screenContainingMouse() ?? NSScreen.main
        guard let screen else { return }

        var frame = panel.frame
        frame.size.width = min(frame.width, screen.visibleFrame.width - 24)
        frame.size.height = min(frame.height, screen.visibleFrame.height - 24)
        frame.origin = PanelPositionCalculator.origin(
            visibleFrame: screen.visibleFrame,
            panelSize: frame.size
        )
        panel.setFrame(frame, display: true)
    }

    private func configurePanel() {
        panel.title = "Workspace Shelf"
        panel.level = .floating
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = false
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.minSize = NSSize(width: 620, height: 340)
        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .transient,
            .ignoresCycle
        ]

        let rootView = ShelfRootView(
            model: model,
            closeAction: { [weak self] in self?.hide() }
        )
        let hostingView = NSHostingView(rootView: rootView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        panel.contentView = hostingView
    }

    private func installEventMonitors() {
        localEventMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .keyDown]
        ) { [weak self] event in
            guard let self else { return event }

            if event.type == .keyDown {
                guard event.window === self.panel else { return event }
                let commandPressed = event.modifierFlags.contains(.command)
                let shiftPressed = event.modifierFlags.contains(.shift)

                if commandPressed {
                    switch event.keyCode {
                    case 0 where !(self.panel.firstResponder is NSTextView): // A
                        self.model.selectAll()
                        return nil
                    // Same text-field guard as Select All: while the search
                    // box has focus these have to stay ordinary text
                    // copy/paste rather than file copy/paste.
                    case 8 where !(self.panel.firstResponder is NSTextView): // C
                        self.model.copySelectedFile()
                        return nil
                    case 9 where !(self.panel.firstResponder is NSTextView): // V
                        self.model.pasteIntoCurrentFolder()
                        return nil
                    case 45 where shiftPressed: // Shift + N
                        self.model.beginNewFolder()
                        return nil
                    // Text-field guard again: while editing, ⌘⌫ is
                    // delete-to-start-of-line, not move-file-to-Trash.
                    case 51 where !(self.panel.firstResponder is NSTextView): // Command + Delete
                        self.model.requestMoveSelectedToTrash()
                        return nil
                    case 15: // R
                        self.model.refresh()
                        return nil
                    default:
                        break
                    }
                }

                // The text-field guard lives in the `where` clauses so that a
                // guarded key falls through to `default` — and on to the field
                // editor — while typing. Guarding inside the case body and
                // returning nil regardless swallowed the key either way, which
                // is how the search box came to reject the space bar.
                switch event.keyCode {
                case 53:
                    self.hide()
                    return nil
                case 49 where !(self.panel.firstResponder is NSTextView): // Space
                    self.previewAction()
                    return nil
                case 36 where !(self.panel.firstResponder is NSTextView): // Return
                    if let entry = self.model.selectedEntry {
                        self.model.activate(entry)
                    }
                    return nil
                default:
                    break
                }
            }

            // Double-click to open, handled globally instead of with a
            // per-row gesture: any tap/click gesture recognizer placed on
            // List row content competes with the List's own native
            // click-to-select and made single clicks unreliable. By the
            // time this second mouseDown (clickCount 2) is seen, the first
            // click has already gone through and updated the selection
            // natively, so there's nothing to hit-test here — just open
            // whatever `doubleClickTarget` resolves to — the selection in
            // list view, the row under the pointer in column view, where an
            // ancestor column's row never becomes the app-wide selection.
            // (Grid view isn't List-backed and already handles its own
            // double-click.)
            if event.type == .leftMouseDown,
               event.window === self.panel,
               event.clickCount == 2,
               self.model.viewMode != .grid,
               !(self.panel.firstResponder is NSTextView),
               let entry = self.model.doubleClickTarget {
                self.model.activate(entry)
            }

            // Only on a press: the monitor also sees every drag and mouse-up
            // now, and re-checking dismissal on each of those would be pure
            // churn during a drag.
            if event.window === self.panel,
               event.type == .leftMouseDown || event.type == .rightMouseDown {
                DispatchQueue.main.async { [weak self] in
                    self?.dismissForOutsideClickIfNeeded()
                }
            }
            return event
        }

        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            Task { @MainActor in
                self?.dismissForOutsideClickIfNeeded()
            }
        }
    }

    private func dismissForOutsideClickIfNeeded() {
        guard panel.isVisible, !model.isPinned, NSApp.modalWindow == nil else {
            return
        }
        guard !panel.frame.contains(NSEvent.mouseLocation) else {
            return
        }
        hide()
    }

    private func installResizeObserver() {
        resizeObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didEndLiveResizeNotification,
            object: panel,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.savePanelSize()
            }
        }
    }

    private func savePanelSize() {
        UserDefaults.standard.set(panel.frame.width, forKey: DefaultsKey.panelWidth)
        UserDefaults.standard.set(panel.frame.height, forKey: DefaultsKey.panelHeight)
    }

    private static func screenContainingMouse() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first { $0.frame.contains(mouseLocation) }
    }

}
