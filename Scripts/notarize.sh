#!/bin/bash
set -euo pipefail

APP_NAME="PasteJack"
VERSION=$(git describe --tags --always 2>/dev/null || echo "0.1.0")
VERSION="${VERSION#v}"
DMG_FILE=".build/${APP_NAME}-${VERSION}.dmg"
APPLE_ID="${APPLE_ID:-wollux@rootwatch.org}"
TEAM_ID="${TEAM_ID:-YS8R2WK948}"
APP_PASSWORD="${AC_PASSWORD:-$(security find-generic-password -s "AC_PASSWORD" -a "${APPLE_ID}" -w)}"

echo "==> Submitting ${DMG_FILE} for notarization..."

xcrun notarytool submit "${DMG_FILE}" \
    --apple-id "${APPLE_ID}" \
    --team-id "${TEAM_ID}" \
    --password "${APP_PASSWORD}" \
    --wait

echo "==> Stapling notarization ticket..."
xcrun stapler staple "${DMG_FILE}"

echo "==> Verifying staple..."
xcrun stapler validate "${DMG_FILE}"

echo "==> Notarization complete!"
