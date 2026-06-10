# Building DepDeck — A Swift Tutorial

Build a real macOS menu bar app that tracks your command-line tools (Homebrew, npm,
cargo), shows available updates, and flags deprecated packages with one-click
replace/delete.

Along the way you'll learn: **Swift Package Manager**, **structs & enums**,
**protocols**, **async/await**, **running shell commands with `Process`**,
**Codable JSON parsing**, **SwiftUI**, and **`MenuBarExtra`**.

> An interactive version of this tutorial lives at `Tutorial/index.html` — open it
> in a browser for clickable code annotations and quizzes.

---

## Chapter 1 — Project Setup

A Swift app doesn't need Xcode. The **Swift Package Manager (SPM)** that ships with
the toolchain can build executables from a folder with a `Package.swift` manifest.

```sh
mkdir -p ~/Developer/DepDeck/Sources/DepDeck/{Managers,Views}
```

**`Package.swift`**

```swift
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "DepDeck",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "DepDeck",
            path: "Sources/DepDeck"
        )
    ]
)
```

- The first comment line is **not optional** — it tells SPM which manifest format
  to use.
- `platforms: [.macOS(.v14)]` sets the **minimum** macOS version. We need v13+
  for `MenuBarExtra`; v14 gives us nicer `onChange`.
- `.executableTarget` means "this produces a runnable binary" (vs. `.target` for
  libraries). Every `.swift` file under `path` is compiled into it.

