# Workspace Shelf 개발 기획서

> macOS용 개인 파일 허브 앱  
> 작성일: 2026-07-30  
> 개발 방식: Codex 중심, Swift + SwiftUI + AppKit  
> 사용 목적: 김흥기 개인용  
> 배포 방식: 본인 Mac에서 직접 빌드하여 사용

---

## 1. 프로젝트 개요

### 1.1 프로젝트명

**Workspace Shelf**

임시 프로젝트명이다. 실제 앱 이름은 개발 중 변경할 수 있다.

후보:

- Workspace Shelf
- Folder Shelf
- Quick Folder
- File Deck
- My Folder Hub
- Notch Shelf

이 문서에서는 `Workspace Shelf`로 통일한다.

### 1.2 개발 목적

Finder 창을 반복해서 열고 작업 폴더를 찾아가는 과정을 줄인다.

화면 상단, 노치 아래 또는 전역 단축키로 작은 파일 패널을 열고, 자주 쓰는 프로젝트 폴더를 빠르게 탐색한다.

주요 사용 대상 폴더:

- Omni Workspace 개발 폴더
- Omni Mobile 개발 폴더
- 소설 집필 폴더
- Suno 음원 작업 폴더
- 유튜브 영상 제작 폴더
- Google Drive 동기화 폴더
- 한의원 문서 폴더

### 1.3 개발 원칙

이 앱은 판매용 제품이 아니라 개인용 도구다.

따라서 처음부터 다음 항목은 구현하지 않는다.

- 회원가입
- 로그인
- 서버
- 데이터베이스
- 결제
- 구독
- 앱스토어 등록
- 자동 업데이트 서버
- 다국어 지원
- 다른 사용자 환경 대응
- 복잡한 온보딩
- 분석 및 로그 수집
- Windows 지원
- iPhone 또는 iPad 지원

우선순위는 다음과 같다.

1. 실제로 매일 사용할 수 있는가
2. 파일을 빠르게 찾고 드래그할 수 있는가
3. 앱이 가볍고 즉시 열리는가
4. 설정이 단순한가
5. 문제가 생겨도 Finder 원본 파일에 영향을 최소화하는가

---

## 2. 핵심 사용자 시나리오

### 시나리오 A: 개발 폴더 열기

1. `Option + Space`를 누른다.
2. 화면 상단 중앙에 Workspace Shelf가 열린다.
3. `Omni` 워크스페이스를 선택한다.
4. `omni-workspace`, `omni-mobile`, `docs` 중 하나를 연다.
5. 파일을 더블클릭하거나 Finder 또는 Terminal에서 연다.

### 시나리오 B: 소설 회차 파일 열기

1. 전역 단축키로 패널을 연다.
2. `Novel` 워크스페이스를 선택한다.
3. `CHAPTERS` 폴더를 연다.
4. `CH021.md` 파일을 Typora에서 연다.

### 시나리오 C: Suno 음원 파일 이동

1. `Suno Downloads` 폴더를 연다.
2. 다운로드한 음원을 미리 듣거나 Quick Look으로 확인한다.
3. 선택한 파일을 `Selected Tracks` 폴더로 드래그한다.
4. 영상 편집 앱으로 파일을 직접 드래그한다.

### 시나리오 D: 이미지 파일 사용

1. YouTube 이미지 소스 폴더를 연다.
2. 이미지 파일을 미리본다.
3. 원하는 이미지를 ChatGPT, Canva, CapCut 또는 Finder로 드래그한다.

### 시나리오 E: 특정 폴더를 Terminal에서 열기

1. 프로젝트 폴더를 우클릭한다.
2. `Terminal에서 열기`를 선택한다.
3. 해당 경로를 작업 디렉터리로 하는 Terminal 창이 열린다.

---

## 3. 목표 기능 범위

## 3.1 MVP 필수 기능

첫 번째 실사용 버전에 반드시 포함한다.

### 앱 기본 동작

- 메뉴바 앱으로 실행
- Dock 아이콘 숨김 또는 설정으로 표시
- 앱 실행 시 메뉴바에 아이콘 표시
- 전역 단축키로 패널 열기/닫기
- 기본 단축키: `Option + Space`
- 패널 밖을 클릭하면 자동으로 닫기
- 패널 고정 기능
- 마지막 패널 크기와 위치 저장

### 폴더 등록

- macOS 폴더 선택창으로 폴더 등록
- 등록한 폴더 목록 저장
- 폴더 이름 사용자 지정
- 폴더별 아이콘 또는 색상 지정
- 등록 폴더 순서 변경
- 등록 폴더 삭제
- 원본 폴더는 삭제하지 않음
- 폴더 경로가 사라졌을 때 오류 표시

### 파일 탐색

- 폴더 내부 파일 및 하위 폴더 표시
- 하위 폴더 진입
- 뒤로 가기
- 상위 폴더 이동
- 현재 경로 표시
- 파일 이름 표시
- 파일 아이콘 표시
- 수정일 표시
- 파일 크기 표시
- 리스트 보기
- 아이콘 보기
- 이름순 정렬
- 수정일순 정렬
- 파일 종류별 정렬

