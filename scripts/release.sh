#!/bin/bash
# Developer ID 서명 → 공증 → DMG → 배포 판정까지 한 번에.
#
# scripts/build-app.sh는 **개발용**이다 — ad-hoc 서명(`-`)이라 남의 맥에서 안 열린다.
# 배포하려면 Developer ID 인증서 + 하드닝 런타임 + 애플 공증 티켓이 필요하고,
# 티켓은 앱과 dmg **양쪽에** 박아야 한다(사용자는 dmg를 먼저 연다 —
# omni-windows/scripts/notarize-dmg.sh 2026-08-24 실측).
#
# 사용법:
#   ./scripts/release.sh            # dmg까지
#   ./scripts/release.sh --publish  # GitHub 릴리즈 업로드까지
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="Workspace Shelf"
ASSET_NAME="WorkspaceShelf"          # 파일명에 공백을 넣지 않는다(다운로드 URL)
IDENTITY="Developer ID Application: RRLLAB (D9FZ6BL5FD)"
SECRETS="${NOTARIZE_ENV:-$HOME/Desktop/app-development/omniai/_secrets/notarize.env}"

APP=".build/app/${APP_NAME}.app"
DIST="dist"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Resources/Info.plist)"
DMG="${DIST}/${ASSET_NAME}-${VERSION}.dmg"
ZIP="${DIST}/${ASSET_NAME}-${VERSION}.zip"

PUBLISH=0
[ "${1:-}" = "--publish" ] && PUBLISH=1

[ -f "$SECRETS" ] || { echo "공증 자격 증명이 없다: $SECRETS" >&2; exit 1; }
set -a; source "$SECRETS"; set +a
: "${APPLE_API_KEY:?notarize.env에 APPLE_API_KEY가 없다}"
: "${APPLE_API_KEY_ID:?notarize.env에 APPLE_API_KEY_ID가 없다}"
: "${APPLE_API_ISSUER:?notarize.env에 APPLE_API_ISSUER가 없다}"

notarize() {
    xcrun notarytool submit "$1" \
        --key "$APPLE_API_KEY" --key-id "$APPLE_API_KEY_ID" --issuer "$APPLE_API_ISSUER" \
        --wait --output-format json
}

echo "==> ${APP_NAME} ${VERSION} 릴리즈"

echo "==> 테스트"
swift test 2>&1 | tail -3

rm -rf "$APP"
./scripts/build-app.sh release >/dev/null

echo "==> Developer ID 서명 (하드닝 런타임 + 타임스탬프)"
codesign --force --options runtime --timestamp --sign "$IDENTITY" "$APP"
codesign --verify --strict --verbose=2 "$APP"

mkdir -p "$DIST"
rm -f "$ZIP" "$DMG"
echo "==> 앱 공증"
ditto -c -k --keepParent "$APP" "$ZIP"
notarize "$ZIP"
xcrun stapler staple "$APP"

echo "==> dmg 생성"
STAGE="$(mktemp -d)"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "$APP_NAME" -srcfolder "$STAGE" -ov -format UDZO -quiet "$DMG"
rm -rf "$STAGE"

echo "==> dmg 서명·공증"
codesign --sign "$IDENTITY" --timestamp -f "$DMG"
notarize "$DMG"
xcrun stapler staple "$DMG"

echo "==> 판정 (accepted가 아니면 배포하면 안 된다)"
spctl -a -t open --context context:primary-signature -vv "$DMG"
spctl -a -vv "$APP"

rm -f "$ZIP"
echo "==> 완료: $DMG"

if [ "$PUBLISH" = "1" ]; then
    TAG="v${VERSION}"
    echo "==> GitHub 릴리즈 $TAG"
    gh release view "$TAG" >/dev/null 2>&1 \
        && gh release upload "$TAG" "$DMG" --clobber \
        || gh release create "$TAG" "$DMG" --title "$APP_NAME $VERSION" --generate-notes
    gh release view "$TAG" --json url --jq .url
fi
