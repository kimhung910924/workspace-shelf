import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct FileBrowserView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        Group {
            if model.selectedWorkspace == nil {
                addWorkspaceEmptyState
            } else if model.currentDirectoryURL == nil {
                unavailableState
            } else {
                browserContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.15), value: model.viewMode)
    }

    @ViewBuilder
    private var browserContent: some View {
        switch model.viewMode {
        case .list:
            VStack(spacing: 0) {
                header
                Divider()
                listContent
            }
        case .grid:
            gridContent
        case .column:
            ColumnBrowserView(model: model)
        }
    }

    private var listContent: some View {
        contentContainer {
            // A native List (rather than a ScrollView/LazyVStack of custom
            // rows) so macOS's own multi-selection drag machinery kicks in:
            // starting a drag from a row that's part of a multi-selection
            // automatically bundles every selected file into one drag
            // session instead of only the row that was clicked.
            List(selection: selectionBinding) {
                ForEach(model.filteredEntries) { entry in
                    FileListRow(entry: entry, actions: actions(for: entry))
                        .folderDropTarget(for: entry, model: model, cornerRadius: 6)
                        .tag(entry.id)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    private var selectionBinding: Binding<Set<URL>> {
        Binding(
            get: { model.selectedEntryIDs },
            set: { model.setSelection($0) }
        )
    }

    private var gridContent: some View {
        contentContainer {
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 96, maximum: 128), spacing: 14)],
                    spacing: 16
                ) {
                    ForEach(model.filteredEntries) { entry in
                        FileGridItem(
                            entry: entry,
                            isSelected: model.isSelected(entry),
                            actions: actions(for: entry)
                        )
                        .folderDropTarget(for: entry, model: model, cornerRadius: 10)
                    }
                }
                .padding(16)
            }
        }
    }

    /// Why the listing has nothing to show, which decides what to say about
    /// it. An empty folder and a search that matched nothing look identical
    /// otherwise, and the second one leaves the user unable to tell whether
    /// the search worked at all.
    enum BrowserEmptyState: Equatable {
        case none
        case folderIsEmpty
        case searchFoundNothing(query: String)
    }

    /// Kept separate from the view that reads it so the order of these cases
    /// can be tested: they overlap, and each one shadows the rest.
    static func emptyState(
        isLoading: Bool,
        entryCount: Int,
        matchCount: Int,
        searchQuery: String
    ) -> BrowserEmptyState {
        // While loading, the listing is only momentarily empty; saying so
        // would flash a message that contradicts the spinner beside it.
        guard !isLoading else { return .none }
        guard entryCount > 0 else { return .folderIsEmpty }
        guard matchCount == 0 else { return .none }
        // The folder has entries but none survive the filter, so a search
        // is what is hiding them.
        return .searchFoundNothing(
            query: searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    private var emptyState: BrowserEmptyState {
        Self.emptyState(
            isLoading: model.isLoading,
            entryCount: model.entries.count,
            matchCount: model.filteredEntries.count,
            searchQuery: model.searchQuery
        )
    }

    /// Wraps folder content with the shared empty-state / loading overlay
    /// used by both the list and grid presentations.
    @ViewBuilder
    private func contentContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            switch emptyState {
            case .none:
                content()
            case .folderIsEmpty:
                ContentUnavailableView(
                    "이 폴더는 비어 있습니다",
                    systemImage: "folder",
                    description: Text("새로고침하거나 다른 폴더를 선택하세요.")
                )
            case .searchFoundNothing(let query):
                ContentUnavailableView {
                    Label("일치하는 항목이 없습니다", systemImage: "magnifyingglass")
                } description: {
                    Text("이 폴더에 \"\(query)\"이(가) 이름에 들어간 항목이 없습니다.")
                } actions: {
                    Button("검색어 지우기") {
                        model.searchQuery = ""
                    }
                }
            }

            if model.isLoading {
                ProgressView("폴더 불러오는 중")
                    .padding(16)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
            }
        }
        // Claim the whole area even when the content is a compact empty
        // state. Without this the list view's column header is dragged into
        // the middle of the panel along with it, since the header and this
        // container are centred together as one short stack.
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // On the container rather than the list or grid itself, so the empty
        // state accepts drops too — an empty folder is one of the likeliest
        // places to drag a file into.
        .fileDropTarget(into: model.currentDirectoryURL, model: model)
    }

    private func actions(for entry: FileEntry) -> FileRowActions {
        FileRowActions(
            select: { shift, command in
                model.selectEntry(entry, extend: command, range: shift)
            },
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

    private var header: some View {
        HStack(spacing: 12) {
            Text("이름")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("수정일")
                .frame(width: 142, alignment: .leading)
            Text("크기")
                .frame(width: 76, alignment: .trailing)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 20)
        .frame(height: 30)
    }

    private var addWorkspaceEmptyState: some View {
        ContentUnavailableView {
            Label("자주 쓰는 폴더를 추가하세요", systemImage: "folder.badge.plus")
        } description: {
            Text("폴더는 이동하거나 복사하지 않고 빠른 접근 경로만 저장합니다.")
        } actions: {
            Button("폴더 추가", action: model.addWorkspace)
                .buttonStyle(.borderedProminent)
        }
    }

    private var unavailableState: some View {
        ContentUnavailableView {
            Label("폴더에 접근할 수 없습니다", systemImage: "exclamationmark.triangle")
        } description: {
            Text(model.selectedWorkspace?.errorDescription ?? "Finder에서 폴더 위치와 권한을 확인하세요.")
        } actions: {
            if let workspace = model.selectedWorkspace {
                Button("목록에서 제거", role: .destructive) {
                    model.removeWorkspace(workspace.id)
                }
            }
        }
    }
}

/// Bundles the actions a single file row can trigger, shared across the
/// list, grid, and column presentations so each only needs to describe its
/// own layout.
struct FileRowActions {
    /// `select(shiftHeld, commandHeld)` — mirrors Finder's click semantics.
    let select: (Bool, Bool) -> Void
    let activate: () -> Void
    let reveal: () -> Void
    let terminal: () -> Void
    let copyPath: () -> Void
    let copyName: () -> Void
    let rename: () -> Void
    let copy: () -> Void
    let trash: () -> Void
}

@ViewBuilder
func fileContextMenuItems(for entry: FileEntry, actions: FileRowActions) -> some View {
    Button(entry.canNavigate ? "폴더 열기" : "열기", action: actions.activate)
    Button("Finder에서 보기", action: actions.reveal)
    Button("Terminal에서 열기", action: actions.terminal)
    Divider()
    Button("이름 변경…", action: actions.rename)
    Button("복사", action: actions.copy)
    Button("휴지통으로 이동…", role: .destructive, action: actions.trash)
    Divider()
    Button("경로 복사", action: actions.copyPath)
    Button("이름 복사", action: actions.copyName)
}

/// Icons are looked up from Launch Services, which hits disk — with several
/// columns of rows on screen at once (column view) this was being redone on
/// every re-render and was the main source of the sluggishness. Cached per
/// (path, size) since a file's icon essentially never changes mid-session.
@MainActor
private final class FileIconCache {
    static let shared = FileIconCache()
    private let cache = NSCache<NSString, NSImage>()

    func icon(for entry: FileEntry, size: CGFloat) -> NSImage {
        let key = "\(entry.url.path)#\(Int(size))" as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }
        let image = NSWorkspace.shared.icon(forFile: entry.url.path)
        image.size = NSSize(width: size, height: size)
        cache.setObject(image, forKey: key)
        return image
    }
}