### 파일 실행

- 더블클릭으로 기본 앱에서 열기
- 우클릭 후 기본 앱에서 열기
- `다음으로 열기` 메뉴
- Finder에서 보기
- Terminal에서 폴더 열기
- 파일 경로 복사
- 파일명 복사

### 드래그앤드롭

- 파일을 Workspace Shelf에서 외부 앱으로 드래그
- Finder로 드래그
- ChatGPT 업로드 영역으로 드래그
- CapCut 또는 영상 편집 앱으로 드래그
- 외부 파일을 현재 폴더로 드롭하여 복사
- `Option` 키를 누른 경우 복사 동작 명확화
- 동일 이름 파일 충돌 시 덮어쓰기 전에 확인

### 상태 저장

- 등록 폴더 목록 저장
- 마지막 선택 워크스페이스 저장
- 워크스페이스별 마지막 하위 경로 저장
- 정렬 기준 저장
- 보기 방식 저장
- 패널 크기 저장
- 패널 고정 여부 저장

---

## 3.2 2차 기능

MVP 안정화 후 추가한다.

### 미리보기

- Space 키로 Quick Look 실행
- 이미지 미리보기
- PDF 미리보기
- 텍스트 파일 미리보기
- Markdown 파일 미리보기
- 오디오 재생
- 동영상 썸네일
- 선택 파일의 기본 정보 패널

### 파일 관리

- 새 폴더 만들기
- 이름 변경
- 복사
- 붙여넣기
- 복제
- 휴지통으로 이동
- 여러 파일 선택
- 일괄 이동
- 일괄 복사
- 최근 파일
- 즐겨찾기 파일 및 폴더

### 검색

- 현재 폴더 검색
- 등록 워크스페이스 전체 검색
- 파일명 검색
- 확장자 필터
- 최근 수정 파일 필터
- Markdown, 이미지, 오디오, 동영상 빠른 필터

### 패널 UX

- 노치 아래 자동 배치
- 커서가 있는 모니터에 표시
- 다중 모니터 지원
- 전체화면 앱 위에 패널 표시
- 화면 상단 마우스 접근으로 열기
- 부드러운 열기/닫기 애니메이션
- 패널 투명도 설정
- 패널 폭과 높이 설정
- compact, normal, wide 크기 프리셋

---

## 3.3 장기 선택 기능

필요성이 확인된 경우에만 구현한다.

- 폴더별 사용자 지정 액션
- VS Code에서 열기
- Xcode에서 열기
- Typora에서 열기
- Obsidian에서 열기
- 특정 파일을 Codex 작업 폴더로 열기
- 선택 경로에서 새 Codex 세션 시작
- 폴더별 고정 명령어 실행
- Git 상태 표시
- 최근 커밋 표시
- 이미지 크기 표시
- 오디오 길이와 BPM 메모
- 파일 태그
- 워크스페이스별 메모
- 즐겨찾기 명령어
- 파일 이름 일괄 변경
- 지정 폴더 자동 정리

---

## 4. 제외 범위

초기 개발에서는 다음을 구현하지 않는다.

- Finder 완전 대체
- iCloud Drive 자체 동기화 기능
- Google Drive 자체 동기화 기능
- Dropbox 자체 동기화 기능
- NAS 전용 클라이언트
- FTP
- SFTP
- 클라우드 계정 로그인
- 파일 버전 관리
- 백업 기능
- 파일 복구 기능
- 관리자 권한이 필요한 시스템 폴더 조작
- 휴지통 비우기
- 파일 영구 삭제
- 앱스토어 샌드박스 배포
- 타인에게 배포하는 설치 프로그램

Google Drive는 Google Drive for desktop이 Finder에 연결한 로컬 경로를 일반 폴더처럼 등록하여 사용한다.

---

## 5. 기술 스택

## 5.1 언어 및 프레임워크

- Swift
- SwiftUI
- AppKit
- macOS 네이티브 앱
- Xcode 프로젝트
- Swift Package Manager

## 5.2 주요 macOS API

### UI

- `SwiftUI`
- `NSPanel`
- `NSWindow`
- `NSStatusItem` 또는 `MenuBarExtra`
- `NSHostingView`

### 파일

- `FileManager`
- `URL`
- `URLResourceValues`
- `NSWorkspace`
- `NSOpenPanel`
- `NSPasteboard`
- `NSItemProvider`

### 미리보기

- `QuickLook`
- `QLPreviewPanel`
- `QuickLookThumbnailing`

### 설정 저장

초기에는 다음 중 하나를 사용한다.

- `UserDefaults`
- JSON 설정 파일

추천 방식:

- 일반 설정: `UserDefaults`
- 등록 폴더 정보: JSON
- 보안 접근 권한: security-scoped bookmark

### 전역 단축키

다음 방식 중 하나를 선택한다.

- Carbon Hot Key API 래퍼
- 검증된 Swift Package
- 직접 NSEvent 감시

개인용 앱이므로 외부 패키지를 사용할 수 있지만, 유지보수가 중단된 패키지는 피한다.

---

