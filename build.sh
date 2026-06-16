#!/usr/bin/env bash
# Build Amped.app locally and drop it in ./dist.
# Requires: Xcode, xcodegen (brew install xcodegen), rsvg-convert (brew install librsvg).
set -euo pipefail
cd "$(dirname "$0")"

echo "▸ Generating app icon…"
./icon/generate-icons.sh

echo "▸ Generating Xcode project…"
xcodegen generate

echo "▸ Building (Release)…"
xcodebuild \
  -project Amped.xcodeproj \
  -scheme Amped \
  -configuration Release \
  -derivedDataPath .build \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  build

APP=".build/Build/Products/Release/Amped.app"
mkdir -p dist
rm -rf "dist/Amped.app"
cp -R "$APP" "dist/Amped.app"

echo ""
echo "✅ Built dist/Amped.app"
echo "   Launch it with:  open dist/Amped.app"
echo "   Install it with: cp -R dist/Amped.app /Applications/"
