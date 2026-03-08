#!/bin/bash
set -euo pipefail

APP_NAME="PasteJack"
VERSION=$(git describe --tags --always 2>/dev/null || echo "0.1.0")
VERSION="${VERSION#v}"
DMG_FILE=".build/${APP_NAME}-${VERSION}.dmg"
APPCAST_FILE="appcast.xml"
UPLOAD_URL="https://pastejack.app/api/upload.php"

# Token from environment or macOS Keychain
UPLOAD_TOKEN="${PASTEJACK_UPLOAD_TOKEN:-$(security find-generic-password -s "PASTEJACK_UPLOAD_TOKEN" -w 2>/dev/null || echo "")}"

if [ -z "$UPLOAD_TOKEN" ]; then
    echo "ERROR: No upload token found."
    echo "Set PASTEJACK_UPLOAD_TOKEN env var or store in Keychain:"
    echo "  security add-generic-password -s PASTEJACK_UPLOAD_TOKEN -a pastejack -w 'YOUR_TOKEN'"
    exit 1
fi

if [ ! -f "$DMG_FILE" ]; then
    echo "ERROR: DMG not found: $DMG_FILE"
    echo "Run build.sh, create-dmg.sh, and notarize.sh first."
    exit 1
fi

echo "==> Uploading ${APP_NAME} v${VERSION} to pastejack.app..."
echo "    DMG: ${DMG_FILE} ($(du -h "$DMG_FILE" | cut -f1))"
echo "    Appcast: ${APPCAST_FILE}"

RESPONSE=$(curl -s -w "\n%{http_code}" \
    -X POST "$UPLOAD_URL" \
    -H "Authorization: Bearer $UPLOAD_TOKEN" \
    -F "dmg=@${DMG_FILE}" \
    -F "appcast=@${APPCAST_FILE}" \
    -F "version=${VERSION}")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -ne 200 ]; then
    echo "ERROR: Upload failed (HTTP $HTTP_CODE)"
    echo "$BODY"
    exit 1
fi

echo "==> Upload successful!"
echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"

# Verify download URL
DMG_URL=$(echo "$BODY" | python3 -c "import sys,json; print(json.load(sys.stdin)['dmg']['url'])" 2>/dev/null || echo "")
if [ -n "$DMG_URL" ]; then
    echo ""
    echo "==> Verifying download..."
    LOCAL_SHA=$(shasum -a 256 "$DMG_FILE" | cut -d' ' -f1)
    REMOTE_SHA=$(curl -sL "$DMG_URL" | shasum -a 256 | cut -d' ' -f1)
    if [ "$LOCAL_SHA" = "$REMOTE_SHA" ]; then
        echo "    SHA256 match: $LOCAL_SHA"
    else
        echo "    WARNING: SHA256 mismatch!"
        echo "    Local:  $LOCAL_SHA"
        echo "    Remote: $REMOTE_SHA"
        exit 1
    fi
fi

# ── Update Homebrew Cask ──────────────────────────────────────────────────
echo ""
echo "==> Updating Homebrew Cask..."

SHA256=$(shasum -a 256 "$DMG_FILE" | cut -d' ' -f1)
CASK_FILE="Distribution/Casks/pastejack.rb"

# Update local cask
sed -i '' "s/version \".*\"/version \"${VERSION}\"/" "$CASK_FILE"
sed -i '' "s/sha256 \".*\"/sha256 \"${SHA256}\"/" "$CASK_FILE"
echo "    Local cask updated: ${CASK_FILE}"

# Update remote tap (wollux/homebrew-tap)
CASK_CONTENT=$(base64 < "$CASK_FILE")
FILE_SHA=$(gh api repos/wollux/homebrew-tap/contents/Casks/pastejack.rb --jq '.sha' 2>/dev/null || echo "")

if [ -n "$FILE_SHA" ]; then
    gh api repos/wollux/homebrew-tap/contents/Casks/pastejack.rb \
        --method PUT \
        -f message="Update pastejack to v${VERSION}" \
        -f content="$CASK_CONTENT" \
        -f sha="$FILE_SHA" > /dev/null
    echo "    Remote tap updated: wollux/homebrew-tap"
else
    echo "    WARNING: Could not update remote tap (gh auth or repo issue)"
fi

echo ""
echo "==> Done! Release v${VERSION} is live at https://pastejack.app/downloads/"