## 6. 앱 아키텍처

```text
WorkspaceShelf
├── App
│   ├── WorkspaceShelfApp.swift
│   ├── AppDelegate.swift
│   └── AppEnvironment.swift
│
├── Core
│   ├── Models
│   │   ├── Workspace.swift
│   │   ├── FolderBookmark.swift
│   │   ├── FileItem.swift
│   │   ├── AppSettings.swift
│   │   └── ViewPreferences.swift
│   │
│   ├── Services
│   │   ├── FileSystemService.swift
│   │   ├── BookmarkService.swift
│   │   ├── SettingsService.swift
│   │   ├── QuickLookService.swift
│   │   ├── DragDropService.swift
│   │   ├── HotKeyService.swift
│   │   └── WorkspaceService.swift
│   │
│   └── Utilities
│       ├── URL+Extensions.swift
│       ├── FileSizeFormatter.swift
│       ├── DateFormatter+App.swift
│       └── Logger.swift
│
├── Features
│   ├── MenuBar
│   │   ├── MenuBarController.swift
│   │   └── MenuBarView.swift
│   │
│   ├── ShelfPanel
│   │   ├── ShelfPanelController.swift
│   │   ├── ShelfPanel.swift
│   │   └── PanelPositionCalculator.swift
│   │
│   ├── Workspaces
│   │   ├── WorkspaceSidebar.swift
│   │   ├── WorkspaceEditorView.swift
│   │   └── WorkspaceViewModel.swift
│   │
│   ├── Browser
│   │   ├── FileBrowserView.swift
│   │   ├── FileListView.swift
│   │   ├── FileGridView.swift
│   │   ├── FileRow.swift
│   │   ├── BreadcrumbView.swift
│   │   └── FileBrowserViewModel.swift
│   │
│   ├── Preview
│   │   ├── PreviewController.swift
│   │   └── FileInfoPanel.swift
│   │
│   └── Settings
│       ├── SettingsView.swift
│       ├── GeneralSettingsView.swift
│       ├── ShortcutSettingsView.swift
│       └── WorkspaceSettingsView.swift
│
├── Resources
│   ├── Assets.xcassets
│   └── AppIcon.appiconset
│
└── Tests
    ├── FileSystemServiceTests.swift
    ├── BookmarkServiceTests.swift
    └── WorkspaceServiceTests.swift
```

---

## 7. 로컬 프로젝트 폴더 설정

## 7.1 추천 상위 폴더

흥기님의 기존 개발 폴더 구조에 맞춰 다음 경로를 추천한다.

```text
~/Desktop/app-development/
├── omniai/
│   └── omni-workspace/
│
└── workspace-shelf/
```

Workspace Shelf 프로젝트의 최종 경로:

```text
~/Desktop/app-development/workspace-shelf
```

터미널에서 생성:

```bash
mkdir -p "$HOME/Desktop/app-development/workspace-shelf"
cd "$HOME/Desktop/app-development/workspace-shelf"
```

### 별도 폴더로 두는 이유

- Omni Workspace 저장소와 완전히 분리
- Swift/Xcode 프로젝트를 독립적으로 관리
- Git 이력 분리
- Codex 작업 범위 혼선 방지
- 나중에 프로젝트를 삭제하거나 이동하기 쉬움

---

## 7.2 Xcode 프로젝트 생성 방법

1. Xcode 실행
2. `Create New Project` 선택
3. 플랫폼에서 `macOS` 선택
4. `App` 선택
5. 다음 값 입력

```text
Product Name: WorkspaceShelf
Team: 본인 Apple Developer Team
Organization Identifier: com.rrllab
Interface: SwiftUI
Language: Swift
Testing System: Swift Testing 또는 XCTest
Storage: None
```

Bundle Identifier 예상값:

```text
com.rrllab.WorkspaceShelf
```

저장 위치:

```text
~/Desktop/app-development/workspace-shelf
```

중요:

Xcode가 다음처럼 폴더를 한 번 더 만들지 확인한다.

원하는 구조:

```text
~/Desktop/app-development/workspace-shelf/
├── WorkspaceShelf.xcodeproj
├── WorkspaceShelf/
└── WorkspaceShelfTests/
```

피해야 하는 중복 구조:

```text
~/Desktop/app-development/workspace-shelf/WorkspaceShelf/WorkspaceShelf/
```

프로젝트 생성 창에서 Git 저장소 생성 옵션은 켜도 된다. 다만 기존 폴더에서 별도로 Git을 초기화할 계획이면 끈다.

---

## 7.3 Git 초기 설정

Xcode가 Git을 만들지 않은 경우:

```bash
cd "$HOME/Desktop/app-development/workspace-shelf"
git init
git branch -M main
```

`.gitignore` 파일 생성:

```gitignore
# Xcode
DerivedData/
build/
*.xcuserstate
xcuserdata/
*.xccheckout
*.xcscmblueprint

# Swift Package Manager
.build/
.swiftpm/

# macOS
.DS_Store

# Local settings
.env
.env.*
local/
tmp/
logs/

# User generated test data
TestData/
```

첫 커밋:

