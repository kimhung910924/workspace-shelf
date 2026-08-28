import SwiftUI
import UniformTypeIdentifiers

struct WorkspaceSidebar: View {
    @ObservedObject var model: AppModel
    @State private var draggingWorkspaceID: UUID?
    @State private var isFolderDropTargeted = false

    var body: some View {
        VStack(spacing: 8) {
            if model.workspaces.isEmpty {
                Spacer()
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 28))
                    .foregroundStyle(.secondary)
                Text("등록된 폴더가 없습니다")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(model.workspaces) { workspace in
                            workspaceRow(workspace)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
                }
            }

            Divider()
            Button(action: model.addWorkspace) {
                Label("폴더 추가", systemImage: "plus")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
            .help("새 Workspace 폴더 추가")
        }
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.35))
        // Drop a folder anywhere on the sidebar — from Finder or from the
        // app's own browser — to register it, the same as "폴더 추가".
        // Declaring only `.fileURL` here leaves the rows' internal `.text`
        // reorder drags to the row delegates.
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.accentColor, lineWidth: 2)
                .padding(3)
                .opacity(isFolderDropTargeted ? 1 : 0)
                .allowsHitTesting(false)
        }
        .background(
            isFolderDropTargeted ? Color.accentColor.opacity(0.12) : Color.clear
        )
        .onDrop(of: [.fileURL], isTargeted: $isFolderDropTargeted) { providers in
            handleFolderDrop(providers)
        }
        // The only reliable "this drag is over" signal: a reorder drag
        // cancelled with Esc, or let go outside every drop target, ends
        // without any drop callback, and the dimmed row would stay dimmed —
        // with the stale ID then misreading the next drop as a reorder.
        .onReceive(
            NotificationCenter.default.publisher(for: .outboundDragSessionDidEnd)
        ) { _ in
            draggingWorkspaceID = nil
        }
    }

    private func handleFolderDrop(_ providers: [NSItemProvider]) -> Bool {
        registerDroppedFolders(providers, model: model)
    }

    private func workspaceRow(_ workspace: ResolvedWorkspace) -> some View {
        let isSelected = model.selectedWorkspaceID == workspace.id

        return HStack(spacing: 8) {
            Image(systemName: workspace.record.iconName)
                .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                .frame(width: 18)
            Text(workspace.record.name)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            if workspace.url == nil {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .accessibilityLabel("접근할 수 없음")
            }
        }
        .font(.system(size: 13))
        .padding(.horizontal, 9)
        .frame(height: 34)
        .background(
            isSelected ? Color.accentColor.opacity(0.16) : Color.clear,
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
        .opacity(draggingWorkspaceID == workspace.id ? 0.4 : 1)
        .contentShape(Rectangle())
        .onTapGesture {
            model.selectWorkspace(workspace.id)
        }
        // Press-and-hold to pick a folder up, drag it to reorder — the
        // reorder happens live as the drag passes over another row
        // (`dropEntered`), matching Finder/Music.app sidebar reordering.
        .onDrag {
            draggingWorkspaceID = workspace.id
            return NSItemProvider(object: workspace.id.uuidString as NSString)
        }
        // `.fileURL` as well as `.text`, because a row cannot decline a drop
        // and leave it to the sidebar underneath: whichever view is innermost
        // wins the drop whatever it then answers. A Markdown or plain-text
        // file's drag conforms to `.text`, so without this the drop would
        // land on a row and vanish.
        .onDrop(
            of: [.text, .fileURL],
            delegate: WorkspaceDropDelegate(
                target: workspace,
                model: model,
                draggingWorkspaceID: $draggingWorkspaceID
            )
        )
        .contextMenu {
            if let url = workspace.url {
                Button("Finder에서 보기") {
                    model.revealInFinder(url)
                }
                Button("Terminal에서 열기") {
                    model.openInTerminal(url)
                }
                Divider()
            }
            Button("목록에서 제거", role: .destructive) {
                model.removeWorkspace(workspace.id)
            }
        }
    }
}

