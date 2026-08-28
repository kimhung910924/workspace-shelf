#!/bin/zsh

set -euo pipefail

configuration="${1:-debug}"

case "$configuration" in
  debug)
    swift_configuration="debug"
    ;;
  release)
    swift_configuration="release"
    ;;
  *)
    print -u2 "usage: $0 [debug|release]"
    exit 2
    ;;
esac

script_directory="${0:A:h}"
project_directory="${script_directory:h}"
application_directory="${project_directory}/.build/app/Workspace Shelf.app"
contents_directory="${application_directory}/Contents"
macos_directory="${contents_directory}/MacOS"

cd "$project_directory"
swift build -c "$swift_configuration"

binary_directory="$(swift build -c "$swift_configuration" --show-bin-path)"
binary_path="${binary_directory}/WorkspaceShelf"

if [[ ! -x "$binary_path" ]]; then
  print -u2 "WorkspaceShelf executable was not produced at $binary_path"
  exit 1
fi

mkdir -p "$macos_directory"
cp "$binary_path" "${macos_directory}/WorkspaceShelf"
mkdir -p "${contents_directory}/Resources"
cp "${project_directory}/Resources/Info.plist" "${contents_directory}/Info.plist"
cp "${project_directory}/Resources/AppIcon.icns" "${contents_directory}/Resources/AppIcon.icns"

# Sparkle.framework를 번들에 넣는다.
#
# SPM은 프레임워크를 빌드 폴더에 풀어놓기만 하고 .app 안으로 넣지 않는다(Xcode가 하던 일이다).
# 안 넣으면 실행 즉시 dyld가 Sparkle을 못 찾아 앱이 죽는다.
frameworks_directory="${contents_directory}/Frameworks"
mkdir -p "$frameworks_directory"
rm -rf "${frameworks_directory}/Sparkle.framework"
ditto "${binary_directory}/Sparkle.framework" "${frameworks_directory}/Sparkle.framework"

# SPM이 박아 준 rpath는 @loader_path(= Contents/MacOS)뿐이라 한 칸 위 Frameworks를 못 본다.
# 없으면 "Library not loaded: @rpath/Sparkle.framework"로 죽는다.
install_name_tool -add_rpath "@executable_path/../Frameworks" \
  "${macos_directory}/WorkspaceShelf" 2>/dev/null || true

# 중첩 코드부터 안쪽 순서로 서명한다. 바깥을 먼저 서명하면 안쪽을 건드리는 순간 깨진다.
# --deep은 애플이 권장하지 않는다(하드닝 런타임·entitlements가 안쪽에 그대로 복사된다).
#
# 신원은 WORKSPACE_SHELF_SIGN_IDENTITY로 넘길 수 있다. 배포본(scripts/release.sh)은
# Developer ID를 넘긴다 — ad-hoc으로 서명된 중첩 코드가 하나라도 있으면 공증이
# "The binary is not signed with a valid Developer ID certificate"로 거절한다
# (2026-08-28 Sparkle의 Updater.app에서 실제로 겪었다).
if command -v codesign >/dev/null 2>&1; then
  sign_identity="${WORKSPACE_SHELF_SIGN_IDENTITY:--}"
  sparkle="${frameworks_directory}/Sparkle.framework"
  for target in \
    "${sparkle}/Versions/B/XPCServices/Downloader.xpc" \
    "${sparkle}/Versions/B/XPCServices/Installer.xpc" \
    "${sparkle}/Versions/B/Updater.app" \
    "${sparkle}/Versions/B/Autoupdate" \
    "$sparkle" \
    "$application_directory"
  do
    codesign --force --options runtime --sign "$sign_identity" "$target"
  done
fi

print "$application_directory"

