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
            Button("확인", role: .cancel) {
                model.clearError()
            }
        } message: {
            Text(model.errorMessage ?? "")
        }
        .alert("이름 변경", isPresented: $model.isRenameDialogPresented) {
            TextField("새 이름", text: $model.draftName)
            Button("취소", role: .cancel) {
                model.cancelRename()
            }
            Button("변경") {
                model.confirmRename()
            }
        } message: {
            Text("같은 폴더 안에서 이름만 변경합니다.")
        }
        .alert("새 폴더", isPresented: $model.isNewFolderDialogPresented) {
            TextField("폴더 이름", text: $model.draftName)
            Button("취소", role: .cancel) {
                model.cancelNewFolder()
            }
            Button("생성") {
                model.confirmNewFolder()
            }
        } message: {
            Text("현재 폴더 안에 새 폴더를 만듭니다.")
        }
        .alert("휴지통으로 이동할까요?", isPresented: $model.isTrashConfirmationPresented) {
            Button("취소", role: .cancel) {
                model.cancelMoveToTrash()
            }
            Button("휴지통으로 이동", role: .destructive) {
                model.confirmMoveToTrash()
            }
        } message: {
            Text("\(model.trashTargetName)을(를) 휴지통으로 보냅니다. 영구 삭제하지 않으며 Finder에서 복원할 수 있습니다.")
        }
        .alert("같은 이름의 항목이 있습니다", isPresented: $model.isPasteConflictPresented) {
            Button("취소", role: .cancel) {
                model.cancelPasteConflict()
            }
            Button("새 이름으로 복사") {
                model.pasteWithRenamedCopies()
            }
        } message: {
            Text("기존 파일은 건드리지 않습니다. 복사본에 copy, copy 2 같은 이름을 붙입니다.")
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
            .help("뒤로")
            .accessibilityLabel("뒤로")

            Button(action: model.navigateUp) {
                Image(systemName: "arrow.up")
            }
            .disabled(!model.canNavigateUp)
            .help("상위 폴더")
            .accessibilityLabel("상위 폴더")

            Text(model.currentRelativePath)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)

            Picker("보기 방식", selection: $model.viewMode) {
                ForEach(BrowserViewMode.allCases, id: \.self) { mode in
                    Image(systemName: mode.symbolName)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 96)
            .disabled(model.currentDirectoryURL == nil)
            .help("보기 방식")
            .accessibilityLabel("보기 방식")

            TextField("현재 폴더 검색", text: $model.searchQuery)
                .textFieldStyle(.roundedBorder)
                .frame(width: 155)
                .help("현재 폴더에서 파일명 검색")

            Button(action: model.beginNewFolder) {
                Image(systemName: "folder.badge.plus")
            }
            .disabled(model.currentDirectoryURL == nil)
            .help("새 폴더")
            .accessibilityLabel("새 폴더")

            Button(action: model.copySelectedFile) {
                Image(systemName: "doc.on.doc")
            }
            .disabled(model.selectedEntries.isEmpty)
            .help("선택 항목 복사")
            .accessibilityLabel("선택 항목 복사")

            Button(action: model.pasteIntoCurrentFolder) {
                Image(systemName: "clipboard")
            }
            .disabled(model.currentDirectoryURL == nil)
            .help("현재 폴더에 붙여넣기")
            .accessibilityLabel("현재 폴더에 붙여넣기")

            Button(role: .destructive, action: model.requestMoveSelectedToTrash) {
                Image(systemName: "trash")
            }
            .disabled(model.selectedEntries.isEmpty)
            .help("선택 항목을 휴지통으로 이동")
            .accessibilityLabel("선택 항목을 휴지통으로 이동")

            Button(action: model.refresh) {
                if model.isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .disabled(model.currentDirectoryURL == nil || model.isLoading)
            .help("새로고침")
            .accessibilityLabel("새로고침")

            Menu {
                Picker("정렬", selection: $model.sortOption) {
                    ForEach(FileSortOption.allCases, id: \.self) { option in
                        Text(option.title).tag(option)
                    }
                }
                Divider()
                Toggle("오름차순", isOn: $model.sortAscending)
            } label: {
                Image(systemName: "arrow.up.arrow.down")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .help("정렬")
            .accessibilityLabel("정렬")

            Menu {
                Picker("드래그 시 동작", selection: $model.dragOperation) {
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
            .help("다른 앱으로 드래그할 때: \(model.dragOperation.shortTitle)")
            .accessibilityLabel("다른 앱으로 드래그할 때: \(model.dragOperation.shortTitle)")

            Button {
                model.isPinned.toggle()
            } label: {
                Image(systemName: model.isPinned ? "pin.fill" : "pin")
            }
            .help(model.isPinned ? "고정 해제" : "패널 고정")
            .accessibilityLabel(model.isPinned ? "고정 해제" : "패널 고정")

            Button(action: closeAction) {
                Image(systemName: "xmark")
            }
            .help("닫기")
            .accessibilityLabel("닫기")
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 16)
        .frame(height: 50)
    }
}
