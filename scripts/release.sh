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

# Sparkle 자동 업데이트
SPARKLE_VERSION="2.9.6"
SPARKLE_TOOLS=".build/sparkle-tools"
REPO="kimhung910924/workspace-shelf"
FEED_SLUG="workspace-shelf"           # rrllab.com/apps/<slug>/appcast.xml
SITE="${RRLLAB_SITE:-$HOME/Desktop/app-development/omniai/rrl-lab-site}"

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
WORKSPACE_SHELF_SIGN_IDENTITY="$IDENTITY" ./scripts/build-app.sh release >/dev/null

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

# zip은 지우지 않는다. 공증 제출물이면서 동시에 Sparkle이 내려받는 업데이트 파일이다.
# 사람이 처음 받는 건 dmg, 앱이 스스로 받는 건 zip — dmg 마운트 단계가 없어 실패 지점이 하나 적다.
echo "==> 완료: $DMG"

# ── Sparkle appcast ───────────────────────────────────────
echo "==> Sparkle 서명"
if [ ! -x "$SPARKLE_TOOLS/bin/sign_update" ]; then
    echo "  도구 내려받는 중 ($SPARKLE_VERSION)"
    mkdir -p "$SPARKLE_TOOLS"
    curl -sL "https://github.com/sparkle-project/Sparkle/releases/download/${SPARKLE_VERSION}/Sparkle-${SPARKLE_VERSION}.tar.xz" \
        | tar -xJ -C "$SPARKLE_TOOLS"
fi

# sign_update는 Keychain의 개인키를 쓴다. 백업은 _secrets/sparkle-ed25519-private.key.
SIGN_OUTPUT="$("$SPARKLE_TOOLS/bin/sign_update" "$ZIP")"
ED_SIGNATURE="$(echo "$SIGN_OUTPUT" | sed -E 's/.*edSignature="([^"]+)".*/\1/')"
ZIP_LENGTH="$(echo "$SIGN_OUTPUT" | sed -E 's/.*length="([0-9]+)".*/\1/')"
[ -n "$ED_SIGNATURE" ] || { echo "서명을 못 만들었다: $SIGN_OUTPUT" >&2; exit 1; }

BUILD="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' Resources/Info.plist)"
MIN_SYSTEM="$(/usr/libexec/PlistBuddy -c 'Print :LSMinimumSystemVersion' Resources/Info.plist)"
FEED_URL="https://rrllab.com/apps/${FEED_SLUG}/appcast.xml"
NOTES_URL="https://rrllab.com/apps/${FEED_SLUG}/notes/${VERSION}.html"
ZIP_URL="https://github.com/${REPO}/releases/download/v${VERSION}/$(basename "$ZIP")"

if [ -d "$SITE" ]; then
    APPCAST="$SITE/public/apps/${FEED_SLUG}/appcast.xml"
    NOTES="$SITE/public/apps/${FEED_SLUG}/notes/${VERSION}.html"
    python3 scripts/update-appcast.py \
        --appcast "$APPCAST" --title "$APP_NAME" --feed "$FEED_URL" \
        --version "$VERSION" --build "$BUILD" \
        --url "$ZIP_URL" --length "$ZIP_LENGTH" --signature "$ED_SIGNATURE" \
        --min-system "$MIN_SYSTEM" --notes-url "$NOTES_URL" \
        --pub-date "$(date -R)"

    if [ ! -f "$NOTES" ]; then
        mkdir -p "$(dirname "$NOTES")"
        cat > "$NOTES" <<HTML
<!doctype html>
<meta charset="utf-8">
<title>${APP_NAME} ${VERSION}</title>
<h2>${APP_NAME} ${VERSION}</h2>
<ul>
  <li>이번 버전에서 달라진 점을 여기에 적어 주세요. 사용자가 업데이터에서 그대로 읽습니다.</li>
</ul>
HTML
        echo "  릴리즈 노트 초안: $NOTES  ← 내용을 채울 것"
    fi
else
    echo "  ⚠️  홈페이지 저장소가 없다: $SITE — appcast를 갱신하지 못했다" >&2
fi

# ── GitHub 릴리즈 ─────────────────────────────────────────

if [ "$PUBLISH" = "1" ]; then
    TAG="v${VERSION}"
    echo "==> GitHub 릴리즈 $TAG"
    gh release view "$TAG" >/dev/null 2>&1 \
        && gh release upload "$TAG" "$DMG" "$ZIP" --clobber \
        || gh release create "$TAG" "$DMG" "$ZIP" --title "$APP_NAME $VERSION" --generate-notes
    gh release view "$TAG" --json url --jq .url

    # appcast는 zip이 실제로 올라간 뒤에 공개한다. 순서가 반대면 앱이 404를 받는다.
    if [ -d "$SITE" ]; then
        echo "==> appcast 배포 (Vercel이 푸시를 받아 배포한다)"
        git -C "$SITE" add "public/apps/${FEED_SLUG}"
        git -C "$SITE" commit -q -m "chore(${FEED_SLUG}): appcast ${VERSION}" || echo "  바뀐 것 없음"
        git -C "$SITE" push -q
        echo "  $FEED_URL"
    fi
fi
