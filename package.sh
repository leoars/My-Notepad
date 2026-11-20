#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
version=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' Resources/Info.plist)
minimum=12.0
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p dist
signing=()
if [[ -n "${DEVELOPER_ID_APPLICATION:-}${DEVELOPER_ID_INSTALLER:-}" ]]; then
    : "${DEVELOPER_ID_APPLICATION:?Missing application signing identity}"
    : "${DEVELOPER_ID_INSTALLER:?Missing installer signing identity}"
    signing=(--sign "$DEVELOPER_ID_INSTALLER" --timestamp)
fi

for arch in arm64 x86_64; do
    work="$tmp/$arch"
    root="$work/root"
    app="$root/My Notepad.app"
    mkdir -p "$root"
    ./build.sh "$app" "$arch-apple-macos$minimum"
    pkgbuild --analyze --root "$root" "$work/components.plist"
    plutil -replace 0.BundleIsRelocatable -bool false "$work/components.plist"
    pkgbuild --root "$root" --component-plist "$work/components.plist" --preserve-xattr \
        --identifier local.mynotepad.editor.pkg --version "$version" \
        --install-location /Applications "$work/Editor.pkg"

    cat > "$work/Distribution" <<XML
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="2">
  <title>My Notepad</title>
  <options customize="never" hostArchitectures="$arch"/>
  <domains enable_anywhere="false" enable_currentUserHome="false" enable_localSystem="true"/>
  <volume-check><allowed-os-versions><os-version min="$minimum"/></allowed-os-versions></volume-check>
  <choices-outline><line choice="editor"/></choices-outline>
  <choice id="editor" title="My Notepad" visible="false"><pkg-ref id="local.mynotepad.editor.pkg"/></choice>
  <pkg-ref id="local.mynotepad.editor.pkg" version="$version">Editor.pkg</pkg-ref>
</installer-gui-script>
XML
    name="My-Notepad-$version-$arch.pkg"
    productbuild ${signing[@]+"${signing[@]}"} --distribution "$work/Distribution" --package-path "$work" "$work/$name"
    pkgutil --expand-full "$work/$name" "$work/expanded"
    installed="$work/expanded/Editor.pkg/Payload/My Notepad.app"
    test "$(lipo -archs "$installed/Contents/MacOS/MyNotepad")" = "$arch"
    codesign --verify "$installed"
    cmp "$app/Contents/Resources/Notepad.icns" "$installed/Contents/Resources/Notepad.icns"
    if [[ -n "${DEVELOPER_ID_INSTALLER:-}" ]]; then
        codesign --verify --strict "$installed"
        pkgutil --check-signature "$work/$name"
    else
        # O formato personalizado do Finder depende também desses dois atributos.
        for pair in 'com.apple.FinderInfo' 'com.apple.ResourceFork'; do
            item=''
            if [ "$pair" = com.apple.ResourceFork ]; then item=$'/Icon\r'; fi
            xattr -px "$pair" "$app$item" > "$work/original-attr"
            xattr -px "$pair" "$installed$item" > "$work/installed-attr"
            cmp "$work/original-attr" "$work/installed-attr"
        done
    fi
    mv "$work/$name" "dist/$name"
done
