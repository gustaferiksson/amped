#!/usr/bin/env bash
# Build Amped.app locally and drop it in ./dist.
# Requires: Xcode, xcodegen (brew install xcodegen), rsvg-convert (brew install librsvg).
#
# Local (ad-hoc) build — the privileged helper won't run, lid mode falls back to
# a password prompt:
#     ./build.sh
#
# Signed build (helper works) — provide your Developer ID:
#     DEVELOPMENT_TEAM=XXXXXXXXXX CODE_SIGN_IDENTITY="Developer ID Application" ./build.sh
set -euo pipefail
cd "$(dirname "$0")"

# Optional local config (git-ignored): DEVELOPMENT_TEAM, CODE_SIGN_IDENTITY.
if [[ -f .env ]]; then
  set -a
  # shellcheck source=/dev/null
  source ./.env
  set +a
fi

SIGN_ID="${CODE_SIGN_IDENTITY:--}"
# The team is only meaningful for a real signed build; ad-hoc ignores it.
TEAM_SETTING=""
if [[ "$SIGN_ID" != "-" && -n "${DEVELOPMENT_TEAM:-}" ]]; then
  TEAM_SETTING="DEVELOPMENT_TEAM=${DEVELOPMENT_TEAM}"
fi

echo "▸ Generating app icon…"
./icon/generate-icons.sh

echo "▸ Generating Xcode project…"
xcodegen generate

echo "▸ Building (Release)…  signing identity: ${SIGN_ID}"
xcodebuild \
  -project Amped.xcodeproj \
  -scheme Amped \
  -configuration Release \
  -derivedDataPath .build \
  CODE_SIGN_IDENTITY="${SIGN_ID}" \
  CODE_SIGNING_REQUIRED=NO \
  ${TEAM_SETTING} \
  build

APP=".build/Build/Products/Release/Amped.app"
mkdir -p dist
rm -rf "dist/Amped.app"
cp -R "$APP" "dist/Amped.app"

echo ""
echo "✅ Built dist/Amped.app"
echo "   Launch it with:  open dist/Amped.app"
echo "   Install it with: cp -R dist/Amped.app /Applications/"
