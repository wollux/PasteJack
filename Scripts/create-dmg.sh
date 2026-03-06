#!/bin/bash
set -euo pipefail

APP_NAME="PasteJack"
VERSION=$(git describe --tags --always 2>/dev/null || echo "0.1.0")
VERSION="${VERSION#v}"
APP_BUNDLE=".build/release/${APP_NAME}.app"
DMG_DIR=".build/dmg"
DMG_FILE=".build/${APP_NAME}-${VERSION}.dmg"

echo "==> Creating DMG..."

rm -rf "${DMG_DIR}"
mkdir -p "${DMG_DIR}"
cp -R "${APP_BUNDLE}" "${DMG_DIR}/"

create-dmg \
    --volname "${APP_NAME}" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "${APP_NAME}.app" 175 190 \
    --icon "Applications" 425 190 \
    --hide-extension "${APP_NAME}.app" \
    --app-drop-link 425 190 \
    "${DMG_FILE}" \
    "${DMG_DIR}"

echo "==> DMG created: ${DMG_FILE}"
