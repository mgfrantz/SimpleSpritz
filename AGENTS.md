# Repository Guidelines

## Project Structure & Module Organization

SimpleSpritz is a small macOS menu-bar utility built directly with `swiftc`.

- `Sources/SimpleSpritz/main.swift` contains the app entrypoint, AppKit UI, reader state, hotkey handling, and clipboard interaction.
- `Info.plist` defines the macOS app bundle metadata.
- `Makefile` owns local build, package, install, and cleanup tasks.
- `.github/workflows/` contains macOS CI packaging and release automation.
- `build/` is generated output and is ignored by Git.

Keep new source under `Sources/SimpleSpritz/`. If the app grows, split by responsibility, for example `ReaderState.swift`, `ReaderView.swift`, and `HotKeyController.swift`.

## Build, Test, and Development Commands

- `make build` builds `build/SimpleSpritz.app` and copies `Info.plist` into the bundle.
- `make package` builds `build/SimpleSpritz.pkg`; this is the default `make` target and the command used by CI and releases.
- `make install` builds and copies the app into `/Applications`.
- `make clean` removes generated build artifacts.

This project targets macOS and requires Xcode command line tools with Swift, AppKit, Carbon, `pkgbuild`, and `make` available.

## Coding Style & Naming Conventions

Use Swift conventions already present in `main.swift`: 4-space indentation, `UpperCamelCase` for types, `lowerCamelCase` for properties and methods, and `private` for file-local implementation details. Prefer small, focused types for UI state, views, and platform integration.

Do not commit generated bundle or package contents from `build/`.

## Testing Guidelines

There is no automated test suite yet. Before opening a pull request, run `make package` to verify the app compiles and packages successfully. For behavior changes, manually test selected-text reading with `Command` + `Option` + `S`, playback controls, speed/ramp controls, hotkey recording, and `Command` + `Q`.

If tests are added later, place them under a dedicated `Tests/` directory and document the command here.

## Commit & Pull Request Guidelines

Recent commits use short, imperative subjects such as `Add package and GitHub release workflow`. Follow that style: describe the change, not the process.

Pull requests should include a brief summary, manual test results, and any user-visible changes. Include screenshots or a short screen recording when UI layout or reader controls change. Link related issues when applicable.

## Release Notes

Releases are created from version tags matching `v*`, for example:

```sh
git tag v0.1.0
git push origin v0.1.0
```

The release workflow builds `build/SimpleSpritz.pkg` on macOS and uploads it to the GitHub Release.