**Checkpoint:** `swift build` should succeed (it compiles nothing yet, that's fine).

---

## Chapter 2 — Modeling the Domain

Before UI or shell commands, define *what a package is*. In Swift you model data
with **structs** (value types) and **enums** (closed sets of cases).

**`Models.swift`** — the enum:

```swift
enum PackageManager: String, CaseIterable, Identifiable {
    case brew
    case npm
    case cargo

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .brew: return "Homebrew"
        case .npm: return "npm"
        case .cargo: return "cargo"
        }
    }
}
```

- `: String` gives each case a **raw value** (`"brew"`, `"npm"`, …) for free.
- `CaseIterable` adds `PackageManager.allCases` — handy for looping in UI.
- `Identifiable` is the protocol SwiftUI lists use to tell rows apart; it just
  requires an `id` property.
- `displayName` is a **computed property** — no stored data, evaluated on access.
  The `switch` must be *exhaustive*; add a case to the enum and the compiler
  forces you to handle it here. This is Swift's biggest safety win over strings.

The struct:

```swift
struct Package: Identifiable, Hashable {
    let manager: PackageManager
    let name: String
    var description: String?
    var installedVersion: String
    var latestVersion: String?
    var outdated: Bool
    var deprecated: Bool
    var deprecationReason: String?
    var disabled: Bool
    var disableReason: String?
    var replacement: String?

    var id: String { "\(manager.rawValue):\(name)" }

    var hasIssue: Bool { deprecated || disabled }
    var issueLabel: String { disabled ? "Disabled" : "Deprecated" }
    var issueReason: String? { disableReason ?? deprecationReason }
}
```

- `String?` is an **Optional** — "a String or nothing." Swift forces you to handle
  the nothing case; there are no surprise nulls.
- `let` = immutable after init, `var` = mutable. Identity fields are `let`.
- `id` combines manager and name (`"brew:ripgrep"`) so the same tool installed by
  two managers doesn't collide.
- `??` is the **nil-coalescing operator**: "use the left side unless it's nil."
- `Hashable` lets us put packages in a `Set` and use them in `ForEach`.

---

## Chapter 3 — Running Shell Commands

The whole app is a UI over `brew`, `npm`, and `cargo`, so we need one solid
function: *run a command, give me its output, or throw an error*.

**`Shell.swift`** (key parts):

```swift
enum Shell {
    @discardableResult
    static func run(_ command: String) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/bin/zsh")
                process.arguments = ["-lc", command]

                let stdout = Pipe()
                let stderr = Pipe()
                process.standardOutput = stdout
                process.standardError = stderr

                do { try process.run() }
                catch { continuation.resume(throwing: error); return }

                // Drain both pipes concurrently so neither fills and blocks.
                var errData = Data()
                let errDone = DispatchSemaphore(value: 0)
                DispatchQueue.global(qos: .userInitiated).async {
                    errData = stderr.fileHandleForReading.readDataToEndOfFile()
                    errDone.signal()
                }
                let outData = stdout.fileHandleForReading.readDataToEndOfFile()
                errDone.wait()
                process.waitUntilExit()
                // ... resume with output or a ShellError
            }
        }
    }
}
```

Concepts, in order of appearance:

1. **`enum Shell` with only static members** is Swift's idiom for a namespace —
   an enum with no cases can never be instantiated.
2. **`async throws -> String`**: callers write
   `let out = try await Shell.run("brew update")`. `await` marks a suspension
   point; `try` marks that it can fail.
3. **`@discardableResult`** silences the "result unused" warning for commands
   like `brew update` where we don't care about output.
4. **`withCheckedThrowingContinuation`** is the bridge from callback-world to
   async/await-world. You get a `continuation`; call `resume(returning:)` or
   `resume(throwing:)` **exactly once**, and the `await` finishes.
5. **`zsh -lc`** runs the command through a *login* shell, so the user's real
   PATH (`/opt/homebrew/bin`, `~/.cargo/bin`, …) applies. Plain `Process` has a
   minimal PATH and wouldn't find `brew`.
6. **The deadlock trap:** a pipe buffer holds ~64KB. If the child writes more to
   stderr while you're only reading stdout, the child blocks forever waiting for
   someone to drain stderr — and you block waiting for stdout EOF. Reading the
   two pipes on separate queues fixes this. Every CLI-wrapping app hits this bug
   eventually; now you've pre-fixed it.

Errors are modeled as a type, not a string:

```swift
enum ShellError: LocalizedError {
    case failed(command: String, code: Int32, output: String)
    var errorDescription: String? { /* readable message */ }
}
```

**Associated values** (`command:`, `code:`, `output:`) attach payload data to an
enum case. `LocalizedError` makes `error.localizedDescription` show our message.

---

## Chapter 4 — The Homebrew Client (Codable)

`brew info --json=v2 --installed` dumps everything about installed formulae as
JSON — versions, outdated flags, and crucially `deprecated`, `deprecation_reason`,
and `deprecation_replacement_formula`.

Swift's **`Codable`** turns JSON into typed structs with zero parsing code.
You declare structs whose property names match the JSON keys:

```swift
private struct Formula: Decodable {
    struct Versions: Decodable { let stable: String? }
    struct Installed: Decodable { let version: String }

    let name: String
    let desc: String?
    let versions: Versions
    let installed: [Installed]
    let outdated: Bool
    let deprecated: Bool
    let deprecation_reason: String?
    let deprecation_replacement_formula: String?
    // ...
}
```

- Nested JSON objects become **nested structs**.
- Optional properties (`String?`) tolerate `null` or missing keys.
- We keep snake_case names to match the JSON exactly. (The alternative is
  `JSONDecoder().keyDecodingStrategy = .convertFromSnakeCase`.)
- `private` because this shape is an implementation detail of `BrewClient`;
  the rest of the app only ever sees our clean `Package` model. This is the
  **adapter pattern**: messy external data in, tidy domain model out.

Mapping to the domain model:

```swift
return response.formulae.compactMap { formula in
    guard let current = formula.installed.last?.version else { return nil }
    return Package(
        manager: .brew,
        name: formula.name,
        // ...
        replacement: formula.disable_replacement_formula
            ?? formula.deprecation_replacement_formula
            ?? formula.disable_replacement_cask
            ?? formula.deprecation_replacement_cask
    )
}
```

- **`compactMap`** = map + drop nils. Formulae with no installed version vanish.
- **`guard let`** unwraps an optional or exits early — Swift's "happy path stays
  un-indented" tool.
- The chained `??` picks the first non-nil replacement suggestion.

---

## Chapter 5 — npm & cargo Clients

Same adapter pattern, different quirks — this chapter is about *defensive
integration*.

**npm:** `npm outdated -g --json` exits with code **1** when anything is outdated
(by design!). Our `Shell.run` would throw, so we append `|| true` and parse
whatever JSON came back. Deprecation comes from `npm view <pkg> deprecated`,
which prints a message only when deprecated.

```swift
let outdatedJSON = (try? await Shell.run("npm outdated -g --json || true")) ?? "{}"
```

`try?` converts a thrown error into `nil` — perfect for "this is allowed to fail."

**cargo** has no JSON for installed tools, so we parse text. `cargo install --list`
looks like:

```
ripgrep v14.1.0:
    rg
```

Top-level lines end with `:`; indented lines are binaries. String slicing handles it:

```swift
for line in output.split(separator: "\n") {
    guard !line.hasPrefix(" "), line.hasSuffix(":") else { continue }
    let parts = line.dropLast().split(separator: " ")
    guard parts.count >= 2, parts[1].hasPrefix("v") else { continue }
    let name = String(parts[0])
    let version = String(parts[1].dropFirst())
    // ...
}
```

Latest versions come from the **crates.io HTTP API** using `URLSession` — note
async/await makes a network call one line:

```swift
let (data, _) = try await URLSession.shared.data(for: request)
```

(crates.io asks for a `User-Agent` header identifying your tool — be a good
API citizen.)

---

## Chapter 6 — The Store (State Management)

The **store** is the single source of truth the UI observes. This is the
ObservableObject pattern (MVVM-ish).

```swift
@MainActor
final class DependencyStore: ObservableObject {
    @Published var packages: [Package] = []
    @Published var busyPackageIDs: Set<String> = []
    @Published var lastError: String?

    @AppStorage("autoUpgrade") var autoUpgrade = false
    @AppStorage("checkIntervalHours") var checkIntervalHours = 6.0
    // ...
}
```

- **`@MainActor`** guarantees every property access and method runs on the main
  thread — UI state must only change there. The compiler *enforces* it.
- **`@Published`** makes SwiftUI re-render any view reading that property when
  it changes.
- **`@AppStorage`** persists straight to UserDefaults — settings survive restarts
  with zero extra code.
- It's a `class` (not struct) because many views need to share *one* mutable
  instance.

**Parallel refresh with `async let`:**

```swift
async let brewResult = gather { try await self.brew.installedPackages() }
async let npmResult = gather { try await self.npm.installedPackages() }
async let cargoResult = gather { try await self.cargo.installedPackages() }
let results = await [brewResult, npmResult, cargoResult]
```

`async let` starts all three immediately and runs them **concurrently**; the
single `await` collects them. Sequential awaits would take
brew-time + npm-time + cargo-time; this takes max of the three.

**The background check loop** is just an infinite async task:

```swift
timerTask = Task { [weak self] in
    while !Task.isCancelled {
        try? await Task.sleep(for: .seconds(hours * 3600))
        guard let self, !Task.isCancelled else { return }
        await self.refresh(updateIndex: true)
        if self.autoUpgrade { await self.upgradeAll() }
    }
}
```

- `[weak self]` prevents a **retain cycle** (the store owns the task, the task
  would otherwise own the store — neither could ever be freed).
- `Task.sleep` suspends without blocking a thread.
- Storing the task lets `schedulePeriodicChecks()` cancel and restart it when
  the user changes the interval.

Also note the busy-tracking pattern used by every mutation:

```swift
busyPackageIDs.insert(package.id)
defer { busyPackageIDs.remove(package.id) }
```

**`defer`** runs when the scope exits *no matter how* — success, error, early
return. It's Swift's "finally."

---

## Chapter 7 — The App Entry Point & MenuBarExtra

```swift
@main
struct DepDeckApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var store = DependencyStore()

    var body: some Scene {
        MenuBarExtra {
            ContentView().environmentObject(store)
        } label: {
            // icon + outdated count
        }
        .menuBarExtraStyle(.window)
    }
}
```

- **`@main`** marks the program entry point — no `main.swift` needed.
- An `App` declares **Scenes** instead of windows. `MenuBarExtra` is a scene
  that lives in the menu bar.
- `.menuBarExtraStyle(.window)` makes clicking the icon open a **rich popover
  panel** (any SwiftUI view) instead of a plain dropdown menu.
- **`@StateObject`** creates and *owns* the store for the app's lifetime;
  `.environmentObject(store)` injects it so any descendant view can grab it
  with `@EnvironmentObject` — no prop-drilling through every initializer.
- The label closure is live SwiftUI: when `store.outdatedPackages.count`
  changes, the menu bar badge updates by itself.

One AppKit escape hatch — hide the Dock icon:

```swift
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
```

`.accessory` means "menu bar only, no Dock icon, no app switcher."
`@NSApplicationDelegateAdaptor` is how SwiftUI apps plug in an AppKit delegate.

---

## Chapter 8 — Building the UI Shell

`ContentView` is a vertical stack: header, tab bar, active tab, error banner.

```swift
VStack(spacing: 0) {
    header
    Divider()
    tabBar
    Divider()
    Group {
        switch tab {
        case .installed: InstalledView()
        case .updates: UpdatesView()
        case .issues: IssuesView()
        case .search: SearchView()
        case .settings: SettingsView()
        }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    // error banner if store.lastError != nil
}
.frame(width: 420, height: 480)
```

- SwiftUI is **declarative**: you describe the UI for the current state; when
  `@State private var tab` changes, SwiftUI re-renders the switch.
- `header` and `tabBar` are private computed properties returning `some View` —
  the standard way to keep `body` readable.
- The tab enum drives everything: `Tab.allCases` renders the buttons,
  the switch renders the content. Add a tab case → compiler walks you through
  every place that must change.
- Small touches: `.help("…")` adds tooltips; badges are just `Text` wrapped in
  a `Capsule()` background.

---

## Chapter 9 — Feature Views

**Installed** — filtering is a computed property, not stored state:

```swift
private var filtered: [Package] {
    let query = filter.trimmingCharacters(in: .whitespaces).lowercased()
    guard !query.isEmpty else { return store.packages }
    return store.packages.filter { $0.name.lowercased().contains(query) }
}
```

Derive, don't duplicate: state that can be computed from other state should be.

**PackageRow** is reused by both Installed and Updates — one source of truth for
how a package renders. Buttons kick off async work with
`Task { await store.upgrade(package) }`, and the row swaps to a spinner because
`busyPackageIDs` is `@Published`.

**Issues** is the deprecation centerpiece:

```swift
if let replacement = package.replacement {
    Button("Replace with \(replacement)") {
        Task { await store.replace(package, with: replacement) }
    }
}
Button("Uninstall", role: .destructive) {
    Task { await store.uninstall(package) }
}
```

`role: .destructive` renders the button red — macOS handles the styling.
`replace` installs the successor *first*, then uninstalls the old package, so
you're never left with neither.

**Settings** shows the payoff of `@AppStorage`: `Toggle` and `Picker` bind
directly to persisted values via `store.$autoUpgrade` — the `$` prefix produces
a **Binding** (read-write connection) instead of the value.

---

## Chapter 10 — Build, Run, Ship

```sh
cd ~/Developer/DepDeck
swift build -c release      # optimized binary
.build/release/DepDeck &    # launch it
```

Auto-start at login: see the LaunchAgent snippet in `README.md`.

### Exercises

1. **Add pip support** — write `PipClient` (`pip list --format=json`,
   `pip list --outdated --format=json`) and add a case to `PackageManager`.
   Watch the compiler point at every switch you need to extend.
2. **Notifications** — use `UserNotifications` to alert when a scheduled check
   finds something newly deprecated.
3. **Pinning** — let the user exclude a package from "Update All"
   (hint: an `@AppStorage`-backed `Set<String>` of pinned ids).
4. **Cask support** — `brew info --json=v2 --installed` already returns a
   `casks` array; decode and merge it.
