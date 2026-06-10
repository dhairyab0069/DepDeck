import Foundation

// ╔════════════════════════════════════════════════════════════════════╗
// ║  STAGE 4 — Parse plain text (cargo) & compare versions            ║
// ║                                                                    ║
// ║  Grade yourself:  ./academy check 4                                ║
// ║  Concepts:        Tutorial chapter 5                               ║
// ╚════════════════════════════════════════════════════════════════════╝

public struct CargoTool: Equatable {
    public let name: String
    public let version: String

    public init(name: String, version: String) {
        self.name = name
        self.version = version
    }
}

// ── EXERCISE 4.1 ─────────────────────────────────────────────────────
// `cargo install --list` prints text like:
//
//     ripgrep v14.1.0:
//         rg
//     cargo-edit v0.12.2 (/Users/you/src/cargo-edit):
//         cargo-add
//
// Rules:
//   • Header lines start at column 0 and end with ":".
//     Indented lines are binary names — skip them.
//   • The first word is the tool name; the second starts with "v"
//     followed by the version (strip the "v").
//   • Ignore any line that doesn't fit the pattern (defensive parsing!).
//
// Useful tools: split(separator:), hasPrefix, hasSuffix, dropLast,
// dropFirst, guard/continue. Remember: slicing returns Substring —
// wrap in String(...) to store it.
public func parseCargoInstallList(_ output: String) -> [CargoTool] {
    // TODO(you)
    return []
}

// ── EXERCISE 4.2 ─────────────────────────────────────────────────────
// Is version `a` strictly newer than `b`?
//
// You CANNOT compare version strings with `>` — "1.10.0" < "1.9.9" as
// strings because "1" < "9" character-wise. You must compare numerically,
// component by component:
//
//   1. Split both on "." and convert each part with Int(...) ?? 0.
//   2. Walk the components left to right; the first position where they
//      differ decides the answer.
//   3. If one version is shorter, treat missing components as 0
//      ("1.2" == "1.2.0", and "1.2.3" is newer than "1.2").
//
// Expected: isVersion("1.10.0", newerThan: "1.9.9") == true
//           isVersion("1.0.0",  newerThan: "1.0.0") == false
public func isVersion(_ a: String, newerThan b: String) -> Bool {
    // TODO(you)
    return false
}
