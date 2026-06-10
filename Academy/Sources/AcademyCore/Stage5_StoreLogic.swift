import Foundation

// ╔════════════════════════════════════════════════════════════════════╗
// ║  STAGE 5 — Store logic (pure functions)                           ║
// ║                                                                    ║
// ║  Grade yourself:  ./academy check 5                                ║
// ║  Concepts:        Tutorial chapter 6                               ║
// ╚════════════════════════════════════════════════════════════════════╝
//
// The real app's Store mixes logic with @Published state. Here you write
// the logic as PURE functions (input → output, no side effects), which is
// what makes them testable. The windowed app calls these directly.

// ── EXERCISE 5.1 ─────────────────────────────────────────────────────
// Filter packages by a search query.
// Rules:
//   • Trim whitespace from the query; lowercase it.
//   • An empty (or all-whitespace) query returns ALL packages.
//   • Otherwise: keep packages whose lowercased name CONTAINS the query.
public func filterPackages(_ packages: [Package], query: String) -> [Package] {
    // TODO(you)
    return []
}

// ── EXERCISE 5.2 ─────────────────────────────────────────────────────
// Sort packages by name, case-insensitively.
// ("Zebra" must come after "apple" — naive `<` on strings puts all
// uppercase letters first because of their ASCII values.)
public func sortedByName(_ packages: [Package]) -> [Package] {
    // TODO(you)
    return []
}

// ── EXERCISE 5.3 ─────────────────────────────────────────────────────
// Pick the replacement to suggest for a broken package. Priority order
// (first non-nil wins) — disabled is more severe than deprecated, and
// formulae beat casks:
//
//   1. disableFormula
//   2. deprecationFormula
//   3. disableCask
//   4. deprecationCask
//
// Requirement: one expression chaining the ?? operator.
public func chooseReplacement(
    disableFormula: String?,
    deprecationFormula: String?,
    disableCask: String?,
    deprecationCask: String?
) -> String? {
    // TODO(you)
    return nil
}