```bash
git add .
git commit -m "chore: initialize Workspace Shelf macOS app"
```

GitHub 원격 저장소를 사용할 경우 비공개 저장소를 권장한다.

예상 저장소 이름:

```text
workspace-shelf
```

원격 연결 예시:

```bash
git remote add origin git@github.com:kimhung910924/workspace-shelf.git
git push -u origin main
```

---

## 7.4 Codex 작업 폴더 설정

Codex에서는 반드시 다음 폴더 자체를 작업 루트로 연다.

```text
~/Desktop/app-development/workspace-shelf
```

Omni Workspace의 상위 폴더나 `app-development` 전체를 열지 않는다.

이유:

- 다른 저장소 파일 오수정 방지
- 검색 범위 축소
- 토큰 사용 감소
- 빌드 명령 명확화
- Git 상태 혼선 방지

Codex가 처음 확인할 항목:

```bash
pwd
git status
find . -maxdepth 2 -type f | sort
xcodebuild -list
```

---

## 8. 프로젝트 내부 문서 폴더

프로젝트 루트에 개발 문서를 둔다.

```text
workspace-shelf/
├── AGENTS.md
├── README.md
├── docs/
│   ├── PRODUCT-SPEC.md
│   ├── ARCHITECTURE.md
│   ├── DEVELOPMENT-PLAN.md
│   ├── TEST-CHECKLIST.md
│   ├── CHANGELOG-DEV.md
│   └── DECISIONS.md
└── WorkspaceShelf/
```

이 기획서는 다음 파일로 저장한다.

```text
docs/PRODUCT-SPEC.md
```

현재 전달되는 파일을 프로젝트에 넣을 때는 파일명을 다음처럼 변경해도 된다.

```text
WORKSPACE-SHELF-기획서.md
```

추천 최종 위치:

```text
~/Desktop/app-development/workspace-shelf/docs/PRODUCT-SPEC.md
```

---

## 9. AGENTS.md 기본 지시문

프로젝트 루트의 `AGENTS.md`에 다음 원칙을 넣는다.

```markdown
# Workspace Shelf Agent Instructions

## Project

Workspace Shelf is a private macOS file panel app built with Swift, SwiftUI, and AppKit.

## Scope

- macOS only
- Personal use only
- No authentication
- No server
- No payment
- No analytics
- No App Store release requirements unless explicitly requested

## Development principles

1. Preserve user files.
2. Never permanently delete files.
3. File deletion must use the macOS Trash.
4. Confirm before overwriting an existing file.
5. Prefer native macOS APIs.
6. Keep dependencies minimal.
7. Do not modify unrelated files.
8. Run tests and build checks after implementation.
9. Keep changes small and commit-ready.
10. Document important architectural decisions.

## Required checks

Before editing:

- Run `git status`.
- Confirm the current branch.
- Inspect relevant files.
- Do not overwrite uncommitted user changes.

After editing:

- Run the relevant tests.
- Run a Debug build with `xcodebuild`.
- Summarize changed files.
- Report unresolved warnings or limitations.

## File safety

- Never implement permanent deletion.
- Move deleted files to Trash using native macOS APIs.
- Never recursively modify a directory without explicit instruction.
- Do not follow symbolic links during destructive operations.
- Treat Google Drive and cloud-backed files as potentially unavailable offline.

## Architecture

- SwiftUI for views.
- AppKit for NSPanel, menu bar, Quick Look, window positioning, and macOS-specific behavior.
- Services must own file-system and bookmark operations.
- Views must not directly perform destructive file operations.
```

---

## 10. 앱의 데이터 저장 위치

## 10.1 앱 설정

`UserDefaults`에 저장할 데이터:

- 전역 단축키
- 패널 크기
- 패널 위치 방식
- 마지막 선택 워크스페이스 ID
- 보기 방식
- 정렬 방식
- 패널 고정 여부
- 메뉴바 실행 여부
- 로그인 시 자동 실행 여부

## 10.2 등록 폴더 정보

추천 저장 위치:

```text
~/Library/Application Support/WorkspaceShelf/workspaces.json
```

예상 JSON 구조:

```json
{
  "version": 1,
  "workspaces": [
    {
      "id": "omni",
      "name": "Omni",
      "bookmarkId": "bookmark-omni",
      "icon": "hammer",
      "color": "blue",
      "sortOrder": 0,
      "lastRelativePath": "docs"
    }
  ]
}
```

실제 절대 경로 문자열을 그대로 영구 저장하기보다 security-scoped bookmark 데이터를 별도 저장한다.

## 10.3 로그

개발 중에만 다음 위치를 사용한다.

```text
~/Library/Logs/WorkspaceShelf/
```

릴리스 상태에서는 과도한 로그를 남기지 않는다.

파일명, 전체 경로 등 민감한 개인 정보가 로그에 계속 쌓이지 않도록 한다.

---

## 11. 최초 실행 시 등록할 워크스페이스

앱이 완성된 후 흥기님이 직접 폴더 선택창에서 등록한다.

앱 코드에 개인 경로를 하드코딩하지 않는다.

## 11.1 Omni

