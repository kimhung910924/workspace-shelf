import AppKit
import Foundation
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var workspaces: [ResolvedWorkspace] = []
    @Published var selectedWorkspaceID: UUID?
    @Published private(set) var currentDirectoryURL: URL?
    @Published private(set) var entries: [FileEntry] = []
    @Published private(set) var selectedEntryIDs: Set<URL> = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published var searchQuery = ""
    @Published var draftName = ""
    @Published var isRenameDialogPresented = false
    @Published var isNewFolderDialogPresented = false
    @Published var isTrashConfirmationPresented = false
    @Published var isPasteConflictPresented = false
    @Published var sortOption: FileSortOption = .name {
        didSet {
            entries = FileEntrySorter.sort(entries, by: sortOption)
            resortAncestorColumns()
            UserDefaults.standard.set(sortOption.rawValue, forKey: DefaultsKey.sortOption)
        }
    }
    @Published var sortAscending = true {
        didSet {
            entries = FileEntrySorter.sort(
                entries,
                by: sortOption,
                ascending: sortAscending
            )
            resortAncestorColumns()
            UserDefaults.standard.set(sortAscending, forKey: DefaultsKey.sortAscending)
        }
    }
    /// Whether an outbound drag offers a move or only a copy. Menu bar
    /// setting; see `OutboundDragOperation`.
    @Published var dragOperation: OutboundDragOperation = .move {
        didSet {
            UserDefaults.standard.set(dragOperation.rawValue, forKey: DefaultsKey.dragOperation)
        }
    }
    @Published var isPinned: Bool {
        didSet {
            UserDefaults.standard.set(isPinned, forKey: DefaultsKey.isPinned)
        }
    }
    @Published var viewMode: BrowserViewMode = .list {
        didSet {
            UserDefaults.standard.set(viewMode.rawValue, forKey: DefaultsKey.viewMode)
            if viewMode == .column {
                rebuildAncestorColumns()
            }
        }
    }
    @Published private(set) var ancestorColumns: [BrowserColumn] = []

    private let workspaceStore: WorkspaceStore
    private var directoryWatcher: DirectoryWatcher?
    private var navigationHistory: [URL] = []
    private var loadGeneration = 0
    private var renameTarget: FileEntry?
    private var trashTargets: [FileEntry] = []
    private var pendingPasteURLs: [URL] = []
    private var selectionAnchorID: URL?
    private var columnGeneration = 0

    init(workspaceStore: WorkspaceStore = WorkspaceStore()) {
        self.workspaceStore = workspaceStore
        self.isPinned = UserDefaults.standard.bool(forKey: DefaultsKey.isPinned)

        if let rawValue = UserDefaults.standard.string(forKey: DefaultsKey.sortOption),
           let storedSort = FileSortOption(rawValue: rawValue) {
            self.sortOption = storedSort
        }
        if UserDefaults.standard.object(forKey: DefaultsKey.sortAscending) != nil {
            self.sortAscending = UserDefaults.standard.bool(
                forKey: DefaultsKey.sortAscending
            )
        }
        if let rawValue = UserDefaults.standard.string(forKey: DefaultsKey.viewMode),
           let storedMode = BrowserViewMode(rawValue: rawValue) {
            self.viewMode = storedMode
        }
        if let rawValue = UserDefaults.standard.string(forKey: DefaultsKey.dragOperation),
           let storedOperation = OutboundDragOperation(rawValue: rawValue) {
            self.dragOperation = storedOperation
        }

        directoryWatcher = DirectoryWatcher { [weak self] in
            self?.reloadCurrentDirectoryQuietly()
        }
        restoreWorkspaces()
    }

    var selectedWorkspace: ResolvedWorkspace? {
        guard let selectedWorkspaceID else { return nil }
        return workspaces.first { $0.id == selectedWorkspaceID }
    }

    var workspaceRootURL: URL? {
        selectedWorkspace?.url
    }

    var currentRelativePath: String {
        guard
            let rootURL = workspaceRootURL,
            let currentDirectoryURL,
            let relativePath = WorkspacePathPolicy.relativePath(
                from: rootURL,
                to: currentDirectoryURL
            )
        else {
            return ""
        }
        return relativePath.isEmpty ? rootURL.lastPathComponent : relativePath
    }

    var canNavigateBack: Bool {
        !navigationHistory.isEmpty
    }

    var canNavigateUp: Bool {
        guard let rootURL = workspaceRootURL, let currentDirectoryURL else {
            return false
        }
        return currentDirectoryURL.standardizedFileURL != rootURL.standardizedFileURL
    }

    var filteredEntries: [FileEntry] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return entries }
        return entries.filter {
            $0.name.localizedCaseInsensitiveContains(query)
        }
    }

    /// All currently selected entries in the current folder, in display order.
    var selectedEntries: [FileEntry] {
        entries.filter { selectedEntryIDs.contains($0.id) }
    }

    /// The single selected entry, or `nil` when zero or several are selected.
    /// Used for actions that only make sense on exactly one item (rename,
    /// Return-to-open).
    var selectedEntry: FileEntry? {
        let selected = selectedEntries
        return selected.count == 1 ? selected.first : nil
    }

    /// What a double-click should open. In column view the clicked row may
    /// live in an ancestor column, whose selection is deliberately local to
    /// that column and never becomes the app-wide selection — so opening
    /// `selectedEntry` there would open a file from the *current* folder
    /// instead of the one under the pointer. The hovered row is the
    /// authoritative answer for a click (the pointer is by definition on the
    /// row being clicked); the selection stays the fallback for the keyboard
    /// path and for clicks that land outside any row.
    var doubleClickTarget: FileEntry? {
        guard viewMode == .column else { return selectedEntry }
        return hoveredColumnEntry ?? selectedEntry
    }

    /// Deliberately not `@Published`: hover changes on every pointer move
    /// across a column, and republishing would re-render every column's rows
    /// each time. Nothing renders from this — it is only read when a
    /// double-click arrives.
    private var hoveredColumnEntryID: URL?

    /// Resolved against every visible column, so a stale hover left behind by
    /// navigation simply resolves to `nil` rather than a wrong entry.
    private var hoveredColumnEntry: FileEntry? {
        guard let hoveredColumnEntryID else { return nil }
        if let entry = entries.first(where: { $0.id == hoveredColumnEntryID }) {
            return entry
        }
        for column in ancestorColumns {
            if let entry = column.entries.first(where: { $0.id == hoveredColumnEntryID }) {
                return entry
            }
        }
        return nil
    }

    /// `isHovering == false` only clears the hover when this row still owns
    /// it: SwiftUI can deliver the new row's enter before the old row's exit,
    /// and an unconditional clear would then throw away the live value.
    func setColumnRowHovered(_ id: URL, isHovering: Bool) {
        if isHovering {
            hoveredColumnEntryID = id
        } else if hoveredColumnEntryID == id {
            hoveredColumnEntryID = nil
        }
    }

    func isSelected(_ entry: FileEntry) -> Bool {
        selectedEntryIDs.contains(entry.id)
    }

    /// Handles a row click with Finder-style multi-selection semantics:
    /// plain click selects only this row, Command-click toggles this row in
    /// the selection, Shift-click selects the range between the last anchor
    /// and this row. Also resigns keyboard focus from any active text field
    /// (search box, rename dialog, etc) — without this, once the user clicks
    /// into the search field the panel's first responder stays the field
    /// editor even after clicking a different row (SwiftUI's `onTapGesture`
    /// doesn't take first responder), so the Space-to-preview shortcut keeps
    /// getting swallowed as if the user were still typing.
    func selectEntry(_ entry: FileEntry, extend: Bool = false, range: Bool = false) {
        NSApp.keyWindow?.makeFirstResponder(nil)

        let visible = filteredEntries
        if range,
           let anchorID = selectionAnchorID,
           let anchorIndex = visible.firstIndex(where: { $0.id == anchorID }),
           let targetIndex = visible.firstIndex(where: { $0.id == entry.id }) {
            let bounds = min(anchorIndex, targetIndex)...max(anchorIndex, targetIndex)
            selectedEntryIDs = Set(visible[bounds].map(\.id))
        } else if extend {
            if selectedEntryIDs.contains(entry.id) {
                selectedEntryIDs.remove(entry.id)
            } else {
                selectedEntryIDs.insert(entry.id)
            }
            selectionAnchorID = entry.id
        } else {
            selectedEntryIDs = [entry.id]
            selectionAnchorID = entry.id
        }
    }

    func selectAll() {
        selectedEntryIDs = Set(filteredEntries.map(\.id))
        selectionAnchorID = filteredEntries.last?.id
    }

    /// Used by the native `List` selection binding in list/column view,
    /// which handles its own Shift/Command-click logic (and, crucially,
    /// bundles every selected row into one drag session automatically) —
    /// unlike the manual grid view, it just needs to be told the resulting set.
    func setSelection(_ ids: Set<URL>) {
        selectedEntryIDs = ids
    }

    var trashTargetName: String {
        switch trashTargets.count {
        case 0: "선택한 항목"
        case 1: trashTargets[0].name
        default: "\(trashTargets.count)개 항목"
        }
    }

    func addWorkspace() {
        let panel = NSOpenPanel()
        panel.title = "Workspace로 사용할 폴더 선택"
        panel.message = "폴더는 이동하지 않으며 빠른 접근 권한만 저장합니다."
        panel.prompt = "폴더 추가"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }
        addWorkspace(at: url)
    }

    func addWorkspace(at url: URL) {
        let normalizedURL = url.standardizedFileURL
        if let existing = workspaces.first(where: {
            guard let existingURL = $0.url else { return false }
            return existingURL.resolvingSymlinksInPath()
                == normalizedURL.resolvingSymlinksInPath()
        }) {
            selectWorkspace(existing.id)
            return
        }

        do {
            let record = try workspaceStore.makeRecord(
                for: normalizedURL,
                name: normalizedURL.lastPathComponent,
                sortOrder: workspaces.count
            )
            let didStartAccess = normalizedURL.startAccessingSecurityScopedResource()
            workspaces.append(
                ResolvedWorkspace(
                    record: record,
                    url: normalizedURL,
                    isAccessingSecurityScopedResource: didStartAccess,
                    errorDescription: nil
                )
            )
            try persistWorkspaces()
            selectWorkspace(record.id)
        } catch {
            errorMessage = "폴더를 등록하지 못했습니다. \(error.localizedDescription)"
        }
    }

    /// Registers folders dropped onto the sidebar. Files are ignored the way
    /// Finder's own sidebar does — only a directory can become a Workspace.
    func addWorkspaces(at urls: [URL]) {
        let folders = urls.filter {
            (try? $0.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
        }
        guard !folders.isEmpty else {
            errorMessage = "폴더만 Workspace로 추가할 수 있습니다."
            return
        }
        for folder in folders {
            addWorkspace(at: folder)
        }
    }

    /// Reorders the sidebar's registered folders (drag-to-reorder). The new
    /// order is persisted immediately, same as any other workspace edit.
    func moveWorkspace(fromOffsets: IndexSet, toOffset: Int) {
        workspaces.move(fromOffsets: fromOffsets, toOffset: toOffset)
        do {
            try persistWorkspaces()
        } catch {
            errorMessage = "Workspace 순서를 저장하지 못했습니다. \(error.localizedDescription)"
        }
    }

    func removeWorkspace(_ id: UUID) {
        guard let index = workspaces.firstIndex(where: { $0.id == id }) else {
            return
        }

        let removed = workspaces.remove(at: index)
        if removed.isAccessingSecurityScopedResource {
            removed.url?.stopAccessingSecurityScopedResource()
        }

        if selectedWorkspaceID == id {
            navigationHistory.removeAll()
            currentDirectoryURL = nil
            directoryWatcher?.stop()
            entries = []
            ancestorColumns = []
            clearSelection()
            selectedWorkspaceID = nil

            if !workspaces.isEmpty {
                let nextIndex = min(index, workspaces.count - 1)
                selectWorkspace(workspaces[nextIndex].id)
            }
        }

        do {
            try persistWorkspaces()
        } catch {
            errorMessage = "Workspace 목록을 저장하지 못했습니다. \(error.localizedDescription)"
        }
    }

    func selectWorkspace(_ id: UUID) {
        guard let workspace = workspaces.first(where: { $0.id == id }) else {
            return
        }
        selectedWorkspaceID = id
        navigationHistory.removeAll()
        clearSelection()

        guard let rootURL = workspace.url else {
            currentDirectoryURL = nil
            directoryWatcher?.stop()
            entries = []
            ancestorColumns = []
            errorMessage = workspace.errorDescription ?? "폴더에 접근할 수 없습니다."
            return
        }
        loadDirectory(rootURL)
    }

    func activate(_ entry: FileEntry) {
        if entry.canNavigate {
            navigateInto(entry.url)
        } else if !FileSystemService.open(entry.url) {
            errorMessage = "기본 앱에서 \(entry.name)을(를) 열지 못했습니다."
        }
    }

    func navigateInto(_ url: URL) {
        guard let rootURL = workspaceRootURL else { return }
        guard WorkspacePathPolicy.contains(url, within: rootURL) else {
            errorMessage = "등록한 Workspace 밖으로 이동할 수 없습니다."
            return
        }

        if let currentDirectoryURL {
            navigationHistory.append(currentDirectoryURL)
        }
        loadDirectory(url)
    }

    func navigateBack() {
        guard let previousURL = navigationHistory.popLast() else { return }
        loadDirectory(previousURL)
    }

    func navigateUp() {
        guard
            let rootURL = workspaceRootURL,
            let currentDirectoryURL,
            currentDirectoryURL.standardizedFileURL != rootURL.standardizedFileURL
        else {
            return
        }

        let parentURL = currentDirectoryURL.deletingLastPathComponent()
        guard WorkspacePathPolicy.contains(parentURL, within: rootURL) else {
            return
        }
        navigationHistory.append(currentDirectoryURL)
        loadDirectory(parentURL)
    }

    func refresh() {
        guard let currentDirectoryURL else { return }
        loadDirectory(currentDirectoryURL)
    }

    func revealInFinder(_ url: URL) {
        FileSystemService.revealInFinder(url)
    }

    func openInTerminal(_ url: URL) {
        FileSystemService.openInTerminal(url)
    }

    func copyPath(_ url: URL) {
        FileSystemService.copyToPasteboard(url.path)
    }

    func copyName(_ url: URL) {
        FileSystemService.copyToPasteboard(url.lastPathComponent)
    }

    func copyFile(_ entry: FileEntry) {
        FileSystemService.copyFileURLsToPasteboard([entry.url])
    }

    func copySelectedFile() {
        let targets = selectedEntries
        guard !targets.isEmpty else {
            errorMessage = "복사할 파일 또는 폴더를 먼저 선택하세요."
            return
        }
        FileSystemService.copyFileURLsToPasteboard(targets.map(\.url))
    }

    func pasteIntoCurrentFolder() {
        guard let currentDirectoryURL else { return }
        let sourceURLs = FileSystemService.fileURLsFromPasteboard()
        guard !sourceURLs.isEmpty else {
            errorMessage = "붙여넣을 파일 또는 폴더가 없습니다."
            return
        }

        if FileOperationService.hasConflicts(
            sourceURLs: sourceURLs,
            destinationDirectoryURL: currentDirectoryURL
        ) {
            pendingPasteURLs = sourceURLs
            isPasteConflictPresented = true
            return
        }
        copyIntoCurrentFolder(sourceURLs, renameConflicts: false)
    }

    func pasteWithRenamedCopies() {
        guard !pendingPasteURLs.isEmpty else { return }
        let sourceURLs = pendingPasteURLs
        pendingPasteURLs = []
        copyIntoCurrentFolder(sourceURLs, renameConflicts: true)
    }

    func cancelPasteConflict() {
        pendingPasteURLs = []
    }

    func beginRename(_ entry: FileEntry) {
        renameTarget = entry
        draftName = entry.name
        isRenameDialogPresented = true
    }

    func confirmRename() {
        guard let entry = renameTarget else { return }
        let requestedName = draftName
        isRenameDialogPresented = false
        renameTarget = nil
        runFileOperation("이름을 변경하지 못했습니다") {
            FileOperationService.rename(entry.url, to: requestedName)
        }
    }

    func cancelRename() {
        renameTarget = nil
    }

    func beginNewFolder() {
        guard currentDirectoryURL != nil else { return }
        draftName = "새 폴더"
        isNewFolderDialogPresented = true
    }

    func confirmNewFolder() {
        guard let currentDirectoryURL else { return }
        let requestedName = draftName
        isNewFolderDialogPresented = false
        runFileOperation("새 폴더를 만들지 못했습니다") {
            FileOperationService.createFolder(named: requestedName, in: currentDirectoryURL)
        }
    }

    func cancelNewFolder() {
        draftName = ""
    }

    func requestMoveToTrash(_ entry: FileEntry) {
        trashTargets = [entry]
        isTrashConfirmationPresented = true
    }

    func requestMoveSelectedToTrash() {
        let targets = selectedEntries
        guard !targets.isEmpty else {
            errorMessage = "휴지통으로 보낼 파일 또는 폴더를 먼저 선택하세요."
            return
        }
        trashTargets = targets
        isTrashConfirmationPresented = true
    }

    func confirmMoveToTrash() {
        guard !trashTargets.isEmpty else { return }
        let targets = trashTargets
        isTrashConfirmationPresented = false
        trashTargets = []
        runFileOperation("휴지통으로 이동하지 못했습니다") {
            for target in targets {
                let result = FileOperationService.moveToTrash(target.url)
                if case .failure = result {
                    return result
                }
            }
            return .success
        }
    }

    func cancelMoveToTrash() {
        trashTargets = []
    }

    func selectedFileURLsForPreview() -> [URL] {
        let selected = selectedEntries
        guard !selected.isEmpty else {
            errorMessage = "미리볼 파일을 먼저 선택하세요."
            return []
        }
        let files = selected.filter { !$0.isDirectory }
        guard !files.isEmpty else {
            errorMessage = "폴더가 아닌 파일을 선택한 뒤 Space를 누르세요."
            return []
        }
        return files.map(\.url)
    }

    func clearError() {
        errorMessage = nil
    }

    func shutdown() {
        directoryWatcher?.stop()
        for workspace in workspaces where workspace.isAccessingSecurityScopedResource {
            workspace.url?.stopAccessingSecurityScopedResource()
        }
    }

    private func restoreWorkspaces() {
        do {
            let records = try workspaceStore.load()
            var shouldSaveRefreshedBookmarks = false

            workspaces = records.map { record in
                do {
                    let resolution = try workspaceStore.resolve(record)
                    var resolvedRecord = record
                    if resolution.isStale {
                        resolvedRecord = try workspaceStore.refreshedRecord(
                            record,
                            url: resolution.url
                        )
                        shouldSaveRefreshedBookmarks = true
                    }
                    let didStartAccess = resolution.url
                        .startAccessingSecurityScopedResource()
                    return ResolvedWorkspace(
                        record: resolvedRecord,
                        url: resolution.url,
                        isAccessingSecurityScopedResource: didStartAccess,
                        errorDescription: nil
                    )
                } catch {
                    return ResolvedWorkspace(
                        record: record,
                        url: nil,
                        isAccessingSecurityScopedResource: false,
                        errorDescription: error.localizedDescription
                    )
                }
            }

            if shouldSaveRefreshedBookmarks {
                try persistWorkspaces()
            }

            if let first = workspaces.first {
                selectWorkspace(first.id)
            }
        } catch {
            errorMessage = "저장된 Workspace를 불러오지 못했습니다. \(error.localizedDescription)"
        }
    }

    private func persistWorkspaces() throws {
        try workspaceStore.save(workspaces.map(\.record))
    }

    private func clearSelection() {
        selectedEntryIDs = []
        selectionAnchorID = nil
    }

    private func resortAncestorColumns() {
        guard !ancestorColumns.isEmpty else { return }
        for index in ancestorColumns.indices {
            ancestorColumns[index].entries = FileEntrySorter.sort(
                ancestorColumns[index].entries,
                by: sortOption,
                ascending: sortAscending
            )
        }
    }

    /// Rebuilds the column chain shown by the "컬럼 보기" browser: one column
    /// per ancestor directory between the workspace root and
    /// `currentDirectoryURL`. The final column (`currentDirectoryURL`
    /// itself) is not part of this array — it reuses `entries`, the same
    /// state the list/grid views already read, so all three view modes stay
    /// in sync automatically.
    private func rebuildAncestorColumns() {
        guard viewMode == .column,
              let rootURL = workspaceRootURL,
              let currentDirectoryURL else {
            ancestorColumns = []
            return
        }

        let ancestorURLs = WorkspacePathPolicy.ancestorChain(
            from: rootURL,
            to: currentDirectoryURL
        )

        columnGeneration += 1
        let generation = columnGeneration

        ancestorColumns = ancestorURLs.enumerated().map { index, directoryURL in
            let highlightedChild = index + 1 < ancestorURLs.count
                ? ancestorURLs[index + 1]
                : currentDirectoryURL
            if let existing = ancestorColumns.first(where: { $0.directoryURL == directoryURL }),
               !existing.isLoading {
                var column = existing
                column.highlightedChildURL = highlightedChild
                return column
            }
            return BrowserColumn(
                directoryURL: directoryURL,
                highlightedChildURL: highlightedChild
            )
        }

        let requestedSort = sortOption
        let ascending = sortAscending

        for directoryURL in ancestorURLs {
            guard let index = ancestorColumns.firstIndex(where: { $0.directoryURL == directoryURL }),
                  ancestorColumns[index].isLoading else {
                continue
            }
            Task {
                let result = await Task.detached(priority: .userInitiated) {
                    FileSystemService.listDirectory(at: directoryURL)
                }.value

                guard generation == columnGeneration,
                      let index = ancestorColumns.firstIndex(where: { $0.directoryURL == directoryURL }) else {
                    return
                }

                switch result {
                case .success(let loaded):
                    ancestorColumns[index].entries = FileEntrySorter.sort(
                        loaded,
                        by: requestedSort,
                        ascending: ascending
                    )
                    ancestorColumns[index].isLoading = false
                case .failure(let message):
                    ancestorColumns[index].entries = []
                    ancestorColumns[index].isLoading = false
                    ancestorColumns[index].errorMessage = message
                }
            }
        }
    }

    /// A reload triggered by the folder changing on disk rather than by the
    /// user — after a file is dragged out to Finder as a move, say. Keeps
    /// the selection and skips the loading indicator so the listing updates
    /// without the view flickering under the user.
    private func reloadCurrentDirectoryQuietly() {
        guard let currentDirectoryURL else { return }
        loadDirectory(currentDirectoryURL, isSilent: true)
    }

    private func loadDirectory(_ url: URL, isSilent: Bool = false) {
        loadGeneration += 1
        let generation = loadGeneration
        let requestedURL = url.standardizedFileURL
        currentDirectoryURL = requestedURL
        directoryWatcher?.watch(requestedURL)
        if !isSilent {
            isLoading = true
            errorMessage = nil
            clearSelection()
        }
        rebuildAncestorColumns()
        let requestedSort = sortOption
        let ascending = sortAscending

        Task {
            let result = await Task.detached(priority: .userInitiated) {
                FileSystemService.listDirectory(at: requestedURL)
            }.value

            guard generation == loadGeneration,
                  currentDirectoryURL == requestedURL else {
                return
            }
            isLoading = false

            switch result {
            case .success(let loadedEntries):
                entries = FileEntrySorter.sort(
                    loadedEntries,
                    by: requestedSort,
                    ascending: ascending
                )
            case .failure(let message):
                entries = []
                errorMessage = "폴더 내용을 불러오지 못했습니다. \(message)"
            }
        }
    }

    /// Handles a drag dropped onto the browsing area or onto a folder row:
    /// moves the dragged items there by default (matching Finder's
    /// same-volume drag), or copies them when `copy` is true (Option-key
    /// held at drop time).
    func dropFiles(_ urls: [URL], into destinationDirectoryURL: URL, copy: Bool) {
        let destination = destinationDirectoryURL.standardizedFileURL
        let sources = Self.dropSources(from: urls, into: destination, copy: copy)
        guard !sources.isEmpty else { return }

        Task {
            let result = await Task.detached(priority: .userInitiated) {
                copy
                    ? FileOperationService.copy(sources, to: destination, renameConflicts: false)
                    : FileOperationService.move(sources, to: destination)
            }.value

            switch result {
            case .success:
                reloadDirectoryListing(at: destination)
                if !copy {
                    for parent in Set(sources.map { $0.deletingLastPathComponent().standardizedFileURL }) {
                        reloadDirectoryListing(at: parent)
                    }
                }
            case .failure(let message):
                errorMessage = (copy ? "복사하지 못했습니다. " : "이동하지 못했습니다. ") + message
            }
        }
    }

    /// Which of the dropped items to act on.
    ///
    /// A folder dropped into itself (or into anything inside itself) is
    /// always discarded — that drop can never work. An item dropped into
    /// the folder it already lives in is discarded only for a *move*, where
    /// it is a no-op; the same drop with Option held is Finder's duplicate
    /// gesture, and the copy machinery already turns it into "이름 copy" the
    /// way paste-in-place does.
    static func dropSources(from urls: [URL], into destination: URL, copy: Bool) -> [URL] {
        // Compared as paths: URL equality tells /Notes and /Notes/ apart,
        // and whether a directory URL carries the trailing slash depends on
        // which API produced it.
        let destinationPath = destination.standardizedFileURL.path
        return urls.map { $0.standardizedFileURL }
            .filter { !isSelfOrDescendant(destination, of: $0) }
            .filter { copy || $0.deletingLastPathComponent().standardizedFileURL.path != destinationPath }
    }

    /// Whether `destination` is `source` itself or somewhere beneath it,
    /// which is the one drop that can never work: a folder cannot be put
    /// inside itself. Compares path components rather than string prefixes
    /// so that `/a/bc` is not read as living inside `/a/b`.
    static func isSelfOrDescendant(_ destination: URL, of source: URL) -> Bool {
        let sourceComponents = source.standardizedFileURL.pathComponents
        let destinationComponents = destination.standardizedFileURL.pathComponents
        guard destinationComponents.count >= sourceComponents.count else { return false }
        return Array(destinationComponents.prefix(sourceComponents.count)) == sourceComponents
    }

    /// Refreshes whichever on-screen listing(s) show `directoryURL`: the
    /// current folder (list/grid/final column) and/or a loaded ancestor
    /// column in the column browser.
    private func reloadDirectoryListing(at directoryURL: URL) {
        if directoryURL == currentDirectoryURL?.standardizedFileURL {
            refresh()
        }
        if ancestorColumns.contains(where: { $0.directoryURL == directoryURL }) {
            reloadColumn(directoryURL)
        }
    }

    private func reloadColumn(_ directoryURL: URL) {
        guard let index = ancestorColumns.firstIndex(where: { $0.directoryURL == directoryURL }) else {
            return
        }
        ancestorColumns[index].isLoading = true
        let requestedSort = sortOption
        let ascending = sortAscending
        let generation = columnGeneration

        Task {
            let result = await Task.detached(priority: .userInitiated) {
                FileSystemService.listDirectory(at: directoryURL)
            }.value

            guard generation == columnGeneration,
                  let index = ancestorColumns.firstIndex(where: { $0.directoryURL == directoryURL }) else {
                return
            }

            switch result {
            case .success(let loaded):
                ancestorColumns[index].entries = FileEntrySorter.sort(
                    loaded,
                    by: requestedSort,
                    ascending: ascending
                )
                ancestorColumns[index].isLoading = false
            case .failure(let message):
                ancestorColumns[index].errorMessage = message
                ancestorColumns[index].isLoading = false
            }
        }
    }

    private func copyIntoCurrentFolder(_ sourceURLs: [URL], renameConflicts: Bool) {
        guard let currentDirectoryURL else { return }
        runFileOperation("붙여넣지 못했습니다") {
            FileOperationService.copy(
                sourceURLs,
                to: currentDirectoryURL,
                renameConflicts: renameConflicts
            )
        }
    }

    private func runFileOperation(
        _ failurePrefix: String,
        operation: @escaping @Sendable () -> FileOperationResult
    ) {
        Task {
            let result = await Task.detached(priority: .userInitiated) {
                operation()
            }.value

            switch result {
            case .success:
                refresh()
            case .failure(let message):
                errorMessage = "\(failurePrefix) \(message)"
            }
        }
    }
}

