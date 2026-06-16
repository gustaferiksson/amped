# Shipping Amped (Part 2 — notarize & distribute)

The signed build is already notarization-ready (Developer ID, Hardened Runtime,
secure timestamp, no `get-task-allow`). What's left is notarizing it with Apple.
Do this when you're ready to hand the app to anyone else.

## One-time setup

1. Create an **app-specific password**: appleid.apple.com → Sign-In & Security →
   App-Specific Passwords. Copy it.
2. Store a notarytool credential profile named `Amped` (matches `NOTARY_PROFILE`
   in `.env`):
   ```sh
   xcrun notarytool store-credentials "Amped" \
     --apple-id "YOUR_APPLE_ID_EMAIL" \
     --team-id 82K3YC8HVF \
     --password "PASTE-THE-APP-SPECIFIC-PASSWORD"
   ```

## Every release

```sh
cd /Users/gustaf/Repos/Gustaf/amped
./build.sh        # Developer ID signed (reads .env)
./notarize.sh     # zip → notarytool submit --wait → stapler staple → verify
```

Ends with `✅ Notarized & stapled`. Hand out the stapled `dist/Amped.app`
(zip it, or wrap in a DMG).

## If notarization fails

`notarytool` prints a submission id. Get the detailed reasons with:
```sh
xcrun notarytool log <submission-id> --keychain-profile "Amped"
```
Common causes: a binary missing Hardened Runtime, no secure timestamp, or a
`get-task-allow` entitlement — all of which `build.sh` already handles.

## Status / TODO

- [x] Developer ID Application cert installed (team 82K3YC8HVF)
- [x] Signed build verified notarization-ready
- [x] Helper approved + lid-closed confirmed working locally
- [ ] Run `./notarize.sh` for the first real notarized build
- [ ] (optional) DMG packaging for distribution
