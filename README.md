# DepDeck

A macOS menu bar app for managing command-line tools and dependencies across
**Homebrew**, **npm (global)**, and **cargo**.

## Features

- **Menu bar badge** — shows the number of outdated packages (and a ⚠︎ count when
  anything is deprecated/disabled)
- **Installed** — every tracked package with version, filter box, and uninstall button
- **Updates** — one-click upgrade per package or *Update All*; optional auto-upgrade
  on a configurable schedule (Settings tab)
- **Issues** — deprecated or disabled packages with the reason, a **Replace with …**
  button when the package manager suggests a successor, and an **Uninstall** button
- **Search** — search Homebrew formulae and crates.io and install from the UI

## Requirements

- macOS 14 (Sonoma) or later, and the Swift toolchain (Xcode or the Command Line Tools).
- Whichever of `brew`, `npm` and `cargo` you use. A manager that isn't installed shows an
  error in the banner and contributes no packages; the others still work.

## Build & run

```sh
git clone https://github.com/dhairyab0069/DepDeck && cd DepDeck
swift build -c release
.build/release/DepDeck &
```

Or use the launcher in `bin/` (`depdeck [start|stop|restart|status|build]`), which builds on
first start. DepDeck has no Dock icon: look for the box icon in the menu bar.

## Test

```sh
swift test
```

The tests cover the output parsers for `brew`, `npm` and `cargo`, the shell quoting that
protects package names, and the models. They don't run any package manager. The `Academy/`
folder is a separate teaching package whose tests are meant to fail until you complete each
stage, so it is not part of `swift test` at the repo root or of CI.

## Permissions and network

- No special macOS permission prompts (no Accessibility, Automation or Full Disk Access).
- Commands run as you, through your login shell, so uninstall and upgrade do what the same
  command in Terminal would do.
- Network: `brew` and `npm` use their usual servers; cargo versions are looked up on the
  crates.io API (the only request DepDeck makes itself). No accounts, analytics or telemetry.
- Settings (auto-upgrade, check interval) are stored in the app's UserDefaults.

## Launch at login

Run this from the repo root (it writes the path of your build into the plist):

```sh
cat > ~/Library/LaunchAgents/com.depdeck.app.plist <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>com.depdeck.app</string>
    <key>ProgramArguments</key>
    <array><string>$PWD/.build/release/DepDeck</string></array>
    <key>RunAtLoad</key><true/>
</dict>
</plist>
PLIST
launchctl load ~/Library/LaunchAgents/com.depdeck.app.plist
```

## More docs

- `MAINTENANCE.md`: which file owns what, common changes, troubleshooting.
- `TUTORIAL.md` and `Tutorial/index.html`: a walkthrough of building DepDeck.
- `Academy/GUIDE.md`: a test-gated Swift course that rebuilds DepDeck as a windowed app.

## Notes

- Commands run through a login shell (`zsh -lc`) so your normal PATH applies.
- Refresh (↻ in the header) runs `brew update` first, so it can take ~30s.
- npm deprecation is detected via `npm view <pkg> deprecated`; cargo versions are
  checked against the crates.io API.