표시 이름:

```text
Omni
```

등록 대상 폴더:

```text
~/Desktop/app-development/omniai/omni-workspace
```

선택적으로 하위 폴더 바로가기:

```text
omni-windows
omni-mobile
omni-backend
docs
```

## 11.2 Workspace Shelf

표시 이름:

```text
Workspace Shelf
```

등록 대상:

```text
~/Desktop/app-development/workspace-shelf
```

## 11.3 Novel

실제 소설 프로젝트 위치에 맞춰 등록한다.

추천 예시:

```text
~/Library/CloudStorage/GoogleDrive-계정/My Drive/Novel
```

또는:

```text
~/Google Drive/My Drive/Novel
```

하위 구조 권장:

```text
Novel/
├── README.md
├── WORLD.md
├── CHARACTERS.md
├── TIMELINE.md
├── TERMS.md
├── IDEAS.md
└── CHAPTERS/
    ├── CH001.md
    ├── CH002.md
    └── ...
```

Google Drive의 정확한 실제 경로는 Finder에서 해당 폴더를 선택하여 등록한다. 경로를 직접 입력하지 않는다.

## 11.4 Suno

추천 기본 구조:

```text
Suno/
├── 00_PROMPTS/
├── 01_DOWNLOADS/
├── 02_REVIEW/
├── 03_SELECTED/
├── 04_NORMALIZED/
├── 05_VIDEO_SOURCE/
├── 06_RENDERED/
└── 07_ARCHIVE/
```

각 폴더 역할:

- `00_PROMPTS`: Suno 입력 프롬프트
- `01_DOWNLOADS`: Suno에서 내려받은 원본
- `02_REVIEW`: 청취 및 선별 대기
- `03_SELECTED`: 최종 선택 음원
- `04_NORMALIZED`: YouTube 음량 표준화 완료본
- `05_VIDEO_SOURCE`: 썸네일, 배경 이미지, 영상 소스
- `06_RENDERED`: 완성 영상
- `07_ARCHIVE`: 사용 완료 원본과 이전 버전

## 11.5 YouTube

추천 구조:

```text
YouTube/
├── CHANNELS/
├── THUMBNAILS/
├── IMAGES/
├── AUDIO/
├── PROJECTS/
├── EXPORTS/
└── UPLOADED/
```

## 11.6 Clinic

개인정보가 포함될 수 있으므로 Google Drive 공유 범위와 파일 권한에 주의한다.

추천 구조:

```text
Clinic/
├── PATIENT-GUIDES/
├── FORMS/
├── MARKETING/
├── PRODUCT-IMAGES/
├── INTERNAL/
└── ARCHIVE/
```

환자 개인 식별 정보가 포함된 파일을 테스트 데이터로 사용하지 않는다.

---

## 12. 패널 UI 설계

## 12.1 기본 레이아웃

```text
┌──────────────────────────────────────────────────────────┐
│ Omni          Search files...                  Pin  Gear │
├──────────────┬───────────────────────────────────────────┤
│ Omni         │ omni-workspace > docs                    │
│ Novel        ├───────────────────────────────────────────┤
│ Suno         │ Name              Modified        Size   │
│ YouTube      │ README.md         Today           12 KB  │
│ Clinic       │ AGENTS.md         Today            5 KB  │
│              │ docs/             Yesterday             │
│ + Add        │ omni-mobile/      Jul 25                │
└──────────────┴───────────────────────────────────────────┘
```

## 12.2 기본 크기

권장 기본값:

```text
Width: 760 pt
Height: 480 pt
Minimum Width: 520 pt
Minimum Height: 320 pt
```

compact 모드:

```text
Width: 520 pt
Height: 360 pt
```

wide 모드:

```text
Width: 980 pt
Height: 620 pt
```

## 12.3 패널 위치

1차 버전:

- 현재 마우스가 있는 화면의 상단 중앙
- 메뉴바 아래에 배치
- 화면 가장자리를 벗어나지 않음

2차 버전:

- 노치가 있는 MacBook에서는 노치 아래
- 노치가 없는 화면은 상단 중앙
- 사용자 지정 위치 지원

## 12.4 키보드 조작

- `Option + Space`: 열기/닫기
- `Esc`: 닫기
- `Command + F`: 검색
- `Command + 1`: 리스트 보기
- `Command + 2`: 아이콘 보기
- `Command + Up`: 상위 폴더
- `Command + Down` 또는 `Return`: 선택 항목 열기
- `Space`: Quick Look
- `Command + C`: 복사
- `Command + V`: 붙여넣기
- `Command + Delete`: 휴지통 이동
- `Command + Shift + N`: 새 폴더
- `Command + R`: 새로고침
- `Command + Option + C`: 경로 복사

---

## 13. 파일 안전 정책

이 프로젝트에서 가장 중요한 정책이다.

### 반드시 지킬 사항

