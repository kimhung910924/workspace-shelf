import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var model: AppModel?
    private var panelController: ShelfPanelController?
    private var statusItemController: StatusItemController?
    private var globalHotKey: GlobalHotKey?
    private var topEdgeTriggerMonitor: TopEdgeTriggerMonitor?
    private var quickLookController: QuickLookController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let model = AppModel()
        let quickLookController = QuickLookController()
        let panelController = ShelfPanelController(model: model) {
            let urls = model.selectedFileURLsForPreview()
            guard !urls.isEmpty else { return }
            quickLookController.show(urls: urls)
        }
        let statusItemController = StatusItemController(
            panelController: panelController,
            model: model
        )
        let globalHotKey = GlobalHotKey {
            panelController.toggle()
        }
        let topEdgeTriggerMonitor = TopEdgeTriggerMonitor(
            isPanelVisible: { panelController.isVisible },
            trigger: { panelController.show() }
        )

        self.model = model
        self.panelController = panelController
        self.statusItemController = statusItemController
        self.globalHotKey = globalHotKey
        self.topEdgeTriggerMonitor = topEdgeTriggerMonitor
        self.quickLookController = quickLookController

        do {
            try globalHotKey.register()
        } catch {
            model.errorMessage = error.localizedDescription
        }
        topEdgeTriggerMonitor.start()

        if ProcessInfo.processInfo.arguments.contains("--show-on-launch") {
            panelController.show()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        topEdgeTriggerMonitor?.stop()
        globalHotKey?.invalidate()
        panelController?.invalidate()
        model?.shutdown()
    }

    func applicationShouldTerminateAfterLastWindowClosed(
        _ sender: NSApplication
    ) -> Bool {
        false
    }
}