enum FileEntrySorter {
    static func sort(
        _ entries: [FileEntry],
        by option: FileSortOption,
        ascending: Bool = true
    ) -> [FileEntry] {
        entries.sorted { left, right in
            if left.canNavigate != right.canNavigate {
                return left.canNavigate
            }

            let result: ComparisonResult
            switch option {
            case .name:
                result = left.name.localizedStandardCompare(right.name)
            case .modificationDate:
                result = compareOptional(
                    left.modificationDate,
                    right.modificationDate
                )
            case .type:
                result = left.typeDescription.localizedStandardCompare(
                    right.typeDescription
                )
            case .size:
                result = compareOptional(left.fileSize, right.fileSize)
            }

            if result == .orderedSame {
                return left.name.localizedStandardCompare(right.name) == .orderedAscending
            }
            return ascending ? result == .orderedAscending : result == .orderedDescending
        }
    }

    private static func compareOptional<T: Comparable>(
        _ left: T?,
        _ right: T?
    ) -> ComparisonResult {
        switch (left, right) {
        case let (left?, right?):
            if left == right { return .orderedSame }
            return left < right ? .orderedAscending : .orderedDescending
        case (.some, .none):
            return .orderedAscending
        case (.none, .some):
            return .orderedDescending
        case (.none, .none):
            return .orderedSame
        }
    }
}

private enum DefaultsKey {
    static let isPinned = "panel.isPinned"
    static let sortOption = "browser.sortOption"
    static let sortAscending = "browser.sortAscending"
    static let viewMode = "browser.viewMode"
    static let dragOperation = "drag.operation"
}