- 영구 삭제 기능을 구현하지 않는다.
- 삭제는 항상 macOS 휴지통으로 보낸다.
- 덮어쓰기는 사용자 확인 후 실행한다.
- 복사 중 오류가 발생하면 원본을 건드리지 않는다.
- 이동 작업은 가능하면 안전한 파일 API를 사용한다.
- 심볼릭 링크를 따라가며 대량 삭제하지 않는다.
- 패키지 파일을 일반 폴더처럼 재귀 탐색하지 않는다.
- 권한이 없는 폴더는 오류로 처리한다.
- Google Drive 파일이 오프라인이면 명확히 표시한다.
- 파일 목록 로딩 중 파일 내용을 전부 읽지 않는다.
- 대용량 폴더는 비동기로 로딩한다.
- UI 스레드에서 무거운 파일 작업을 하지 않는다.

### 테스트 중 금지

- 실제 소설 원본 폴더에서 삭제 테스트
- 실제 Omni 저장소에서 이동 테스트
- 환자 자료 폴더에서 테스트
- Google Drive 중요 폴더에서 덮어쓰기 테스트

별도 테스트 폴더를 만든다.

```text
~/Desktop/WorkspaceShelf-TestData
```

테스트 구조:

```text
WorkspaceShelf-TestData/
├── Folder-A/
│   ├── sample.txt
│   ├── sample.md
│   └── sample.png
├── Folder-B/
└── Large-Folder/
```

---

## 14. 개발 브랜치 전략

개인용 프로젝트이므로 단순하게 운영한다.

```text
main
├── feature/app-shell
├── feature/workspace-bookmarks
├── feature/file-browser
├── feature/drag-and-drop
├── feature/quick-look
├── feature/file-actions
└── fix/...
```

규칙:

- `main`은 항상 빌드 가능한 상태 유지
- 기능 하나당 브랜치 하나
- 구현과 문서 변경을 같은 커밋에 과도하게 섞지 않음
- 큰 기능은 2~4개 커밋으로 분리
- 실사용 확인 전 main 병합 금지

---

## 15. 단계별 개발 계획

## Phase 0. 프로젝트 초기화

목표:

- Xcode 프로젝트 생성
- Git 초기화
- 문서 구조 생성
- 기본 빌드 성공
- 앱 실행 성공

완료 기준:

- 빈 SwiftUI macOS 앱 실행
- `xcodebuild` Debug 빌드 성공
- main 첫 커밋 완료

추천 커밋:

```text
chore: initialize Workspace Shelf macOS app
docs: add product specification and agent instructions
```

## Phase 1. 메뉴바와 패널

목표:

- 메뉴바 아이콘
- NSPanel 생성
- 전역 단축키
- 패널 열기/닫기
- 현재 모니터 상단 중앙 배치

완료 기준:

- 앱을 실행하면 메뉴바 아이콘 표시
- `Option + Space`로 패널 토글
- 외부 화면에서도 정상 위치
- ESC로 닫힘

추천 커밋:

```text
feat: add menu bar app and floating shelf panel
feat: add global shortcut and panel positioning
```

## Phase 2. 워크스페이스 등록

목표:

- 폴더 선택창
- 워크스페이스 추가/삭제/이름 변경
- security-scoped bookmark 저장
- 앱 재시작 후 접근 복원

완료 기준:

- 폴더 3개 이상 등록 가능
- 앱 재실행 후 유지
- 이동되거나 삭제된 폴더 오류 처리
- 권한 접근 실패 시 앱이 종료되지 않음

추천 커밋:

```text
feat: add persistent workspace bookmarks
feat: add workspace management UI
```

## Phase 3. 파일 브라우저

목표:

- 파일 목록
- 하위 폴더 탐색
- breadcrumb
- 정렬
- 리스트/아이콘 보기
- 기본 앱 열기
- Finder에서 보기

완료 기준:

- 파일과 폴더가 구분되어 표시
- 폴더 이동과 뒤로 가기 정상
- 대용량 폴더에서 UI 멈춤 최소화
- 파일 더블클릭 실행

추천 커밋:

```text
feat: implement workspace file browser
feat: add file sorting and view modes
```

## Phase 4. 드래그앤드롭

목표:

- 외부 앱으로 파일 드래그
- 외부 파일을 현재 폴더에 드롭
- 복사 상태 표시
- 이름 충돌 확인

완료 기준:

- Finder로 드래그 성공
- ChatGPT 파일 업로드 영역으로 드래그 성공
- 이미지 편집 앱으로 드래그 성공
- 외부 파일 드롭 복사 성공
- 원본 파일 보존 확인

추천 커밋:

```text
feat: add outbound file dragging
feat: add safe inbound file drop
```

## Phase 5. Quick Look과 파일 작업

목표:

- Space 미리보기
- 새 폴더
- 이름 변경
- 복사/붙여넣기
- 휴지통 이동
- 경로 복사

완료 기준:

- 이미지, PDF, Markdown 미리보기
- 파일 삭제 시 휴지통으로 이동
- 덮어쓰기 확인
- 여러 파일 선택 기본 지원

추천 커밋:

```text
feat: add Quick Look preview
feat: add safe file actions
```

## Phase 6. 실사용 최적화

목표:

- 노치 위치 보정
- 다중 모니터
- 전체화면 위 표시
- 검색
- 최근 파일
- 설정 화면
- 로그인 시 자동 실행

