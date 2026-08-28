# Workspace Shelf Test Checklist

## Test data

Use only a disposable directory:

```text
~/Desktop/WorkspaceShelf-TestData/
├── Folder A/
│   ├── sample.txt
│   ├── sample.md
│   └── nested/
├── Empty Folder/
└── 한글 폴더/
    └── 아주 긴 파일 이름 테스트 문서.md
```

Do not use a real novel, source repository, Suno archive, or clinic directory
for write-operation testing.

## Automated

- [ ] `swift test`
- [ ] `swift build`
- [ ] `swift build -c release`
- [ ] `./scripts/build-app.sh debug`
- [ ] `./scripts/build-app.sh release`

## Launch and lifecycle

- [ ] packaged app opens without a Dock icon
- [ ] status item appears
- [ ] status menu opens
- [ ] Quit exits cleanly
- [ ] relaunch does not create duplicate status items or panels

## Shelf triggers

- [ ] status item toggles the Shelf
- [ ] `Option + Space` opens it while another app is active
- [ ] `Option + Space` closes it
- [ ] `Escape` closes it
- [ ] top-center hover opens it after a deliberate pause
- [ ] quickly crossing the top center does not open it
- [ ] hover can open it again after closing

## Panel geometry

- [ ] built-in display placement
- [ ] external display placement
- [ ] pointer display wins over primary display
- [ ] panel stays inside a narrow display
- [ ] panel appears below the visible menu-bar/notch area
- [ ] panel participates in full-screen Spaces as intended

## Dismissal and pin

- [ ] outside click closes when unpinned
- [ ] inside click does not close
- [ ] context menu does not cause premature close
- [ ] folder picker does not cause premature close
- [ ] pin keeps Shelf open on outside click
- [ ] Escape closes even when pinned

## Workspace registration

- [ ] Add Folder opens a directory-only picker
- [ ] cancel changes nothing
- [ ] selected folder appears and becomes active
- [ ] duplicate selection is handled predictably
- [ ] remove registration leaves the folder on disk
- [ ] local folder restores after relaunch
- [ ] Google Drive folder restores after relaunch
- [ ] **every folder still restores after a rebuild**, not merely a relaunch
      of the same binary — this is what security-scoped bookmarks used to
      break, and only a rebuild shows it
- [ ] missing folder shows an error instead of crashing
- [ ] a folder that really was deleted still shows the warning and can be
      removed from the list

## Browser

- [ ] folders appear before files
- [ ] names use natural localized ordering
- [ ] modification dates are readable
- [ ] folders do not show a misleading size
- [ ] entering a subfolder works
- [ ] Back returns to the previous folder
- [ ] Up stops at the workspace root
- [ ] Refresh updates created/removed test files
- [ ] empty folder state is clear
- [ ] in list view, an empty folder keeps the column header at the top
      instead of floating it into the middle of the panel
- [ ] a search matching nothing says so and quotes what was typed
- [ ] its "검색어 지우기" button restores the full listing
- [ ] an empty folder still reads as empty, not as a failed search, while
      something is typed in the search box
- [ ] 1,000-entry folder does not freeze panel opening
- [ ] a package opens as an item, not as an ordinary folder

## File actions

- [ ] double-click file opens default app
- [ ] Reveal in Finder selects a file
- [ ] Reveal in Finder opens a folder
- [ ] Open in Terminal uses the selected folder
- [ ] Open in Terminal uses a file's containing folder
- [ ] Copy Path puts the full path on clipboard
- [ ] Copy Name puts only the last path component on clipboard

## Outbound drag

- [ ] file drags to Finder
- [ ] file drags to ChatGPT upload
- [ ] image drags to Canva or a browser upload field
- [ ] audio drags to CapCut or another editor
- [ ] drag to Finder on the same volume moves the file, and the row leaves
      the listing on its own
- [ ] drag to Finder on another volume copies it, original stays
- [ ] drag to an upload area copies it, original stays
- [ ] the dropped file keeps its original name
- [ ] the dropped file's extension is not doubled (`note.md`, never
      `note.md.md`) — check a `.md`, a `.png`, and a `.tar.gz`
- [ ] a moved original lands in the Trash and can be put back
- [ ] a file with no extension survives the drag with its name intact

## Drag behavior setting

- [ ] the hand icon in the panel toolbar opens the move/copy menu
- [ ] the current choice is checked in that menu
- [ ] hovering the icon names the current choice
- [ ] changing it in the toolbar also changes the status-item menu, and the
      reverse
- [ ] the choice survives a relaunch
- [ ] with Copy selected, dragging to Finder leaves the original in place

## Inbound drop (Finder to Shelf)

Pin the Shelf first — an unpinned panel hides as soon as Finder takes focus.

- [ ] dropping a Finder file onto the list view moves it into the open folder
- [ ] the same works in icon view
- [ ] the same works in column view
- [ ] dropping onto an empty folder's "this folder is empty" state works
- [ ] the listing updates on its own, with no Refresh needed
- [ ] Option held at drop copies instead of moving, original stays in Finder
- [ ] dropping onto a *folder row* puts the files inside that folder, not
      the folder being browsed
- [ ] the targeted folder row highlights while dragging over it
- [ ] dragging over a file row highlights the whole area instead, and the
      drop lands in the open folder
- [ ] dropping a folder onto its own row does nothing and shows no error
- [ ] dropping several files at once moves all of them
- [ ] dropping a file that is already in the destination does nothing
- [ ] a drop from a read-only location reports an error rather than failing
      silently

## Folder registration by drag

- [ ] dragging a folder from the browser onto the sidebar registers it
- [ ] the same works when let go of directly on top of an existing workspace
      row, not only on empty sidebar space
- [ ] a folder dragged from Finder onto the sidebar registers too
- [ ] dropping a *file* on the sidebar says folders only, and registers
      nothing
- [ ] dropping a `.md` file on a workspace row gives that same message rather
      than silently doing nothing
- [ ] the registered folder opens and browses normally
- [ ] it survives a relaunch
- [ ] reordering the sidebar by dragging a row still works
- [ ] a folder registered this way is still on disk afterwards, in its
      original location

## Bug-sweep regressions (2026-08-02)

- [ ] a space can be typed into the search box
- [ ] Return while typing in the search box does not open the selected file
- [ ] ⌘⌫ while typing in the search box edits text, no Trash dialog
- [ ] with no text field focused, Space previews, Return opens, ⌘⌫ asks to
      trash — all still work
- [ ] start reordering a sidebar row, press Esc mid-drag: the row undims
- [ ] after that cancelled reorder, dragging a file from Finder across the
      sidebar rows does not shuffle the workspace order
- [ ] and dropping a folder on a row right after still registers it
- [ ] dragging selected text from a text editor onto a workspace row is
      refused, and the editor keeps its text
- [ ] Option-dropping a file into the folder it is already in creates
      "이름 copy", and a plain drop there does nothing

## Accessibility

- [ ] all toolbar icons have VoiceOver labels
- [ ] disabled controls are announced as disabled
- [ ] selected workspace is not indicated by color alone
- [ ] keyboard focus remains usable after opening
- [ ] text remains legible in light and dark mode

## Result log

| Date | Build | Mac/display | Result | Notes |
|---|---|---|---|---|
|  |  |  |  |  |

