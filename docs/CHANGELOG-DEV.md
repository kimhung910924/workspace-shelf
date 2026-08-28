# Development Changelog

## 2026-07-30

- Reframed the original plan into a focused implementation contract.
- Added architecture, milestone, test, and decision documents.
- Added the initial SwiftUI/AppKit application structure.
- Added menu bar, floating panel, global hot key, top-center hover trigger,
  folder registration, bookmark persistence, basic browsing, file actions, and
  outbound drag support.

## 2026-07-31

- Reworked the top-center trigger to poll the pointer position instead of
  depending on global `mouseMoved` delivery.
- Added Space-key Quick Look preview for selected files.
- Added safe file-management actions: new folder, rename, copy/paste with
  conflict-safe renamed copies, and confirmed move-to-Trash.
- Added current-folder filename filtering and file-operation tests.

## 2026-08-01

- Made an outbound drag actually move the file. The receiver reporting
  `NSDragOperationMove` means the *source* owes the removal, and nothing was
  doing it; the originals now go to the Trash rather than being unlinked,
  since the receiver's report cannot be verified.
- Fixed the removal hitting the wrong file: reading the pasteboard back at
  session end returns AppKit's staged copy, so the real URLs are recorded as
  the drag begins instead.
- Fixed dropped files gaining a second extension (`note.md.md`).
  `suggestedName` takes a base name, and the receiver appends the extension
  belonging to the registered content type.
- Removed the temporary drag file log; kept os_log lines only for the two
  silent failures (hook not installed, original not trashed).
- Added the move/copy drag setting to the panel toolbar, alongside the
  existing status-item menu.
- Accepted files dragged in from Finder in the list and icon views, not only
  the column view, including onto the empty-folder state.
- Allowed dropping onto a folder row to file items straight into that folder,
  and blocked dropping a folder into itself.

## 2026-08-02

- Fixed a drop onto a sidebar row vanishing. A Markdown or text file's drag
  conforms to `.text`, which is what the rows listen for to reorder
  themselves, and a row cannot decline a drop and leave it to the sidebar
  underneath. Rows now take file URLs too and register the folder.
- Stopped a sidebar row answering `.move` to a dropped file. Registering a
  folder takes nothing away from the source app, and `.move` is what tells a
  source its original is now someone else's to keep.
- Stopped registered folders being lost on every rebuild. The bookmarks were
  security-scoped, which binds them to the code signature that wrote them,
  and the ad-hoc signature changes with each build; the scoping bought
  nothing, since the app is not sandboxed. Plain bookmarks now, and folders
  registered by earlier builds resolve without migration.
- Fixed the list view's column header sliding into the middle of the panel
  for an empty folder: the compact empty state let the whole stack be centred
  vertically, so the browsing area now claims its full height.
- Said something when a search matches nothing, rather than leaving a blank
  listing that looks the same as a search that never ran.

Full-codebase bug sweep, same day:

- Let the search box accept the space bar, Return, and ⌘⌫ as *text* keys.
  The panel's key monitor swallowed Space outright (typing a space in the
  search field did nothing), opened the selected file on Return, and turned
  ⌘⌫ — delete-to-line-start while editing — into a Trash confirmation.
- Made a sidebar row decide what a drop *is* by its payload, not by the
  "which row is being reordered" state: that state outlives a reorder drag
  that ends nowhere (Esc, or let go outside the sidebar), and while stale it
  dimmed the row forever, reordered the list as unrelated file drags passed
  over rows, and swallowed folder registrations. The drag-source hook now
  posts a session-ended notification, the one reliable end-of-drag signal
  SwiftUI's onDrag lacks, and the sidebar clears its state on it.
- Stopped workspace rows accepting foreign drags (text from another app)
  with `.move` — an editor hearing `.move` may delete the dragged text. Such
  drops are now refused.
- Made Option-dropping an item into its own folder duplicate it ("이름
  copy"), matching Finder and this app's own paste-in-place; as a plain move
  it stays a no-op. The same-folder check also compares paths now, since URL
  equality tells /Notes and /Notes/ apart and the trailing slash depends on
  which API produced the URL.
