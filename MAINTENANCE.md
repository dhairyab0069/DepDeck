# DepDeck Maintenance Guide

How to keep DepDeck running, change any part of it yourself, and recover when
something breaks. No Xcode needed — just a terminal and any text editor.

---

## 1. The golden loop (memorize this)

Every change follows the same three steps:

```sh
cd /path/to/DepDeck   # wherever you cloned it

# 1. Edit a file (any editor — VS Code, vim, TextEdit)
# 2. Rebuild
swift build -c release

# 3. Restart the app
pkill -f ".build/release/DepDeck"
.build/release/DepDeck & disown
```

If step 2 prints errors, the app keeps running on the **old** version — a failed
build never breaks the running app. Fix the error and rebuild.

> Tip: during development use plain `swift build` (faster, unoptimized) and only
> `-c release` when you're done.

---

## 2. Map: which file owns what

| You want to change… | Edit this file |
|---|---|
| What a "package" knows (fields, labels) | `Sources/DepDeck/Models.swift` |
| How shell commands run | `Sources/DepDeck/Shell.swift` |
| Anything Homebrew (commands, JSON parsing) | `Sources/DepDeck/Managers/BrewClient.swift` |
| Anything npm | `Sources/DepDeck/Managers/NpmClient.swift` |
| Anything cargo / crates.io | `Sources/DepDeck/Managers/CargoClient.swift` |
| App logic: refresh, upgrade, replace, auto-update timer | `Sources/DepDeck/Store.swift` |
| Menu bar icon & badge | `Sources/DepDeck/DepDeckApp.swift` |
| Panel size, tabs, header, error banner | `Sources/DepDeck/Views/ContentView.swift` |
| The five tabs | `Sources/DepDeck/Views/{Installed,Updates,Issues,Search,Settings}View.swift` |
| Minimum macOS version | `Package.swift` |

Rule of thumb: **Clients** talk to the outside world, the **Store** decides what
happens, **Views** only display. Keep changes in their lane and nothing else breaks.

---

## 3. Common changes (recipes)

### Change the panel size
`ContentView.swift`, last line of `body`:
```swift
.frame(width: 420, height: 480)   // make it bigger/smaller here
```

### Change the menu bar icon
`DepDeckApp.swift` — swap `"shippingbox"` for any SF Symbol name
(browse them with the free [SF Symbols app](https://developer.apple.com/sf-symbols/)).

### Add/change update-interval choices
`Views/SettingsView.swift` — add a line to the Picker:
```swift
Text("30 minutes").tag(0.5)
```

### Change the default check interval
`Store.swift`:
```swift
@AppStorage("checkIntervalHours") var checkIntervalHours = 6.0  // ← default
```
(Note: once you've used the app, the *saved* setting wins. Reset saved settings with
`defaults delete DepDeck` if it exists, or just change it in the Settings tab.)

### Add a new package manager (e.g. pip)
1. Copy `Managers/CargoClient.swift` → `Managers/PipClient.swift`, adapt the
   commands (`pip list --format=json`, `pip list --outdated --format=json`).
2. Add `case pip` to `PackageManager` in `Models.swift`.
3. Build. The compiler will now **list every switch you must extend**
   (badge color, store methods). Fix each one — when it compiles, it works.

### Make "Refresh" faster
The ↻ button runs `brew update` first. To skip that, in `ContentView.swift`
change `store.refresh(updateIndex: true)` to `updateIndex: false`.

---

## 4. Troubleshooting

| Symptom | Fix |
|---|---|
| No icon in the menu bar | `pgrep -fl DepDeck` — if nothing, launch it again (step 1). If it crashes instantly, run it in the foreground to see the error: `.build/release/DepDeck` |
| Icon there, panel empty/stale | Click ↻. If stuck, restart the app (step 1, part 3). |
| "Update" fails on a package | The red banner shows the real brew/npm error. Try the same command in Terminal (e.g. `brew upgrade foo`) — if it fails there too, it's not DepDeck. |
| Build fails after a macOS/Xcode update | `sudo xcode-select --install` then rebuild. Toolchain updates occasionally need a clean build: `rm -rf .build && swift build -c release` |
| Weird behavior after editing | `git diff` to see exactly what you changed; `git checkout -- <file>` to undo one file. |
| Everything is broken, panic | `git log --oneline` then `git reset --hard <last-good-commit>` and rebuild. |

The app writes nothing outside its own folder except UserDefaults (settings) and
the packages you tell it to install/remove — deleting your clone of the repo
removes it completely (plus the LaunchAgent below, if you installed it).

---

## 5. Version control: your safety net

The repo is already a git repository. Before *any* experiment:

```sh
cd /path/to/DepDeck
git add -A && git commit -m "what I'm about to change and why"
```

Now you can always get back:

```sh
git log --oneline          # see history
git diff                   # what have I changed since last commit?
git checkout -- .          # discard ALL uncommitted edits
git reset --hard <commit>  # time-travel to a known-good state
```

Commit small and often — one change per commit makes rollbacks painless.

---

## 6. If you use the LaunchAgent (start at login)

After rebuilding, restart the agent instead of `pkill`:

```sh
launchctl unload ~/Library/LaunchAgents/com.depdeck.app.plist
launchctl load   ~/Library/LaunchAgents/com.depdeck.app.plist
```

To stop DepDeck from starting at login:

```sh
launchctl unload ~/Library/LaunchAgents/com.depdeck.app.plist
rm ~/Library/LaunchAgents/com.depdeck.app.plist
```

---

## 7. Staying healthy long-term

- **After macOS upgrades**, rebuild once (`swift build -c release`). Swift binaries
  keep working across upgrades, but rebuilding catches deprecations early.
- **If brew changes its JSON** (rare), the Issues/Updates tabs may go empty and the
  banner will show a decoding error naming the missing key — update the matching
  property in `BrewClient.swift`.
- **Learn by reading** `TUTORIAL.md` or `Tutorial/index.html` — every part of the
  code is explained there, so you can modify anything with confidence.
