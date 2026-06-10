# DepDeck Academy — Learn Swift by Building It Yourself

You already *have* a working DepDeck (the menu bar app). This Academy makes you
**rebuild its brain from scratch and give it a new body**: a windowed macOS app.
Nothing here touches the real app — this folder is a fully isolated workspace
with its own package, so break things freely.

**The rules:**

1. You write every `// TODO(you)` yourself. Typing matters — no pasting.
2. Tests are the gatekeeper. A stage is done when `./academy check <n>` is green.
3. Stuck ≥ 20 minutes → `./academy hint <n>`. Still stuck → re-read the matching
   Tutorial chapter (`../Tutorial/index.html`). Solutions are the last resort.
4. The windowed app is your reward: it stays an empty shell until **your** code
   from Stages 1–5 powers it. There is no way through except writing Swift.

```sh
cd ~/Developer/DepDeck/Academy
./academy            # see all commands
./academy check 1    # grade stage 1 (will fail — that's your starting line)
```

---

## Stage 1 — Model the domain  ·  `Sources/AcademyCore/Stage1_Models.swift`

**You learn:** enums, raw values, exhaustive switches, structs, optionals,
computed properties, the ternary and `??` operators.

Five small exercises (1.1–1.5) inside the file. Each is one to five lines.
The file compiles right now — the placeholders return wrong values, and the
tests call you out on exactly what's wrong:

```sh
./academy check 1
```

Read each failure message: it names the exercise (`testIssueLabelPrefersDisabled_1_4`)
and what was expected. Fix one exercise at a time, re-run, repeat. **Green? →**
compare your code with `../Sources/DepDeck/Models.swift` — you just wrote the
real app's foundation.

---

## Stage 2 — Run shell commands  ·  `Stage2_Shell.swift`

**You learn:** `Process`, pipes, async/await, continuations, typed errors.

One big exercise (2.1): implement `Shell.run`. The numbered steps are in the
file as comments; Tutorial chapter 3 explains every concept. The tests check:

- stdout is captured exactly (including multi-line output)
- non-zero exit → throws `ShellError.failed` with the code **and stderr**
- you used a *login* shell (`-lc`) so `brew` is on PATH

This is the hardest jump in the course. Budget a real hour. When it's green,
you've written the engine the entire app runs on.

**Stretch goal:** make stdout/stderr read concurrently (the 64KB deadlock fix —
Tutorial ch. 3 tells the story). Tests stay green; future-you stays unstuck.

---

## Stage 3 — Parse Homebrew JSON  ·  `Stage3_BrewParsing.swift`

**You learn:** `Codable`, nested Decodable structs, `compactMap`, `guard let`,
optional chaining, the adapter pattern.

Implement `parseBrewInfo(_:) -> [Package]`. The JSON shape is documented at the
top of the file, and the tests feed you a realistic fixture including a
deprecated formula (`youtube-dl` → replacement `yt-dlp`) and a never-installed
formula your code must skip.

No network, no brew needed — pure parsing. That's why it's testable.

---

## Stage 4 — Text parsing & version math  ·  `Stage4_TextParsing.swift`

**You learn:** string slicing (`Substring`, `dropFirst/dropLast`, `hasPrefix`),
defensive parsing, and why `"1.10.0" < "1.9.9"` as strings (!).

- **4.1** parse `cargo install --list` output (watch the `(/path)` variant and
  junk lines — the tests include both)
- **4.2** numeric version comparison, component by component

---

## Stage 5 — Store logic  ·  `Stage5_StoreLogic.swift`

**You learn:** pure functions, `filter`/`sorted` with closures, case-insensitive
text handling, `??` chains.

Three exercises: query filtering (trim! lowercase! empty = all), case-insensitive
sort (the tests plant a capitalized `Zellij` to catch naive `<`), and the
replacement-priority chooser. After this stage, all logic for the app exists —
written entirely by you.

```sh
./academy progress     # should show stages 1–5 ✅
```

---

## Stage 6 — The windowed app  ·  `Sources/DepDeckWindowed/`

**You learn:** `WindowGroup` vs `MenuBarExtra`, `NavigationSplitView`,
`@EnvironmentObject`, `@State` + Bindings, Lists, conditional views.

Three files:

- `DepDeckWindowedApp.swift` — **given.** Read it; note `WindowGroup` replaces
  `MenuBarExtra` and `.task { await store.load() }` loads on launch.
- `WindowedStore.swift` — **given, but look closely:** every meaningful line
  calls a function *you* wrote in Stages 1–5.
- `Screens.swift` — **yours.** Exercises 6.1 (package list with live filter)
  and 6.2 (issues screen with Replace/Uninstall affordances). Instructions are
  at the top of each screen.

```sh
./academy run
```

First run shows a window with two "Exercise" placeholders and a working sidebar +
reload button. Build 6.1 → real packages from your Mac appear (your Stage 2 ran
brew, your Stage 3 parsed it, your Stage 5 sorted it). Build 6.2 → your Issues
screen lights up if anything on your system is deprecated.

**Visual checklist for done:**
- [ ] Typing in the filter narrows the list live
- [ ] Rows show name, version, description, and ⚠️ on issue packages
- [ ] Issues screen: friendly empty state, or labeled rows with reasons
- [ ] Stretch: a working "Replace with …" button

---

## Focus mode — `./academy focus` 🔒

Built for ADHD brains and LLM temptation. FocusLock runs timed lockdown
sessions while you work through the stages:

- **Pick a length** (25/45/60/90 min) and **allowlist** your terminal and
  editor. The session window floats in the corner with the countdown.
- **Switch to any other app** → instant fullscreen lock screen, the app gets
  hidden, and you're bounced back to your editor. Every attempt is counted.
- **Open an LLM** (Claude desktop, ChatGPT, Perplexity — or Claude Code in a
  terminal) → the screen goes red and **the timer pauses**. No credit for
  cheated minutes. Close it and the session resumes automatically.
- **Need the tutorial?** Don't unlock a browser — FocusLock has a built-in
  offline viewer for it ("Open Tutorial" button).
- **⌘Q is a confession**: quitting mid-session requires typing
  *"I am choosing to stop early"*. Friction, not handcuffs.

Honest limits: this is a commitment device, not a prison. `killall FocusLock`
from your (allowed) terminal beats it, and your phone exists. Its job is to
make drifting *loud and immediate* instead of silent — which is usually all
an ADHD brain needs to snap back.

Suggested rhythm: one 25-minute session ≈ one or two exercises. Stage 2
deserves a 45.

---

## After graduation

- Do the real exercises: add **pip support to the real app** (Tutorial ch. 10) —
  you now know every layer it touches.
- Compare each of your files against the real app's equivalent. Where you
  differ, decide *which is better*. Sometimes it'll be yours.
- Delete the Solutions folder. You don't need it anymore.
