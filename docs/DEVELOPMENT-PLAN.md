# Development Plan

## Status legend

- `[x]` implemented in the initial code slice
- `[~]` foundation implemented; interactive verification remains
- `[ ]` not implemented

## Milestone 0 — Repository and executable

- [x] documentation structure
- [x] Swift Package executable
- [x] test target
- [x] local `.app` packaging script
- [ ] Git repository and first commit
- [ ] permanent Xcode app target, signing, and entitlements

Exit:

- `swift build` succeeds
- `swift test` succeeds
- packaged app launches locally

## Milestone 1 — Shelf shell

- [x] accessory app without Dock icon
- [x] status item
- [x] one reusable `NSPanel`
- [x] current-display top-center placement
- [x] `Option + Space` global hot key
- [x] `Escape` close
- [x] outside-click close
- [x] pin state
- [~] center-top hover trigger
- [ ] polished open/close animation
- [ ] settings UI for trigger sensitivity

Manual verification:

- shortcut while Finder, browser, and full-screen app are active
- hover on built-in display and external monitor
- menu bar click while the pointer is on a secondary display
- no unexpected close while a context menu is open

## Milestone 2 — Workspace registration

- [x] folder picker
- [x] default name from folder
- [x] security-scoped bookmark creation
- [x] versioned JSON persistence
- [x] bookmark restoration
- [x] remove registration without touching original folder
- [~] stale bookmark refresh
- [ ] rename workspace
- [ ] reorder workspaces
- [ ] reconnect inaccessible workspace
- [ ] choose icon and color

Manual verification:

- local folder survives relaunch
- Google Drive folder survives relaunch
- unavailable cloud volume does not crash the app
- removing a registration leaves the directory unchanged

## Milestone 3 — Read-only browser

- [x] asynchronous single-directory listing
- [x] folder/file separation
- [x] folders-first name sorting
- [x] modification date and size
- [x] enter folder
- [x] back and parent navigation
- [x] workspace root boundary
- [x] reload
- [x] default open
- [x] Finder reveal
- [x] Terminal open
- [x] copy path/name
- [x] outbound drag
- [ ] list/grid switch
- [ ] configurable sort
- [ ] restored last relative path
- [ ] multi-selection
- [ ] keyboard selection and Return

Manual verification:

- Hangul and long file names
- folders containing at least 1,000 entries
- `.app`, `.photoslibrary`, and other packages
- symlinks pointing inside and outside a workspace
- Finder, ChatGPT, Canva, and CapCut drag targets

## Milestone 4 — Safe inbound operations

- [ ] inbound file drop as copy
- [ ] collision dialog
- [ ] copy progress and cancellation
- [x] new folder
- [x] rename
- [x] clipboard copy/paste for a selected item
- [x] Trash-only deletion with confirmation

This milestone must use generated temporary test directories before any real
workspace. No write operation is approved merely because browsing works.

## Milestone 5 — Preview and discovery

- [x] selected file Quick Look with `Space`
- [x] filename search in current folder
- [ ] workspace-wide search
- [ ] image/PDF/audio metadata
- [ ] recent files
- [ ] favorites

## Milestone 6 — Daily-use hardening

- [ ] configurable global shortcut
- [ ] start at login
- [ ] compact/normal/wide sizes
- [ ] exact behavior across full-screen Spaces
- [ ] accessibility pass
- [ ] performance profiling
- [ ] 7-day real-use test
- [ ] signed Release app

## Next recommended implementation pass

Before adding file writes, complete Milestones 1–3 manually:

1. launch the packaged app
2. register a disposable test folder
3. test all three opening methods
4. relaunch and verify bookmark restoration
5. drag a test file into Finder and ChatGPT
6. record failures in `docs/TEST-CHECKLIST.md`
