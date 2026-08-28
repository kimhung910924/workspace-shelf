import AppKit
@preconcurrency import QuickLookUI

@MainActor
final class QuickLookController: NSObject {
    private var previewURLs: [URL] = []

    func show(url: URL) {
        show(urls: [url])
    }

    func show(urls: [URL]) {
        guard !urls.isEmpty else { return }
        previewURLs = urls

        guard let panel = QLPreviewPanel.shared() else { return }
        panel.dataSource = self
        panel.delegate = self
        panel.reloadData()
        panel.currentPreviewItemIndex = 0
        panel.makeKeyAndOrderFront(nil)
    }

}

extension QuickLookController: @MainActor QLPreviewPanelDataSource {
    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        previewURLs.count
    }

    func previewPanel(
        _ panel: QLPreviewPanel!,
        previewItemAt index: Int
    ) -> (any QLPreviewItem)! {
        guard previewURLs.indices.contains(index) else { return nil }
        return previewURLs[index] as NSURL
    }
}
