#!/bin/bash
set -euo pipefail

APP_NAME="PasteJack"
VERSION=$(git describe --tags --always 2>/dev/null || echo "0.1.0")
DMG_FILE=".build/${APP_NAME}-${VERSION}.dmg"
APPLE_ID="${APPLE_ID:-your@apple-id.com}"
TEAM_ID="${TEAM_ID:-YOUR_TEAM_ID}"
APP_PASSWORD="${AC_PASSWORD:-@keychain:AC_PASSWORD}"

echo "==> Submitting ${DMG_FILE} for notarization..."

xcrun notarytool submit "${DMG_FILE}" \
    --apple-id "${APPLE_ID}" \
    --team-id "${TEAM_ID}" \
    --password "${APP_PASSWORD}" \
    --wait

echo "==> Stapling notarization ticket..."
xcrun stapler staple "${DMG_FILE}"

echo "==> Verifying..."
xcrun stapler validate "${DMG_FILE}"
spctl --assess --type open --context context:primary-signature "${DMG_FILE}"

echo "==> Notarization complete!"
