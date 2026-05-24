# SimpleSpritz

A tiny macOS menu-bar utility for speed-reading selected text in a temporary floating window.

## Install

Download the latest `SimpleSpritz.pkg` from the [GitHub Releases page](https://github.com/mgfrantz/SimpleSpritz/releases), then double-click it to install `SimpleSpritz.app` into `/Applications`.

Once installed, launch SimpleSpritz from `/Applications`. The app appears in the menu bar and macOS app menu as `SimpleSpritz`.

## Developer Install

Build a local installer package:

```sh
make package
```

This creates:

```text
build/SimpleSpritz.pkg
```

Install directly from a local checkout:

```sh
make install
```

This builds and copies `SimpleSpritz.app` directly into `/Applications`.

## Release

GitHub Releases are published from version tags. Maintainers can publish a release with:

```sh
git tag v0.1.0
git push origin v0.1.0
```

The release workflow builds `build/SimpleSpritz.pkg` on macOS and uploads it to the GitHub Release.

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