완료 기준:

- 흥기님 실제 작업 폴더 1주 이상 사용
- 파일 손상 없음
- 패널 호출 지연이 체감상 짧음
- 주요 오류 로그 정리

---

## 16. Codex 작업 진행 방식

한 번에 전체 앱을 만들어 달라고 지시하지 않는다.

기능 단위로 다음 순서로 진행한다.

1. 현재 코드와 Git 상태 확인
2. 구현 계획 작성
3. 관련 파일만 수정
4. 빌드
5. 테스트
6. 변경 사항 요약
7. 흥기님이 실기기에서 확인
8. 수정
9. 커밋

### Codex 첫 지시문 예시

```text
현재 저장소는 개인용 macOS 앱 Workspace Shelf 프로젝트다.

먼저 AGENTS.md와 docs/PRODUCT-SPEC.md를 읽고 프로젝트 구조를 점검해라.

이번 작업 범위는 Phase 1의 메뉴바 앱과 NSPanel 기반 플로팅 패널 구현이다.

요구사항:
- SwiftUI와 AppKit 사용
- 메뉴바 아이콘 표시
- Option + Space 전역 단축키로 패널 열기/닫기
- 패널은 현재 마우스가 위치한 모니터의 상단 중앙에 표시
- ESC로 닫기
- 패널 밖 클릭 시 닫기
- 패널은 일반 앱 위에 표시
- 아직 파일 탐색 기능은 구현하지 말 것
- 불필요한 외부 의존성은 추가하지 말 것

작업 전:
- git status 확인
- 현재 브랜치 확인
- xcodebuild -list 확인
- 관련 파일 구조 확인

작업 후:
- Debug 빌드 실행
- 가능한 테스트 실행
- 변경 파일과 구현 내용을 요약
- 미해결 경고를 보고
- 커밋은 하지 말 것
```

### Codex에 항상 포함할 문장

```text
현재 작업 범위를 벗어난 기능은 구현하지 마라.
기존 사용자 변경 사항을 덮어쓰지 마라.
파일 삭제는 구현하지 마라.
빌드가 실패하면 실패 원인을 숨기지 말고 정확히 보고하라.
```

---

## 17. 빌드 및 실행 명령

프로젝트와 Scheme 이름이 `WorkspaceShelf`인 경우:

### 프로젝트 정보 확인

```bash
cd "$HOME/Desktop/app-development/workspace-shelf"
xcodebuild -list -project WorkspaceShelf.xcodeproj
```

### Debug 빌드

```bash
xcodebuild \
  -project WorkspaceShelf.xcodeproj \
  -scheme WorkspaceShelf \
  -configuration Debug \
  -destination 'platform=macOS' \
  build
```

### 테스트

```bash
xcodebuild \
  -project WorkspaceShelf.xcodeproj \
  -scheme WorkspaceShelf \
  -destination 'platform=macOS' \
  test
```

### Xcode에서 열기

```bash
open WorkspaceShelf.xcodeproj
```

---

## 18. 앱 설치 방식

개인용 초기 단계에서는 Xcode에서 직접 실행한다.

안정화 후 Release 앱을 생성하여 `/Applications`에 넣는다.

예상 앱 위치:

```text
~/Library/Developer/Xcode/DerivedData/.../Build/Products/Release/WorkspaceShelf.app
```

복사:

```bash
cp -R "/실제/빌드/경로/WorkspaceShelf.app" "/Applications/"
```

주의:

정확한 DerivedData 경로는 빌드 환경에 따라 달라진다. 경로를 추측하지 말고 `xcodebuild -showBuildSettings` 또는 Finder에서 빌드 산출물을 확인한다.

---

## 19. macOS 권한 및 설정

필요할 수 있는 권한:

- 사용자 선택 폴더 접근
- 접근성 권한: 전역 단축키 구현 방식에 따라 필요할 수 있음
- 로그인 항목: 자동 실행 기능을 추가할 경우
- 파일 및 폴더 접근

개인용 앱이라도 전체 디스크 접근 권한을 기본 요구하지 않는다.

폴더 선택창으로 필요한 폴더만 등록하는 방식을 우선한다.

앱이 접근 권한을 잃으면 해당 워크스페이스 옆에 경고를 표시하고 `다시 연결` 버튼을 제공한다.

---

## 20. Google Drive 설정

### Google Drive for desktop 사용

1. Google Drive for desktop 설치
2. Finder 사이드바에서 Google Drive 확인
3. 실제 사용할 폴더를 Finder에서 열기
4. Workspace Shelf에서 `폴더 추가`
5. Finder에 표시된 Google Drive 폴더 선택

macOS에서 실제 경로가 다음과 비슷할 수 있다.

```text
~/Library/CloudStorage/GoogleDrive-이메일주소/My Drive/
```

하지만 경로 문자열은 계정과 설치 방식에 따라 달라질 수 있으므로 직접 입력하지 않는다.

### 스트리밍 파일 주의

Google Drive의 스트리밍 파일은 로컬에 실제 내용이 없을 수 있다.

