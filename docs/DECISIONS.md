# Architecture Decisions

## ADR-001 — Native macOS application

- Status: accepted
- Decision: use SwiftUI and AppKit.
- Reason: the product depends on `NSPanel`, status items, screen geometry,
  Finder integration, file URLs, and system drag-and-drop.

## ADR-002 — Swift Package as the initial project

- Status: accepted
- Decision: start with a Swift Package executable instead of hand-authoring an
  `.xcodeproj`.
- Reason: it is reproducible from the command line, opens directly in Xcode,
  keeps project metadata small, and allows the first app slice to build now.
- Consequence: signing, entitlements, and a distributable application target
  will be formalized before the first installed release.

## ADR-003 — No third-party runtime dependencies

- Status: accepted
- Decision: use Carbon's registered hot-key API rather than a hot-key package.
- Reason: the API is small, avoids Input Monitoring for the default shortcut,
  and keeps a private utility easy to maintain.

## ADR-004 — Bookmark records, not hard-coded paths

- Status: accepted
- Decision: persist security-scoped bookmark data and user-facing metadata.
- Reason: selected folders may be renamed, mounted through Google Drive, or
  require renewed permission.

## ADR-005 — Read-only first slice

- Status: accepted
- Decision: the first slice browses, opens, reveals, copies path text, and
  supports outbound drag. It does not rename, move, delete, or copy files in.
- Reason: a file hub becomes useful before it becomes a file manager. This
  reduces the highest-risk part of the initial implementation.

## ADR-006 — Top-center trigger model

- Status: accepted
- Decision: opening can be triggered by `Option + Space`, the status item, or a
  short hover at the horizontal center of the current display's top edge.
- Reason: the notch interaction is the product's identity, while the keyboard
  shortcut remains the reliable fallback.
- Constraint: actual notch dimensions are not exposed as a stable public API.
  The first implementation uses the display's top-center safe region.

## ADR-007 — Safe write operations

- Status: accepted
- Decision: file writes are limited to one selected item at a time. Rename and
  new-folder creation reject invalid names and existing destinations; paste
  never overwrites and offers a renamed copy; deletion always goes through the
  macOS Trash after confirmation.
- Reason: the app is a fast-access tool, so avoiding irreversible outcomes is
  more important than matching every Finder operation in its first release.
