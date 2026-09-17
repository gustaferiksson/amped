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

## Automated releases (GitHub Actions)

> Full step-by-step (one-time setup + every release) lives in
> [`docs/RELEASING.md`](docs/RELEASING.md). Short version below.

`.github/workflows/release.yml` does the whole thing on a version tag:

```sh
git tag v1.0 && git push origin v1.0
```

→ Developer ID signed build → notarize → staple → `Amped-1.0.zip`
attached to a GitHub Release → Homebrew cask bumped in `gustaferiksson/homebrew-tap`.
`.github/workflows/ci.yml` separately builds (unsigned) on every push/PR and
asserts the icon is in the bundle.

### CI release secrets

Add these under the repo's **Settings → Secrets and variables → Actions**:

| Secret | What it is / how to get it |
| --- | --- |
| `APPLE_CERT_P12` | Your *Developer ID Application* cert+key exported from Keychain Access as a `.p12`, then `base64 -i cert.p12 \| pbcopy`. |
| `APPLE_CERT_PASSWORD` | The password you set when exporting the `.p12`. |
| `NOTARY_APPLE_ID` | The Apple ID email that owns the Developer ID certificate. |
| `NOTARY_PASSWORD` | An app-specific password for that Apple ID: appleid.apple.com → Sign-In & Security → App-Specific Passwords. Not your Apple ID password. |
| `TAP_GITHUB_TOKEN` | A fine-grained PAT with **Contents: read/write** on `gustaferiksson/homebrew-tap`. Required — preflight fails the release if it is unset. |

The Team ID (`82K3YC8HVF`) is not secret — it's baked into every signed binary
and lives in the workflow and README.

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
