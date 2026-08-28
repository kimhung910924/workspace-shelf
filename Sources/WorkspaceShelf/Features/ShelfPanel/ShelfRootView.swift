import SwiftUI

struct ShelfRootView: View {
    @ObservedObject var model: AppModel
    let closeAction: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ShelfToolbar(model: model, closeAction: closeAction)
            Divider()
            HStack(spacing: 0) {
                WorkspaceSidebar(model: model)
                    .frame(width: 176)
                Divider()
                FileBrowserView(model: model)
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.separator.opacity(0.55), lineWidth: 1)
        }
        .padding(1)
        .alert(
            "Workspace Shelf",
            isPresented: Binding(
                get: { model.errorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        model.clearError()
                    }
                }
            )
        ) {
            Button(L10n.t("확인", "OK"), role: .cancel) {
                model.clearError()
            }
        } message: {
            Text(model.errorMessage ?? "")
        }
        .alert(L10n.t("이름 변경", "Rename"), isPresented: $model.isRenameDialogPresented) {
            TextField(L10n.t("새 이름", "New Name"), text: $model.draftName)
            Button(L10n.t("취소", "Cancel"), role: .cancel) {
                model.cancelRename()
            }
            Button(L10n.t("변경", "Rename")) {
                model.confirmRename()
            }
        } message: {
            Text(L10n.t("같은 폴더 안에서 이름만 변경합니다.", "Only the name changes; the item stays in the same folder."))
        }
        .alert(L10n.t("새 폴더", "New Folder"), isPresented: $model.isNewFolderDialogPresented) {
            TextField(L10n.t("폴더 이름", "Folder Name"), text: $model.draftName)
            Button(L10n.t("취소", "Cancel"), role: .cancel) {
                model.cancelNewFolder()
            }
            Button(L10n.t("생성", "Create")) {
                model.confirmNewFolder()
            }
        } message: {
            Text(L10n.t("현재 폴더 안에 새 폴더를 만듭니다.", "Creates a new folder inside the current folder."))
        }
        .alert(L10n.t("휴지통으로 이동할까요?", "Move to Trash?"), isPresented: $model.isTrashConfirmationPresented) {
            Button(L10n.t("취소", "Cancel"), role: .cancel) {
                model.cancelMoveToTrash()
            }
            Button(L10n.t("휴지통으로 이동", "Move to Trash"), role: .destructive) {
                model.confirmMoveToTrash()
            }
        } message: {
            Text(L10n.t("\(model.trashTargetName)을(를) 휴지통으로 보냅니다. 영구 삭제하지 않으며 Finder에서 복원할 수 있습니다.", "Moves \(model.trashTargetName) to the Trash. Nothing is deleted permanently; you can restore it in Finder."))
        }
        .alert(L10n.t("같은 이름의 항목이 있습니다", "An Item with the Same Name Exists"), isPresented: $model.isPasteConflictPresented) {
            Button(L10n.t("취소", "Cancel"), role: .cancel) {
                model.cancelPasteConflict()
            }
            Button(L10n.t("새 이름으로 복사", "Copy with New Name")) {
                model.pasteWithRenamedCopies()
            }
        } message: {
            Text(L10n.t("기존 파일은 건드리지 않습니다. 복사본에 copy, copy 2 같은 이름을 붙입니다.", "Existing files are left untouched. Copies are named copy, copy 2, and so on."))
        }
    }
}

private struct ShelfToolbar: View {
    @ObservedObject var model: AppModel
    let closeAction: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Label(
                model.selectedWorkspace?.record.name ?? "Workspace Shelf",
                systemImage: "square.stack.3d.up.fill"
            )
            .font(.system(size: 14, weight: .semibold))
            .frame(minWidth: 112, alignment: .leading)

            Button(action: model.navigateBack) {
                Image(systemName: "chevron.left")
            }
            .disabled(!model.canNavigateBack)
            .help(L10n.t("뒤로", "Back"))
            .accessibilityLabel(L10n.t("뒤로", "Back"))

            Button(action: model.navigateUp) {
                Image(systemName: "arrow.up")
            }
            .disabled(!model.canNavigateUp)
            .help(L10n.t("상위 폴더", "Enclosing Folder"))
            .accessibilityLabel(L10n.t("상위 폴더", "Enclosing Folder"))

