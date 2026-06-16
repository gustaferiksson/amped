#!/usr/bin/env bash
# Notarize and staple dist/Amped.app. Run after a signed ./build.sh.
#
# One-time credential setup — create a notarytool keychain profile (the password
# is an app-specific password from appleid.apple.com → Sign-In & Security →
# App-Specific Passwords, NOT your Apple ID password):
#
#     xcrun notarytool store-credentials "Amped" \
#       --apple-id "you@example.com" --team-id 82K3YC8HVF --password "xxxx-xxxx-xxxx-xxxx"
#
# Then set NOTARY_PROFILE=Amped in .env.
set -euo pipefail
cd "$(dirname "$0")"

[[ -f .env ]] && { set -a; source ./.env; set +a; }
: "${NOTARY_PROFILE:?Set NOTARY_PROFILE in .env to your notarytool keychain profile (see this file's header for the one-time setup).}"

APP="dist/Amped.app"
ZIP="dist/Amped.zip"

[[ -d "$APP" ]] || { echo "✗ $APP not found — run a signed ./build.sh first."; exit 1; }
if codesign -dvv "$APP" 2>&1 | grep -q "Signature=adhoc"; then
  echo "✗ $APP is ad-hoc signed. Set a Developer ID identity in .env and rebuild."; exit 1
fi

echo "▸ Zipping for submission…"
/usr/bin/ditto -c -k --keepParent "$APP" "$ZIP"

echo "▸ Submitting to the Apple notary service (waits for the result)…"
xcrun notarytool submit "$ZIP" --keychain-profile "$NOTARY_PROFILE" --wait

echo "▸ Stapling the ticket onto the app…"
xcrun stapler staple "$APP"

echo "▸ Verifying…"
xcrun stapler validate "$APP"
spctl -a -vvv --type exec "$APP"

rm -f "$ZIP"
echo "✅ Notarized & stapled: $APP"
