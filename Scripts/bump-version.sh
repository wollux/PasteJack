#!/bin/bash
set -euo pipefail

if [ $# -ne 1 ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 0.2.0"
    exit 1
fi

VERSION="$1"
TAG="v${VERSION}"

echo "==> Bumping to version ${VERSION}..."

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo "Error: Uncommitted changes. Please commit first."
    exit 1
fi

# Create annotated tag
git tag -a "${TAG}" -m "Release ${TAG}"

echo "==> Tagged ${TAG}"
echo "==> Push with: git push origin ${TAG}"
