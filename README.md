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

## Build & run

```sh
cd ~/Developer/DepDeck
swift build -c release
.build/release/DepDeck &
```

## Launch at login

```sh
cat > ~/Library/LaunchAgents/com.depdeck.app.plist <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>com.depdeck.app</string>
    <key>ProgramArguments</key>
    <array><string>/Users/dhairyabhatia/Developer/DepDeck/.build/release/DepDeck</string></array>
    <key>RunAtLoad</key><true/>
</dict>
</plist>
EOF
launchctl load ~/Library/LaunchAgents/com.depdeck.app.plist
```

## Notes

- Commands run through a login shell (`zsh -lc`) so your normal PATH applies.
- Refresh (↻ in the header) runs `brew update` first, so it can take ~30s.
- npm deprecation is detected via `npm view <pkg> deprecated`; cargo versions are
  checked against the crates.io API.
