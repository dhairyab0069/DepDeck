import SwiftUI
import AcademyCore

// ╔════════════════════════════════════════════════════════════════════╗
// ║  EXERCISES 6.1 & 6.2 — you build the screens                       ║
// ║  These are checked visually: ./academy run                         ║
// ╚════════════════════════════════════════════════════════════════════╝

// ── EXERCISE 6.1 — the package list ──────────────────────────────────
// Replace the placeholder with:
//
//   1. A @State var filter = "" and a TextField("Filter…", text: $filter)
//      at the top (Tutorial ch. 9 shows the layout).
//   2. A computed property using YOUR filterPackages(_:query:) from
//      Stage 5 — derive, don't duplicate.
//   3. A List over the filtered packages. Each row should show at least:
//        • the name (try .font(.system(.body, design: .monospaced)))
//        • installedVersion in secondary style
//        • the description, if present (if let)
//        • a small orange exclamation icon when package.hasIssue
//   4. Wrap rows + text field in a VStack(spacing: 0).
//
// Stretch: show "x → y" in blue when package.outdated (see PackageRow
// in the real app *after* you've got your own version working).
struct PackagesScreen: View {
    @EnvironmentObject var store: WindowedStore

    var body: some View {
        // TODO(you): Exercise 6.1 — replace this placeholder
        ContentUnavailableView(
            "Exercise 6.1",
            systemImage: "hammer",
            description: Text("Build the package list here — instructions at the top of Screens.swift")
        )
    }
}

// ── EXERCISE 6.2 — the issues screen ─────────────────────────────────
// Replace the placeholder with:
//
//   1. If store.issuePackages is empty: a friendly "all clear" view
//      (ContentUnavailableView with a checkmark works great).
//   2. Otherwise a List where each row shows:
//        • name + your issueLabel from Stage 1 in a colored capsule
//          (red when disabled, orange when deprecated)
//        • the issueReason text, if present
//        • if package.replacement is non-nil, a Button("Replace with …")
//          — it can just print() for now; wiring real installs is the
//          stretch goal.
//
// Stretch: add the real replace action by calling
//   Shell.run("brew install '\(replacement)' && brew uninstall '\(pkg.name)'")
// inside a Task, then await store.load().
struct IssuesScreen: View {
    @EnvironmentObject var store: WindowedStore

    var body: some View {
        // TODO(you): Exercise 6.2 — replace this placeholder
        ContentUnavailableView(
            "Exercise 6.2",
            systemImage: "hammer",
            description: Text("Build the issues screen here — instructions at the top of Screens.swift")
        )
    }
}
