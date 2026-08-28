# Workspace Shelf

*[English](README.md)*
*[변경 이력](CHANGELOG.md)* · *[릴리즈 방법](docs/RELEASING.md)*

노치와 메뉴바 아래에 떠 있는 선반에 자주 쓰는 폴더를 놓아두는 초경량 macOS 앱입니다.

화면 위쪽 가운데로 마우스를 올리시거나 `Option + Space`를 누르시면 선반이 내려옵니다.
앱은 1.9MB, 상주 메모리는 100MB입니다. Dock 아이콘 없이 메뉴바에만 있습니다.

- 폴더를 등록해 두고 선반에서 바로 엽니다
- 등록한 폴더 안에서만 돌아다닙니다
- 파일 열기, Finder에서 보기, 터미널에서 폴더 열기, 경로 복사를 지원합니다
- 새 폴더 만들기, 이름 변경, 복사·붙여넣기, 휴지통으로 삭제까지 됩니다
- `Space`로 Quick Look 미리보기, 현재 폴더 안에서 이름 검색
- Finder나 다른 앱으로 파일을 끌어다 놓을 수 있습니다

## 다운로드

**[Workspace Shelf 0.1.1 내려받기 (dmg)](https://github.com/kimhung910924/workspace-shelf/releases/latest)**

- macOS 14 Sonoma 이상이 필요합니다
- Apple 공증을 마쳤습니다. 경고 없이 바로 열립니다
- dmg를 열고 Workspace Shelf를 `응용 프로그램`으로 끌어다 놓으시면 됩니다

## 문의

[rrllab.com](https://rrllab.com) · contact@rrllab.com

---

기획서는 [WORKSPACE-SHELF-기획서.md](WORKSPACE-SHELF-기획서.md), 구현 계약은
`docs/PRODUCT-SPEC.md`에 있습니다.

## 개발

### 요구 사항

- macOS 14 이상
- Xcode 16 이상
- Swift 6

### 개발 중 실행

```bash
swift run WorkspaceShelf
```

Dock 아이콘 없이 메뉴바 액세서리로 실행됩니다.

### 테스트와 빌드

```bash
swift test
swift build
```

### 로컬 `.app` 만들기

```bash
./scripts/build-app.sh debug
open ".build/app/Workspace Shelf.app"
```

`.build/app/Workspace Shelf.app`에 만들어집니다. `/Applications`로 복사하지는 않습니다.

### 배포본 만들기

```bash
./scripts/release.sh            # 서명, 공증, dmg
./scripts/release.sh --publish  # GitHub 릴리즈 업로드까지
```

### 현재 범위

일상적으로 쓰시는 동작은 모두 됩니다. 아직 없는 것은 아래와 같습니다.

- 선반 **안으로** 파일을 끌어다 넣기(복사)
- 워크스페이스 전체 검색
- 워크스페이스 이름 변경과 순서 변경
- 로그인 시 자동 실행, 창 크기 옵션

항목별 상태는 `docs/DEVELOPMENT-PLAN.md`에 체크박스로 정리해 두었습니다.
