#!/usr/bin/env bash
# Build "Mapsmith.app" into build/ (release configuration, ad-hoc signed).
# Usage: scripts-build/bundle.sh [--install]   (--install copies it to /Applications)
set -euo pipefail

cd "$(dirname "$0")/.."
APP="build/Mapsmith.app"

swift build -c release --product Mapsmith
BIN="$(swift build -c release --show-bin-path)/Mapsmith"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Mapsmith"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
codesign --force --sign - "$APP"
echo "Built $APP"

if [[ "${1:-}" == "--install" ]]; then
    rm -rf "/Applications/Mapsmith.app"
    cp -R "$APP" /Applications/
    echo "Installed to /Applications/Mapsmith.app"
fi
