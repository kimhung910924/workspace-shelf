# 변경 이력

형식은 [Keep a Changelog](https://keepachangelog.com/ko/1.1.0/)를 따르고,
버전은 [유의적 버전](https://semver.org/lang/ko/)을 따릅니다.

## [0.1.1] — 2026-08-28

### 더했습니다

- **자동 업데이트(Sparkle).** 새 버전이 나오면 앱이 알려드립니다. 메뉴바 메뉴의
  「업데이트 확인…」에서 직접 확인하실 수도 있습니다.
  업데이트 피드는 `rrllab.com`에 둡니다. 이 주소는 배포된 앱 안에 영구히 박히고
  이미 설치된 앱이 몇 년 뒤에도 계속 조회하기 때문에, 호스팅을 바꿀 수 있는
  자기 도메인이어야 합니다.
- **앱 아이콘.** 응용 프로그램과 Spotlight에서 아이콘이 표시됩니다.
- **배포 파이프라인.** Developer ID 서명부터 공증, dmg, GitHub 릴리즈까지 한 줄로
  이어집니다. 자세한 내용은 [docs/RELEASING.md](docs/RELEASING.md)에 있습니다.

### 바꿨습니다

- `build-app.sh`가 서명 신원을 인자로 받습니다(`WORKSPACE_SHELF_SIGN_IDENTITY`).
  중첩된 Sparkle 구성요소가 ad-hoc 서명으로 남으면 공증이 거절합니다.
- README를 영어 기본으로 바꾸고 한국어는 `README.ko.md`로 분리했습니다.

## [0.1.0]

첫 동작본입니다. 항목별 상태는 `docs/DEVELOPMENT-PLAN.md`에 있습니다.

- 노치와 메뉴바 아래 선반에 자주 쓰는 폴더를 놓아둡니다
- 화면 위쪽 가운데에 마우스를 올리거나 `Option + Space`로 엽니다
- 보안 스코프 북마크로 등록한 폴더를 기억합니다
- 파일 열기, Finder에서 보기, 터미널에서 열기, 경로 복사, 드래그로 반출

[0.1.1]: https://github.com/kimhung910924/workspace-shelf/releases/tag/v0.1.1
