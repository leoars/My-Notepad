#!/bin/bash
set -eu
cd "$(dirname "$0")"
app="${1:-My Notepad.app}"
bundle="$app/Contents"
flags=(-swift-version 5)
if [ "$#" -gt 1 ]; then flags+=(-target "$2"); fi
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$bundle/MacOS" "$bundle/Resources"
swiftc "${flags[@]}" -module-cache-path "$tmp/modules" -O Sources/*.swift -o "$tmp/MyNotepad"
python3 Tools/icon.py Resources/Notepad.png "$bundle/Resources/Notepad.icns" "$tmp"
cp "$tmp/16.png" "$bundle/Resources/Caption.png"
cp -R Resources/*.lproj "$bundle/Resources/"
cp LICENSE THIRD_PARTY_NOTICES.md "$bundle/Resources/"

cp Resources/Info.plist "$bundle/Info.plist"
cp "$tmp/MyNotepad" "$bundle/MacOS/MyNotepad"
swift -module-cache-path "$tmp/modules" Tools/FinderIcon.swift clear "$app"
if [[ -n "${DEVELOPER_ID_APPLICATION:-}" ]]; then
    codesign --force --options runtime --timestamp --sign "$DEVELOPER_ID_APPLICATION" "$app"
    codesign --verify --strict "$app"
else
    codesign --force --sign - "$app"
    swift -module-cache-path "$tmp/modules" Tools/FinderIcon.swift apply "$app"
fi
