# Workspace Shelf

Workspace Shelf is a private macOS utility that places frequently used folders
in a floating shelf below the notch or menu bar.

The first working slice is intentionally small:

- open from the center-top hover zone or `Option + Space`
- add folders with the macOS folder picker
- remember registered folders with security-scoped bookmarks
- browse folders without leaving the registered root
- open files, reveal them in Finder, open folders in Terminal, and copy paths
- drag files out to Finder or another application

The original planning document is preserved as
`WORKSPACE-SHELF-기획서.md`. The implementation contract is
`docs/PRODUCT-SPEC.md`.

## Requirements

- macOS 14 or later
- Xcode 16 or later
- Swift 6

## Run during development

```bash
swift run WorkspaceShelf
```

The process runs as a menu bar accessory and does not show a Dock icon.

## Test and build

```bash
swift test
swift build
```

## Create a local `.app`

```bash
./scripts/build-app.sh debug
open ".build/app/Workspace Shelf.app"
```

The app is written to `.build/app/Workspace Shelf.app`. It is not copied to
`/Applications` automatically.

## Current status

This repository contains the Phase 1 working slice, not the complete MVP.
See `docs/DEVELOPMENT-PLAN.md` for the exact implemented and deferred scope.