@MainActor
private struct WorkspaceDropDelegate: DropDelegate {
    let target: ResolvedWorkspace
    let model: AppModel
    @Binding var draggingWorkspaceID: UUID?

    /// What kind of drop a row is looking at, decided by the payload rather
    /// than by `draggingWorkspaceID`: the state can go stale (a cancelled
    /// reorder ends without any drop callback), and a stale ID once made a
    /// row read a folder registration as a reorder and swallow it.
    private enum DropKind {
        /// Carries file URLs — a folder (or file) on its way into the list.
        case fileRegistration
        /// No file URLs, and a reorder drag is genuinely in flight.
        case reorder
        /// Anything else — text dragged in from another app, say. Not ours.
        case foreign
    }

    private func kind(of info: DropInfo) -> DropKind {
        if info.hasItemsConforming(to: [.fileURL]) { return .fileRegistration }
        return draggingWorkspaceID != nil ? .reorder : .foreign
    }

    func dropEntered(info: DropInfo) {
        guard case .reorder = kind(of: info),
              let draggingWorkspaceID,
              draggingWorkspaceID != target.id,
              let fromIndex = model.workspaces.firstIndex(where: { $0.id == draggingWorkspaceID }),
              let toIndex = model.workspaces.firstIndex(where: { $0.id == target.id }) else {
            return
        }
        let destination = toIndex > fromIndex ? toIndex + 1 : toIndex
        model.moveWorkspace(fromOffsets: IndexSet(integer: fromIndex), toOffset: destination)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        switch kind(of: info) {
        case .reorder:
            // A reorder really does move something.
            DropProposal(operation: .move)
        case .fileRegistration:
            // Registering a folder takes nothing from the source app, and
            // `.move` is what tells a source its original is now someone
            // else's — Finder deletes the original once it hears that.
            DropProposal(operation: .copy)
        case .foreign:
            // Refuse outright. Accepting with `.move` — which these rows
            // once answered unconditionally — invites a text editor to
            // delete the dragged text the moment the drop lands here.
            DropProposal(operation: .cancel)
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        defer { draggingWorkspaceID = nil }
        switch kind(of: info) {
        case .reorder:
            return true
        case .fileRegistration:
            return registerDroppedFolders(info.itemProviders(for: [.fileURL]), model: model)
        case .foreign:
            return false
        }
    }
}

/// Registers dropped folders as workspaces. Shared by the sidebar as a whole
/// and by each row, so that a folder lands in the list wherever in the
/// sidebar it is let go of.
@MainActor
private func registerDroppedFolders(_ providers: [NSItemProvider], model: AppModel) -> Bool {
    // The pasteboard, not the providers, is what reliably carries the URLs —
    // see `draggedFileURLs`. A drag from the app's own browser arrives with
    // providers that cannot load a URL at all.
    let pasteboardURLs = draggedFileURLs()
    if !pasteboardURLs.isEmpty {
        model.addWorkspaces(at: pasteboardURLs)
        return true
    }

    // Providers as the fallback, for a drop whose pasteboard offers nothing
    // readable (and for tests that hand providers in directly).
    let loadable = providers.filter { $0.canLoadObject(ofClass: URL.self) }
    guard !loadable.isEmpty else { return false }

    Task {
        var collected: [URL] = []
        for provider in loadable {
            if let url = await loadURL(from: provider) {
                collected.append(url)
            }
        }
        guard !collected.isEmpty else { return }
        model.addWorkspaces(at: collected)
    }
    return true
}

@MainActor
private func loadURL(from provider: NSItemProvider) async -> URL? {
    await withCheckedContinuation { continuation in
        _ = provider.loadObject(ofClass: URL.self) { url, _ in
            continuation.resume(returning: url)
        }
    }
}