따라서 앱은:

- 목록을 표시할 때 파일 전체를 읽지 않는다.
- 썸네일 요청을 과도하게 하지 않는다.
- 오프라인 파일 열기 실패를 정상 오류로 처리한다.
- 다운로드 중 상태를 표시할 수 있도록 한다.
- 파일 복사 중 네트워크 지연을 고려한다.

---

## 21. 실사용용 초기 설정 추천

앱 완성 후 다음 워크스페이스 순서로 등록한다.

```text
1. Omni
2. Workspace Shelf
3. Novel
4. Suno
5. YouTube
6. Clinic
7. Downloads
```

### Downloads 등록

다운로드 폴더:

```text
~/Downloads
```

용도:

- Suno 파일
- 이미지
- 압축 파일
- 임시 다운로드
- ChatGPT에서 받은 파일

다운로드 폴더는 파일이 많으므로 수정일 내림차순을 기본 정렬로 지정한다.

### 워크스페이스별 추천 보기

| 워크스페이스 | 기본 보기 | 기본 정렬 |
|---|---|---|
| Omni | 리스트 | 이름순 |
| Workspace Shelf | 리스트 | 이름순 |
| Novel | 리스트 | 이름순 |
| Suno | 리스트 | 수정일순 |
| YouTube | 아이콘 | 수정일순 |
| Clinic | 리스트 | 이름순 |
| Downloads | 리스트 | 수정일순 |

---

## 22. 테스트 체크리스트

### 패널

- [ ] 앱 실행 시 메뉴바 아이콘 표시
- [ ] 단축키로 패널 열림
- [ ] 단축키로 패널 닫힘
- [ ] ESC로 닫힘
- [ ] 외부 클릭으로 닫힘
- [ ] 패널 고정 시 외부 클릭으로 닫히지 않음
- [ ] 외부 모니터에서 정상 표시
- [ ] 전체화면 앱 위에서 정상 표시

### 워크스페이스

- [ ] 폴더 추가 가능
- [ ] 폴더 삭제 시 원본 폴더 유지
- [ ] 순서 변경 가능
- [ ] 이름 변경 가능
- [ ] 앱 재실행 후 유지
- [ ] Google Drive 폴더 등록 가능
- [ ] 권한이 끊긴 폴더 재연결 가능

### 파일 탐색

- [ ] 파일 목록 표시
- [ ] 하위 폴더 이동
- [ ] 상위 폴더 이동
- [ ] 뒤로 가기
- [ ] 숨김 파일 표시 설정
- [ ] 파일 정렬
- [ ] 대용량 폴더 로딩
- [ ] 한글 파일명 정상 표시
- [ ] 긴 파일명 말줄임 처리

### 파일 실행

- [ ] Markdown 파일 열기
- [ ] 이미지 열기
- [ ] PDF 열기
- [ ] 오디오 열기
- [ ] Finder에서 보기
- [ ] Terminal에서 열기
- [ ] 경로 복사

### 드래그앤드롭

- [ ] Finder로 드래그
- [ ] ChatGPT로 드래그
- [ ] CapCut으로 드래그
- [ ] 외부 파일을 폴더에 드롭
- [ ] 여러 파일 드래그
- [ ] 이름 충돌 확인
- [ ] 복사 실패 시 원본 유지

### 파일 관리

- [ ] 새 폴더
- [ ] 이름 변경
- [ ] 복사
- [ ] 붙여넣기
- [ ] 휴지통 이동
- [ ] Quick Look
- [ ] 여러 파일 선택

---

## 23. 완료 정의

MVP 완료 조건:

1. 앱을 부팅 후 매번 Xcode 없이 실행할 수 있다.
2. 메뉴바 또는 단축키로 1초 이내에 패널을 열 수 있다.
3. Omni, Novel, Suno 폴더를 등록할 수 있다.
4. 폴더를 탐색하고 파일을 열 수 있다.
5. 파일을 ChatGPT 또는 Finder로 드래그할 수 있다.
6. 외부 파일을 현재 폴더로 복사할 수 있다.
7. 앱 재시작 후 등록 폴더와 마지막 위치가 유지된다.
8. 파일 삭제는 휴지통만 사용한다.
9. 실제 파일 손상이나 유실이 없다.
10. Debug 및 Release 빌드가 성공한다.

---

## 24. 최종 개발 방향

Workspace Shelf는 Folder Hub의 모든 기능을 복제하는 프로젝트가 아니다.

흥기님이 실제로 반복하는 작업을 가장 빠르게 만드는 개인용 macOS 도구다.

첫 완성 목표는 다음 한 문장으로 정의한다.

> 전역 단축키를 누르면 자주 쓰는 작업 폴더가 즉시 열리고, 파일을 탐색하거나 다른 앱으로 드래그할 수 있는 가벼운 macOS 패널 앱.

초기 개발은 메뉴바, 플로팅 패널, 폴더 등록, 파일 탐색, 드래그앤드롭에 집중한다.

검색, Quick Look, 노치 자동 표시, 다중 모니터 최적화는 MVP가 안정적으로 동작한 이후 추가한다.
