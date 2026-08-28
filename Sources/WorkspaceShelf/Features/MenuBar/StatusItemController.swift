import AppKit

@MainActor
final class StatusItemController {
    private let statusItem: NSStatusItem
    private let panelController: ShelfPanelController
    private let model: AppModel

    init(panelController: ShelfPanelController, model: AppModel) {
        self.panelController = panelController
        self.model = model
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "square.stack.3d.up.fill",
                accessibilityDescription: "Workspace Shelf"
            )
            button.toolTip = "Workspace Shelf"
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    @objc
    private func statusItemClicked(_ sender: NSStatusBarButton) {
        if NSApp.currentEvent?.type == .rightMouseUp {
            statusItem.menu = makeContextMenu()
            sender.performClick(nil)
            statusItem.menu = nil
        } else {
            panelController.toggle()
        }
    }

    @objc
    private func openShelf() {
        panelController.show()
    }

    @objc
    private func addWorkspace() {
        panelController.show()
        model.addWorkspace()
    }

    @objc
    private func selectDragOperation(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let operation = OutboundDragOperation(rawValue: rawValue) else {
            return
        }
        model.dragOperation = operation
    }

    @objc
    private func quit() {
        NSApp.terminate(nil)
    }

    private func makeContextMenu() -> NSMenu {
        let menu = NSMenu()
        let openItem = NSMenuItem(
            title: "Workspace Shelf 열기",
            action: #selector(openShelf),
            keyEquivalent: ""
        )
        openItem.target = self
        menu.addItem(openItem)

        let addItem = NSMenuItem(
            title: "폴더 추가…",
            action: #selector(addWorkspace),
            keyEquivalent: ""
        )
        addItem.target = self
        menu.addItem(addItem)
        menu.addItem(.separator())

        let shortcutItem = NSMenuItem(
            title: "단축키: ⌥ Space",
            action: nil,
            keyEquivalent: ""
        )
        shortcutItem.isEnabled = false
        menu.addItem(shortcutItem)
        let dragMenu = NSMenu()
        for operation in OutboundDragOperation.allCases {
            let item = NSMenuItem(
                title: operation.menuTitle,
                action: #selector(selectDragOperation(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = operation.rawValue
            item.state = model.dragOperation == operation ? .on : .off
            dragMenu.addItem(item)
        }
        let dragItem = NSMenuItem(
            title: "다른 앱으로 드래그할 때",
            action: nil,
            keyEquivalent: ""
        )
        dragItem.submenu = dragMenu
        menu.addItem(dragItem)
        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Workspace Shelf 종료",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
        return menu
    }
}

