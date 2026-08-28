import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// Finder-style "컬럼 보기": every ancestor folder from the workspace root
/// down to the current folder is shown side by side in its own scrollable
/// column, so a file can be dragged straight into a parent folder without
/// first navigating away from where it currently lives.
struct ColumnBrowserView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 0) {
                    ForEach(model.ancestorColumns) { column in
                        ColumnView(
                            directoryURL: column.directoryURL,
                            entries: column.entries,
                            isLoading: column.isLoading,
                            errorMessage: column.errorMessage,
                            highlightedChildURL: column.highlightedChildURL,
                            isFinalColumn: false,
                            model: model
                        )
                        .id(column.directoryURL)
                        Divider()
                    }

                    if let currentDirectoryURL = model.currentDirectoryURL {
                        ColumnView(
                            directoryURL: currentDirectoryURL,
                            entries: model.filteredEntries,
                            isLoading: model.isLoading,
                            errorMessage: nil,
                            highlightedChildURL: nil,
                            isFinalColumn: true,
                            model: model
                        )
                        .id(currentDirectoryURL)
                    }
                }
            }
            .onChange(of: model.currentDirectoryURL) { _, newValue in
                guard let newValue else { return }
                withAnimation(.easeOut(duration: 0.18)) {
                    proxy.scrollTo(newValue, anchor: .trailing)
                }
            }
        }
        .background(Color(nsColor: .textBackgroundColor).opacity(0.35))
    }
}

private struct ColumnView: View {
    let directoryURL: URL
    let entries: [FileEntry]
    let isLoading: Bool
    let errorMessage: String?
    /// Which child in this column leads toward the folder currently open in
    /// the final column. Used to pre-select that row so the chain of
    /// folders stays visibly highlighted, matching Finder's column view.
    let highlightedChildURL: URL?
    /// Whether this column shows `currentDirectoryURL` itself (the
    /// rightmost column). Its selection is the app's real selection, wired
    /// to Space-preview, Cmd+C, and the toolbar's copy/trash buttons.
    /// Ancestor columns to its left keep their own local selection, purely
    /// so files there can still be clicked, multi-selected, and dragged —
    /// without hijacking what "the current selection" means app-wide.
    let isFinalColumn: Bool
    @ObservedObject var model: AppModel

    @State private var localSelection: Set<URL> = []

    var body: some View {
        VStack(spacing: 0) {
            Text(directoryURL.lastPathComponent)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .frame(height: 24)

            Divider()

            // A native List, not a manual ScrollView/LazyVStack: it gives
            // Shift/Command-click for free, and — the reason it matters here
            // — starting a drag from a row that's part of a multi-selection
            // automatically bundles every selected file into one drag
            // session instead of only the row that was clicked.
            List(selection: selectionBinding) {
                ForEach(entries) { entry in
                    ColumnRow(
                        entry: entry,
                        actions: actions(for: entry),
                        onHoverChange: { isHovering in
                            model.setColumnRowHovered(entry.id, isHovering: isHovering)
                        }
                    )
                    .folderDropTarget(for: entry, model: model, cornerRadius: 6)
                    .tag(entry.id)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .onChange(of: selectionBinding.wrappedValue) { _, newValue in
                expandIfSingleFolderSelected(newValue)
            }
            .onAppear {
                syncSelectionToChainHighlight()
            }
            .onChange(of: highlightedChildURL) { _, _ in
                syncSelectionToChainHighlight()
            }
            .frame(maxHeight: .infinity)

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(8)
            } else if isLoading {
                ProgressView()
                    .controlSize(.small)
                    .padding(8)
            } else if entries.isEmpty {
                Text(L10n.t("비어 있음", "Empty"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(8)
            }
        }
        .frame(width: 208, alignment: .top)
        .frame(maxHeight: .infinity)
        .fileDropTarget(into: directoryURL, model: model)
    }

    private var selectionBinding: Binding<Set<URL>> {
        if isFinalColumn {
            Binding(get: { model.selectedEntryIDs }, set: { model.setSelection($0) })
        } else {
            $localSelection
        }
    }

    /// Keeps the folder that continues the chain highlighted in this
    /// column, the way Finder does, until the user picks something else in
    /// this specific column.
    private func syncSelectionToChainHighlight() {
        guard !isFinalColumn, let highlightedChildURL else { return }
        localSelection = [highlightedChildURL]
    }

    /// Matches Finder's column view: selecting a folder (even via a plain
    /// single click) immediately expands it into the next column. Skips
    /// folders that are already the chain highlight, since that selection
    /// can also come from `syncSelectionToChainHighlight` re-asserting the
    /// existing chain rather than a genuine new click — re-navigating there
    /// would otherwise bounce the app back to a shallower folder.
    private func expandIfSingleFolderSelected(_ selection: Set<URL>) {
        guard selection.count == 1,
              let id = selection.first,
              id != highlightedChildURL,
              let entry = entries.first(where: { $0.id == id }),
              entry.canNavigate else {
            return
        }
        model.navigateInto(entry.url)
    }

    private func actions(for entry: FileEntry) -> FileRowActions {
        FileRowActions(
            select: { _, _ in },
            activate: { model.activate(entry) },
            reveal: { model.revealInFinder(entry.url) },
            terminal: { model.openInTerminal(entry.url) },
            copyPath: { model.copyPath(entry.url) },
            copyName: { model.copyName(entry.url) },
            rename: { model.beginRename(entry) },
            copy: { model.copyFile(entry) },
            trash: { model.requestMoveToTrash(entry) }
        )
    }

}

private struct ColumnRow: View {
    let entry: FileEntry
    let actions: FileRowActions
    /// Reported to the model so a double-click knows which column's row the
    /// pointer is on — see `AppModel.doubleClickTarget`. Hover is tracking
    /// area based, so unlike a click gesture it doesn't compete with the
    /// List's own click-to-select.
    let onHoverChange: (Bool) -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(nsImage: fileIcon(for: entry, size: 18))
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)

            Text(entry.name)
                .font(.system(size: 12.5))
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer(minLength: 4)

            if entry.canNavigate {
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        // No tap gesture here at all — see FileListRow. Double-click-to-open
        // for the final (current) column is handled globally in
        // ShelfPanelController; folders in any column already expand on a
        // plain single click via the List selection + onChange below.
        // See FileListRow.
        .itemProvider {
            fileDragItemProvider(for: entry.url)
        }
        .onHover(perform: onHoverChange)
        .contextMenu {
            fileContextMenuItems(for: entry, actions: actions)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.name), \(entry.typeDescription)")
    }
}
