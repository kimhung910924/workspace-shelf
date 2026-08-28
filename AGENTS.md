# Workspace Shelf Agent Instructions

## Product boundary

Workspace Shelf is a private, macOS-only file hub. It opens as a lightweight
panel below the display notch or top menu bar and gives fast access to folders
chosen by the user.

- Personal use only
- SwiftUI for views and AppKit for macOS window behavior
- No server, account, analytics, payment, sync engine, or App Store work
- No hard-coded personal folder paths
- Keep external dependencies at zero unless the user approves one

## Safety

1. Preserve user files.
2. Never permanently delete a file.
3. If deletion is added later, it must use the macOS Trash.
4. Never overwrite an existing destination without explicit confirmation.
5. Do not recursively mutate registered folders.
6. Treat security-scoped bookmarks and cloud-backed files as fallible.
7. Never use real writing, production, clinic, or source repositories as
   destructive test data.

## Working rules

- Inspect `git status --short` before editing when this directory becomes a
  Git repository.
- Preserve unrelated and user-owned changes.
- Keep product behavior aligned with `docs/PRODUCT-SPEC.md`.
- Record architectural changes in `docs/DECISIONS.md`.
- Prefer small services with testable pure logic over file operations inside
  SwiftUI views.
- Do not commit or push unless explicitly requested.

## Required verification

For source changes, run:

```bash
swift test
swift build
```

When the packaged app script changes, also run:

```bash
./scripts/build-app.sh debug
```

Report anything that still requires physical interaction, especially:

- global hot key behavior
- notch hover behavior
- multi-display placement
- drag into another application
- security-scoped bookmark restoration after relaunch


## 현황판

작업 시작 전에 읽어라:
- `~/Desktop/status/STATUS.md`
- `~/Desktop/status/projects/mac-apps.md`

내가 **"인수인계"** 라고 하면 아래를 갱신해라:

1. `~/Desktop/status/projects/mac-apps.md`
   - 한 것 / 다음 할 것 / 막힌 것
   - 결정한 게 있으면 **이유까지** 적는다
2. `~/Desktop/status/STATUS.md` 의 해당 섹션
3. `~/Desktop/status/log.md` 에 append
   - 형식: `## [YYYY-MM-DD] 프로젝트명 | 한 줄 요약`
   - **기존 줄은 절대 수정하지 마라.** 추가만 한다.

짧게 써라. 버그 목록 같은 건 원본 경로만 가리키고 옮겨적지 마라.
