# Workspace Shelf

*[한국어](README.ko.md)*
*[Changelog](CHANGELOG.md)* · *[Releasing](docs/RELEASING.md)*

A tiny macOS app that parks your most-used folders on a shelf that slides down from under
the notch.

Move the pointer to the top center of the screen, or press `Option + Space`, and the shelf
comes down.

1.9 MB on disk, 100 MB resident. No Dock icon — it lives in the menu bar only.

- Register folders once and open them straight from the shelf
- Browse inside a registered folder without escaping its root
- Open files, reveal in Finder, open the folder in Terminal, copy the path
- Create folders, rename, copy and paste, move to Trash
- Quick Look with `Space`, filename search in the current folder
- Drag files out to Finder or any other app

## Download

**[Get Workspace Shelf 0.1.1 (dmg)](https://github.com/kimhung910924/workspace-shelf/releases/latest)**

- macOS 14 Sonoma or later
- Notarized by Apple, so it opens without a Gatekeeper warning
- Open the dmg and drag Workspace Shelf to `Applications`

## Contact

[rrllab.com](https://rrllab.com) · contact@rrllab.com

---

## Scope

Everything you reach for day to day works. What is still missing:

- dropping files **into** the shelf (inbound copy)
- workspace-wide search
- renaming and reordering workspaces
- launch at login, window size options

Per-item status is checkboxed in `docs/DEVELOPMENT-PLAN.md`; the implementation contract is
`docs/PRODUCT-SPEC.md`. The original planning document is
[WORKSPACE-SHELF-기획서.md](WORKSPACE-SHELF-기획서.md) (Korean).

Registered folders are remembered with security-scoped bookmarks, so access survives
relaunch without asking again.

## Requirements to build

- macOS 14 or later
- Xcode 16 or later
- Swift 6

## Run during development

```bash
swift run WorkspaceShelf
```

It runs as a menu bar accessory and shows no Dock icon.

## Test and build

```bash
swift test
swift build
```

## Build a local `.app`

```bash
./scripts/build-app.sh debug
open ".build/app/Workspace Shelf.app"
```

The bundle lands at `.build/app/Workspace Shelf.app`. It is not copied to `/Applications`
for you.

### Ship a release

```bash
./scripts/release.sh            # Developer ID signing, notarization, dmg
./scripts/release.sh --publish  # and upload to GitHub Releases
```
