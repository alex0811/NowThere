#!/usr/bin/env bash
set -euo pipefail

CONFIGURATION="${1:-debug}"

swift build --configuration "$CONFIGURATION" --product NowThere
BUILD_DIR="$(swift build --configuration "$CONFIGURATION" --show-bin-path)"
APP_DIR=".build/${CONFIGURATION}/NowThere.app"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp Resources/Info.plist "$APP_DIR/Contents/Info.plist"
cp "$BUILD_DIR/NowThere" "$APP_DIR/Contents/MacOS/NowThere"
chmod +x "$APP_DIR/Contents/MacOS/NowThere"

echo "$APP_DIR"
