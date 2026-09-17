# Releasing Amped (continuous deployment)

Amped ships as a **Developer ID signed + notarized** app — *not* through the Mac
App Store. The App Store requires the App Sandbox, which forbids the privileged
root helper and `pmset disablesleep` that power the lid-closed feature. There is
therefore no App Store review/approval step. Notarization is an automated Apple
malware scan (usually a few minutes), after which the app opens with no Gatekeeper
warnings. Delivery is via GitHub Releases + a Homebrew cask.

## How the pipeline works

Two GitHub Actions workflows:

| Workflow | Trigger | What it does |
| --- | --- | --- |
| `.github/workflows/ci.yml` | every push / PR | Unsigned build; asserts the app icon compiled into the bundle. No secrets. |
| `.github/workflows/release.yml` | push of a `v*` tag | Calls `gustaferiksson/macos-release`: Developer ID signed build → notarize → staple → zip → GitHub Release → bump the Homebrew cask. |

Pushing a version tag is the entire release action. Everything below it is automatic:

```
git tag v1.2.0  →  push  →  [release.yml]
                              ├─ build.sh         (Developer ID, hardened runtime, timestamp)
                              ├─ notarytool       (Apple ID + app-specific password)
                              ├─ ditto → Amped-1.2.0.zip
                              ├─ gh release create (attaches the zip)
                              └─ bump Casks/amped.rb in gustaferiksson/homebrew-tap
```

The version comes from the tag (`v1.2.0` → `1.2.0`), stamped into the build via
`MARKETING_VERSION`. The build number is the Actions run number.

## One-time setup

You only do this once. It wires the secrets `release.yml` needs.

### 1. Export the Developer ID certificate

Keychain Access → **Developer ID Application: … (82K3YC8HVF)** → right-click →
**Export** → save `DeveloperID.p12` and set an export password.

### 2. Create an app-specific password (for notarization)

[appleid.apple.com](https://appleid.apple.com) → **Sign-In & Security →
App-Specific Passwords** → **+** → name it `notarytool`. Copy the
`xxxx-xxxx-xxxx-xxxx` value (one chance).

### 3. Token for auto-bumping the Homebrew cask

[github.com/settings/tokens](https://github.com/settings/tokens?type=beta) →
fine-grained token, repository access limited to `gustaferiksson/homebrew-tap`,
permission **Contents: Read and write**. This one is required: the release
workflow's preflight fails the run if it is unset, so a release can never ship
without bumping the cask.

### 4. Add the secrets

Run in the repo (each command prompts for the value, or reads the file):

```sh
gh secret set APPLE_CERT_P12 < <(base64 -i ~/Downloads/DeveloperID.p12)
gh secret set APPLE_CERT_PASSWORD         # the .p12 export password
gh secret set NOTARY_APPLE_ID             # the Apple ID email
gh secret set NOTARY_PASSWORD             # app-specific password from step 2
gh secret set TAP_GITHUB_TOKEN            # token from step 3
```

Confirm with `gh secret list`.

## Every release

```sh
git tag v1.0          # use the version you're shipping
git push origin v1.0
gh run watch          # follow the release run
```

When it's green:

- the notarized download is on the [Releases page](https://github.com/gustaferiksson/amped/releases),
- and `brew install --cask gustaferiksson/tap/amped` installs that version.

(Existing users update with `brew upgrade --cask amped`.)

## Notes

- **Local releases still work** without any of this: a signed `./build.sh` then
  `./notarize.sh` using a local keychain profile (`NOTARY_PROFILE`). See
  [`SHIPPING.md`](../SHIPPING.md). The CI path just uses the API-key credentials instead.
- **Action pinning:** workflow `uses:` are pinned to a commit SHA (not a moving
  tag) so the code that runs with your signing secrets can't change under you.
  To update, bump the SHA and its `# vX.Y.Z` comment.
- **First release:** `Casks/amped.rb` ships with placeholder `version`/`sha256`;
  the first tagged release fills them in.