@MainActor
func fileIcon(for entry: FileEntry, size: CGFloat) -> NSImage {
    FileIconCache.shared.icon(for: entry, size: size)
}

/// The payload for dragging an item out of the shelf: a reference to the
/// real file, never a fresh copy of its bytes.
///
/// `NSItemProvider(contentsOf:)` registers the file's *data* under its
/// content type, so a receiver like Finder writes out a brand-new document
/// named after that type — dragging `기획서.md` to the Desktop produced
/// `Markdown text file.md`. Registering the file URL first makes Finder and
/// every other standard drop target treat the drag as the existing file, so
/// the name survives. The in-place file representation is the fallback for
/// receivers that want bytes rather than a URL — upload fields, editors.
func fileDragItemProvider(for url: URL) -> NSItemProvider {
    // Runs as the drag begins, which makes it the one place the app still
    // knows which real file is being dragged. The session's drag source
    // reads this registry to finish a move — the pasteboard can't tell it,
    // because reading that back yields AppKit's staged copy, not the
    // original.
    MainActor.assumeIsolated {
        OutboundDragMaskHook.pendingDragOriginals.append(url)
    }

    let contentType = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType

    let provider = NSItemProvider()
    provider.suggestedName = suggestedDragName(for: url, contentType: contentType)
    provider.registerObject(url as NSURL, visibility: .all)

    if let contentType {
        provider.registerFileRepresentation(
            forTypeIdentifier: contentType.identifier,
            fileOptions: [.openInPlace],
            visibility: .all
        ) { completion in
            completion(url, true, nil)
            return nil
        }
    }
    return provider
}

