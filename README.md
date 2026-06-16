# Amped ⚊

A tiny, completely native macOS menu bar app that keeps your Mac awake — an
Amphetamine-style alternative whose party trick is keeping the Mac awake **with
the lid closed**, using `pmset disablesleep` rather than `caffeinate` alone.

No window, no settings sheet, no Dock icon. Just a pill in your menu bar and a
handful of switches.

## The menu

Click the pill in the menu bar:

| Toggle | What it does |
| --- | --- |
| **Keep Awake** | Prevents idle sleep while the lid is open. Uses an IOKit power assertion (same mechanism as `caffeinate`). No password needed. |
| **Allow Lid Closed** | Also stays awake with the lid **closed** (clamshell). Runs `pmset -a disablesleep 1`, the only thing that overrides clamshell sleep. Turning this on also turns on *Keep Awake*. |
| **Auto-off at 20% Battery** | Safety net: when on battery and the charge drops to 20% or below, Amped releases everything so the Mac can sleep normally. This preference is remembered between launches. |
| **Launch at Login** | Registers Amped as a login item (via `SMAppService`) so the pill is there every time you log in. |
| **Skip Password for Lid Mode** | One-time setup: flip it once, approve a single admin prompt, and *Allow Lid Closed* never asks for a password again. Installs a tightly-scoped sudoers rule (see below); flip it off to remove. |

The menu bar pill reflects the state at a glance:

- `pill` — sleep allowed (off)
- `pill.fill` — awake (lid open)
- `pills.fill` — awake with the lid closed

A status line shows the current state and battery level. `⌘Q` quits.

> On launch Amped starts with everything **off** (so it never surprises you by
> blocking sleep or prompting for a password). Only the *Auto-off* preference is
> remembered. When it quits it always restores normal sleep behaviour.

## Why lid-closed needs a password (and how to remove it)

Keeping a Mac awake with the lid shut requires flipping the system
`disablesleep` flag, which only `root` can do.

The **first time** you enable *Allow Lid Closed*, Amped offers to make it
passwordless. Choose *Make It Passwordless* and you approve a single admin prompt
— the lid toggle is silent from then on (which also lets *Auto-off at 20%* drop
clamshell mode while the lid is shut and you're away). Choose *Just This Time*
and it simply prompts for that one toggle. You can also flip **Skip Password for
Lid Mode** in the menu at any point to turn the rule on or off.

It installs a sudoers rule that permits **only** `pmset -a disablesleep 0` and
`pmset -a disablesleep 1` to run without a password — nothing else. Amped tries
this passwordless path first and falls back to the admin prompt if it's absent.

The same setup is also available from the command line if you prefer:

```sh
./scripts/enable-silent-mode.sh      # installs the rule
./scripts/disable-silent-mode.sh     # undo
```

## Build & run

Requires Xcode, plus two Homebrew tools:

```sh
brew install xcodegen librsvg
./build.sh           # generates the icon + Xcode project, builds, copies to ./dist
open dist/Amped.app  # the pill appears in your menu bar
```

To work on it in Xcode:

```sh
./icon/generate-icons.sh && xcodegen generate && open Amped.xcodeproj
```

(The `.xcodeproj` is generated from `project.yml` and is git-ignored.)

## The icon

- **Menu bar:** an SF Symbol (`pill` family) — Apple permits SF Symbols in your
  own UI, and they adapt to light/dark and the focus state automatically.
- **App icon:** `icon/amped.svg` (a two-tone capsule). `icon/generate-icons.sh`
  renders it into the asset catalog at all macOS sizes. To make a proper Liquid
  Glass icon, open `amped.svg` in **Icon Composer**, refine the layers, and
  export an `.icon` to drop into the project.

## A note on the App Store

The lid-closed feature relies on `pmset disablesleep`, which a sandboxed App
Store build cannot do. To ship this you'd distribute it as a notarized
**Developer ID** app (set `DEVELOPMENT_TEAM` and a Developer ID identity in
`project.yml`). An App Store version would have to drop the clamshell feature.

## Project layout

```
Sources/
  AmpedApp.swift        @main App + MenuBarExtra
  MenuContent.swift     the dropdown (toggles + status + quit)
  MenuBarLabel.swift    the pill SF Symbol that reflects state
  SleepController.swift state, battery polling, auto-off safety net
  PowerAssertion.swift  IOKit power assertion wrapper (idle sleep)
  Privileged.swift      pmset disablesleep + sudoers setup via sudo / admin prompt
  Battery.swift         battery % + on-battery via IOKit power sources
  LoginItem.swift       launch-at-login via SMAppService
  AppDelegate.swift     restores normal sleep on quit
icon/                   amped.svg + render script
scripts/                optional passwordless lid-control setup
project.yml             XcodeGen project definition
build.sh                one-shot local build
```