            Text(model.currentRelativePath)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)

            Picker(L10n.t("보기 방식", "View Mode"), selection: $model.viewMode) {
                ForEach(BrowserViewMode.allCases, id: \.self) { mode in
                    Image(systemName: mode.symbolName)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 96)
            .disabled(model.currentDirectoryURL == nil)
            .help(L10n.t("보기 방식", "View Mode"))
            .accessibilityLabel(L10n.t("보기 방식", "View Mode"))

            TextField(L10n.t("현재 폴더 검색", "Search Current Folder"), text: $model.searchQuery)
                .textFieldStyle(.roundedBorder)
                .frame(width: 155)
                .help(L10n.t("현재 폴더에서 파일명 검색", "Search file names in the current folder"))

            Button(action: model.beginNewFolder) {
                Image(systemName: "folder.badge.plus")
            }
            .disabled(model.currentDirectoryURL == nil)
            .help(L10n.t("새 폴더", "New Folder"))
            .accessibilityLabel(L10n.t("새 폴더", "New Folder"))

            Button(action: model.copySelectedFile) {
                Image(systemName: "doc.on.doc")
            }
            .disabled(model.selectedEntries.isEmpty)
            .help(L10n.t("선택 항목 복사", "Copy Selection"))
            .accessibilityLabel(L10n.t("선택 항목 복사", "Copy Selection"))

            Button(action: model.pasteIntoCurrentFolder) {
                Image(systemName: "clipboard")
            }
            .disabled(model.currentDirectoryURL == nil)
            .help(L10n.t("현재 폴더에 붙여넣기", "Paste into Current Folder"))
            .accessibilityLabel(L10n.t("현재 폴더에 붙여넣기", "Paste into Current Folder"))

            Button(role: .destructive, action: model.requestMoveSelectedToTrash) {
                Image(systemName: "trash")
            }
            .disabled(model.selectedEntries.isEmpty)
            .help(L10n.t("선택 항목을 휴지통으로 이동", "Move Selection to Trash"))
            .accessibilityLabel(L10n.t("선택 항목을 휴지통으로 이동", "Move Selection to Trash"))

            Button(action: model.refresh) {
                if model.isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .disabled(model.currentDirectoryURL == nil || model.isLoading)
            .help(L10n.t("새로고침", "Refresh"))
            .accessibilityLabel(L10n.t("새로고침", "Refresh"))

            Menu {
                Picker(L10n.t("정렬", "Sort By"), selection: $model.sortOption) {
                    ForEach(FileSortOption.allCases, id: \.self) { option in
                        Text(option.title).tag(option)
                    }
                }
                Divider()
                Toggle(L10n.t("오름차순", "Ascending"), isOn: $model.sortAscending)
            } label: {
                Image(systemName: "arrow.up.arrow.down")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .help(L10n.t("정렬", "Sort"))
            .accessibilityLabel(L10n.t("정렬", "Sort"))

            Menu {
                Picker(L10n.t("드래그 시 동작", "Drag Behavior"), selection: $model.dragOperation) {
                    ForEach(OutboundDragOperation.allCases, id: \.self) { operation in
                        Text(operation.menuTitle).tag(operation)
                    }
                }
            } label: {
                Image(systemName: "hand.draw")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            // The icon stays put and the tooltip carries the current choice:
            // a label that changed with the setting would shift everything
            // beside it in a toolbar this tight.
            .help(L10n.t("다른 앱으로 드래그할 때: \(model.dragOperation.shortTitle)", "When dragging to other apps: \(model.dragOperation.shortTitle)"))
            .accessibilityLabel(L10n.t("다른 앱으로 드래그할 때: \(model.dragOperation.shortTitle)", "When dragging to other apps: \(model.dragOperation.shortTitle)"))

            Button {
                model.isPinned.toggle()
            } label: {
                Image(systemName: model.isPinned ? "pin.fill" : "pin")
            }
            .help(model.isPinned ? L10n.t("고정 해제", "Unpin") : L10n.t("패널 고정", "Pin Panel"))
            .accessibilityLabel(model.isPinned ? L10n.t("고정 해제", "Unpin") : L10n.t("패널 고정", "Pin Panel"))

            Button(action: closeAction) {
                Image(systemName: "xmark")
            }
            .help(L10n.t("닫기", "Close"))
            .accessibilityLabel(L10n.t("닫기", "Close"))
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 16)
        .frame(height: 50)
    }
}
