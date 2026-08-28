# 변경 이력

형식은 [Keep a Changelog](https://keepachangelog.com/ko/1.1.0/)를 따르고,
버전은 [유의적 버전](https://semver.org/lang/ko/)을 따른다.

## [0.1.1] — 2026-08-28

### 더함

- **자동 업데이트(Sparkle).** 메뉴바 메뉴의 「업데이트 확인…」으로 직접 확인할 수도 있다.
  피드는 `rrllab.com`에 둔다 — 이 주소는 배포된 앱 안에 영구히 박히고 이미 깔린 앱이
  몇 년 뒤에도 계속 두드리므로, 호스팅을 갈아끼울 수 있는 자기 도메인이어야 한다.
- **앱 아이콘.** 응용 프로그램과 Spotlight에서 아이콘이 보인다.
- **배포 파이프라인.** Developer ID 서명 → 공증 → dmg → GitHub 릴리즈까지 한 줄로.
  자세한 건 [docs/RELEASING.md](docs/RELEASING.md).

### 바뀜

- `build-app.sh`가 서명 신원을 인자로 받는다(`WORKSPACE_SHELF_SIGN_IDENTITY`).
  중첩 Sparkle 구성요소가 ad-hoc으로 남으면 공증이 거절한다.
- README를 영어 기본으로 바꾸고 한국어는 `README.ko.md`로 분리했다.

## [0.1.0]

Phase 1 동작 조각. 구현·보류 범위는 `docs/DEVELOPMENT-PLAN.md`에 있다.

- 노치·메뉴바 아래 선반에 자주 쓰는 폴더를 놓는다
- 화면 위쪽 가운데 hover 또는 `Option + Space`로 연다
- 보안 스코프 북마크로 등록 폴더를 기억한다
- 파일 열기, Finder에서 보기, 터미널에서 열기, 경로 복사, 드래그 반출

[0.1.1]: https://github.com/kimhung910924/workspace-shelf/releases/tag/v0.1.1
