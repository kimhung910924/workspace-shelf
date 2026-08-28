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

if command -v codesign >/dev/null 2>&1; then
  codesign --force --sign - "$application_directory"
fi

print "$application_directory"

