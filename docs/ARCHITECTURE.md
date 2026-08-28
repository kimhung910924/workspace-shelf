# Workspace Shelf Architecture

## 1. Runtime shape

```text
NSApplication (.accessory)
├── AppDelegate
│   ├── AppModel
│   ├── ShelfPanelController
│   ├── StatusItemController
│   ├── GlobalHotKey
│   └── TopEdgeTriggerMonitor
│
├── WorkspaceStore
│   └── Application Support/WorkspaceShelf/workspaces.json
│
└── FileSystemService
    └── read-only URL metadata and NSWorkspace actions
```

The application owns one long-lived panel. Opening and closing changes its
visibility rather than creating a new window, keeping the browser state warm.

## 2. Layer responsibilities

### App

- configure `NSApplication` as an accessory app
- own process-lifetime controllers
- route menu bar, shortcut, and hover events
- stop security-scoped access on termination

### Core models

- persisted workspace metadata
- resolved workspace state
- file entry metadata
- sorting and browser preferences

Models do not open panels or mutate files.

### Services

#### WorkspaceStore

- choose the Application Support URL
- encode/decode versioned JSON
- create and resolve bookmarks
- perform atomic writes

#### FileSystemService

- enumerate one directory without recursion
- collect only required resource values
- open with `NSWorkspace`
- reveal in Finder
- open Terminal at a folder

#### GlobalHotKey

- register one Carbon hot key
- deliver only the matching command to the main actor
- unregister during teardown

### Features

#### ShelfPanel

- custom `NSPanel`
- current-display positioning
- outside-click and escape handling
- pin behavior

#### Workspaces

- folder selection
- sidebar selection
- remove registration without touching disk

#### Browser

- navigation history
- root containment
- asynchronous listing
- selection, context menu, and outbound drag

## 3. State ownership

`AppModel` is the single observable source for the first slice.

```text
AppModel
├── workspaces
├── selectedWorkspaceID
├── currentDirectoryURL
├── navigationHistory
├── entries
├── selectedEntryID
├── isLoading
├── errorMessage
├── sortDescriptor
└── isPinned
```

The panel controller owns visibility and geometry. Views do not call
`NSApplication` window APIs directly.

## 4. Navigation invariants

1. Every current directory belongs to the selected workspace root.
2. Selecting another workspace clears navigation history.
3. `navigateUp` is disabled at the workspace root.
4. A delayed directory response may update state only if its requested URL is
   still current.
5. Package directories are not entered by default.
6. Removing a selected workspace selects the next available workspace or shows
   the empty state.

## 5. Concurrency

Directory enumeration runs outside the main actor. The returned value is a
`Sendable` array of `FileEntry` values.

```text
user navigation
    ↓
capture request URL + request token
    ↓
Task.detached: FileManager enumeration
    ↓
MainActor: verify token and current URL
    ↓
publish entries or error
```

No file contents are read during enumeration.

## 6. Security-scoped bookmark lifecycle

```text
choose folder
    ↓
create bookmark data
    ↓
save record atomically
    ↓
resolve on launch
    ↓
startAccessingSecurityScopedResource()
    ↓
use while record is active
    ↓
stopAccessing on removal or termination
```

Resolution failures remain visible records so the user can reconnect them.

## 7. Panel geometry

`PanelPositionCalculator` receives an `NSScreen` visible frame and desired size.
It returns an origin:

```text
x = visibleFrame.midX - width / 2
y = visibleFrame.maxY - height - topGap
```

Both axes are clamped inside the visible frame. The pointer's screen is chosen
from `NSScreen.screens`; `NSScreen.main` is only a fallback.

## 8. Hot key choice

Carbon `RegisterEventHotKey` is used because:

- it captures the registered combination without logging all key input
- it does not require a third-party package
- it works while another application is active

The registration may fail if another app owns the shortcut. The menu bar and
hover triggers remain available, and a later settings UI will allow remapping.

## 9. File safety boundary

The initial `FileSystemService` exposes no delete, move, rename, overwrite, or
recursive mutation API. The compiler-level absence of those methods is part of
the safety model.

When write actions are added, they belong in a separate `FileOperationService`
with:

- preflight validation
- destination collision policy
- cancellable progress
- structured result per item
- Trash-only deletion
- dedicated tests using temporary directories

## 10. Packaging

Development uses Swift Package Manager. `scripts/build-app.sh`:

1. builds the executable
2. creates a local `.app` directory under `.build/app`
3. copies the binary
4. installs the repository `Info.plist`
5. signs locally with an ad-hoc signature when available

It never installs into `/Applications`. Distribution signing and notarization
are deliberately outside the first slice.