/// The name to suggest for the dragged file, which is a base name rather
/// than a filename: a receiver taking the file representation appends the
/// extension belonging to the registered content type itself, so suggesting
/// `기획서.md` landed on the Desktop as `기획서.md.md`.
///
/// The extension is only dropped when the content type would put the same
/// one back. A file whose extension does not match its type — the type was
/// guessed from something other than the name, or the name is misleading —
/// keeps its full name, since replacing a known-correct extension with a
/// guessed one is the worse of the two mistakes. Receivers that take the URL
/// instead never read this and always see the real name.
func suggestedDragName(for url: URL, contentType: UTType?) -> String {
    let fileExtension = url.pathExtension
    guard !fileExtension.isEmpty,
          let typeExtension = contentType?.preferredFilenameExtension,
          typeExtension.compare(fileExtension, options: .caseInsensitive) == .orderedSame
    else {
        return url.lastPathComponent
    }
    return url.deletingPathExtension().lastPathComponent
}


/// Handles the shift/command-aware tap gesture shared by every row style.
/// A single plain `.onTapGesture` (checking `clickCount` after the fact for
/// double-click) instead of a dedicated count-2 gesture recognizer: a
/// count-2 recognizer has to wait to see whether a second click actually
/// arrives before it can "fail over," and that wait is what was making
/// clicks feel swallowed when combined with `.onDrag` on the same row.
private struct SelectableRowModifier: ViewModifier {
    let onDoubleClick: () -> Void
    let onSelect: (_ shift: Bool, _ command: Bool) -> Void

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .onTapGesture {
                if NSApp.currentEvent?.clickCount == 2 {
                    onDoubleClick()
                } else {
                    let flags = NSEvent.modifierFlags
                    onSelect(flags.contains(.shift), flags.contains(.command))
                }
            }
    }
}

extension View {
    func selectableRow(
        onDoubleClick: @escaping () -> Void,
        onSelect: @escaping (_ shift: Bool, _ command: Bool) -> Void
    ) -> some View {
        modifier(SelectableRowModifier(onDoubleClick: onDoubleClick, onSelect: onSelect))
    }
}

private struct FileListRow: View {
    let entry: FileEntry
    let actions: FileRowActions

    var body: some View {
        HStack(spacing: 12) {
            Image(nsImage: fileIcon(for: entry, size: 22))
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)

            VStack(alignment: .leading, spacing: 1) {
                Text(entry.name)
                    .lineLimit(1)
                    .truncationMode(.middle)
                if entry.isSymbolicLink {
                    Text("별칭 또는 심볼릭 링크")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(modificationDateText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 142, alignment: .leading)

            Text(fileSizeText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 76, alignment: .trailing)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        // No tap gesture here at all — even a single-tap recognizer on List
        // row content competes with the List's own native click-to-select
        // on macOS and made clicks unreliable. Double-click-to-open is
        // handled globally in ShelfPanelController instead.
        //
        // The drag is SwiftUI's; `OutboundDragMaskHook` is what lets it
        // offer a move as well as a copy.
        .itemProvider {
            fileDragItemProvider(for: entry.url)
        }
        .contextMenu {
            fileContextMenuItems(for: entry, actions: actions)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.name), \(entry.typeDescription)")
    }

    private var modificationDateText: String {
        guard let modificationDate = entry.modificationDate else {
            return "—"
        }
        return AppFormatters.modificationDate.string(from: modificationDate)
    }

    private var fileSizeText: String {
        guard let fileSize = entry.fileSize else {
            return "—"
        }
        return AppFormatters.fileSize.string(fromByteCount: fileSize)
    }
}

private struct FileGridItem: View {
    let entry: FileEntry
    let isSelected: Bool
    let actions: FileRowActions

    var body: some View {
        VStack(spacing: 6) {
            Image(nsImage: fileIcon(for: entry, size: 48))
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)

            Text(entry.name)
                .font(.system(size: 11.5))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .truncationMode(.middle)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 6)
        .frame(width: 104, height: 92)
        .background(
            isSelected ? Color.accentColor.opacity(0.18) : Color.clear,
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.accentColor.opacity(0.35), lineWidth: 1)
            }
        }
        .selectableRow(onDoubleClick: actions.activate, onSelect: actions.select)
        .onDrag {
            fileDragItemProvider(for: entry.url)
        }
        .contextMenu {
            fileContextMenuItems(for: entry, actions: actions)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.name), \(entry.typeDescription)")
    }
}
