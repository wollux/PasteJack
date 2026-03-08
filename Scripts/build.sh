#!/bin/bash
set -euo pipefail

APP_NAME="PasteJack"
VERSION=$(git describe --tags --always 2>/dev/null || echo "0.1.0")
# Strip leading 'v' from git tag (v0.1.0 → 0.1.0)
VERSION="${VERSION#v}"

echo "==> Building ${APP_NAME} v${VERSION}..."

# Universal binary (Apple Silicon + Intel)
swift build -c release \
    --arch arm64 \
    --arch x86_64

# Find the binary (universal builds use .build/apple/Products/Release/)
BIN_PATH="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)"
BINARY="${BIN_PATH}/${APP_NAME}"
BUILD_DIR=".build/release"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"

echo "==> Creating app bundle..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

cp "${BINARY}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

cat > "${APP_BUNDLE}/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.pastejack.app</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>CFBundleURLTypes</key>
    <array><dict>
        <key>CFBundleURLSchemes</key>
        <array><string>pastejack</string></array>
        <key>CFBundleURLName</key>
        <string>com.pastejack.app</string>
    </dict></array>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026 Wolfgang Vieregg. All rights reserved.</string>
</dict>
</plist>
EOF

cp Resources/PasteJack.entitlements "${APP_BUNDLE}/Contents/Resources/"

echo "==> Signing with hardened runtime..."
codesign --force --deep --options runtime \
    --entitlements Resources/PasteJack.entitlements \
    --sign "Developer ID Application: Wolfgang Vieregg (YS8R2WK948)" \
    "${APP_BUNDLE}"

echo "==> Build complete: ${APP_BUNDLE}"
