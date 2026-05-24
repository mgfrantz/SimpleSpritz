# SimpleSpritz

A tiny macOS menu-bar utility for speed-reading selected text in a temporary floating window.

## Package

```sh
make package
```

This creates a macOS installer package:

```text
build/SimpleSpritz.pkg
```

Double-click the package to install `SimpleSpritz.app` into `/Applications`.

## Release

GitHub Releases are published from version tags:

```sh
git tag v0.1.0
git push origin v0.1.0
```

The release workflow builds `build/SimpleSpritz.pkg` on macOS and uploads it to the GitHub Release.

## Local Install

```sh
make install
```

This builds and copies `SimpleSpritz.app` directly into `/Applications`.

Once installed, launch SimpleSpritz from `/Applications`. The app appears in the menu bar and macOS app menu as `SimpleSpritz`.

## Shortcut

Select text in another app, then press `Command` + `Option` + `S` to read it.

macOS may ask for Accessibility permission because SimpleSpritz sends a temporary `Command` + `C` to capture the selection, then restores your original clipboard. If macOS blocks that copy event or no text is selected, SimpleSpritz will not fall back to existing clipboard text.

Selection reading is only triggered by the global hotkey. The app and status menus only include Quit.

## Reader Controls

- `Space`: pause or resume
- `Left` / `Right`: move one word backward or forward
- `Up` / `Down`: increase or decrease speed
- `Esc`: close the reader window
- `Command` + `Q`: quit SimpleSpritz

The reader opens in a compact mode focused on the text. Use `Settings` to reveal pause, speed, ramp, glass transparency, and hotkey controls. Speed and ramp can be adjusted with sliders or `+` / `-` buttons. Use `Change Hotkey`, then press the new key combination to update the global shortcut for the current run.

The default speed is 500 wpm. The `Ramp` control sets how long playback takes to accelerate from 50% of the selected speed to the selected speed. It defaults to 1 second. Glass opacity defaults to 93%.
