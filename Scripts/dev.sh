#!/bin/bash
set -euo pipefail

# Resolve symlinks and cd to project root (works from Desktop shortcut)
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0" 2>/dev/null || echo "$0")")" && pwd)"
cd "${SCRIPT_DIR}/.."

APP_NAME="PasteJack"
BUILD_DIR=".build/debug"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"

echo "==> Building ${APP_NAME} (debug)..."
swift build

echo "==> Creating dev app bundle..."
mkdir -p "${APP_BUNDLE}/Contents/MacOS"

cp "${BUILD_DIR}/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

cat > "${APP_BUNDLE}/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.pastejack.app</string>
    <key>CFBundleName</key>
    <string>PasteJack</string>
    <key>CFBundleExecutable</key>
    <string>PasteJack</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

echo "==> Signing (ad-hoc with stable designated requirement)..."
codesign --force --sign - -r='designated => identifier "com.pastejack.app"' "${APP_BUNDLE}"

echo "==> Launching ${APP_BUNDLE}"
open "${APP_BUNDLE}"
