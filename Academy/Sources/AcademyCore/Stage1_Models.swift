import Foundation

// ╔════════════════════════════════════════════════════════════════════╗
// ║  STAGE 1 — Model the domain                                        ║
// ║                                                                    ║
// ║  Your tasks are marked   // TODO(you):                             ║
// ║  Grade yourself:         ./academy check 1                         ║
// ║  Stuck?                  ./academy hint 1                          ║
// ║  Concepts:               Tutorial chapter 2                        ║
// ╚════════════════════════════════════════════════════════════════════╝
//
// Everything is `public` because the windowed app target imports this
// library — Swift hides non-public symbols across module boundaries.

public enum PackageManager: String, CaseIterable, Identifiable {
    case brew
    case npm
    case cargo

    public var id: String { rawValue }

    // ── EXERCISE 1.1 ─────────────────────────────────────────────────
    // Return a human-friendly name: brew → "Homebrew", npm → "npm",
    // cargo → "cargo".
    //
    // Requirement: use an exhaustive `switch self` with NO `default:`
    // case. That's the whole point of enums — when you add a fourth
    // manager later, the compiler will point here automatically.
    public var displayName: String {
        // TODO(you): replace this placeholder
        return ""
    }
}

public struct Package: Identifiable, Hashable {
    public let manager: PackageManager
    public let name: String
    public var description: String?
    public var installedVersion: String
    public var latestVersion: String?
    public var outdated: Bool
    public var deprecated: Bool
    public var deprecationReason: String?
    public var disabled: Bool
    public var disableReason: String?
    public var replacement: String?

    // Memberwise init with defaults — given to you, it's boilerplate.
    public init(
        manager: PackageManager,
        name: String,
        description: String? = nil,
        installedVersion: String = "1.0.0",
        latestVersion: String? = nil,
        outdated: Bool = false,
        deprecated: Bool = false,
        deprecationReason: String? = nil,
        disabled: Bool = false,
        disableReason: String? = nil,
        replacement: String? = nil
    ) {
        self.manager = manager
        self.name = name
        self.description = description
        self.installedVersion = installedVersion
        self.latestVersion = latestVersion
        self.outdated = outdated
        self.deprecated = deprecated
        self.deprecationReason = deprecationReason
        self.disabled = disabled
        self.disableReason = disableReason
        self.replacement = replacement
    }

    // ── EXERCISE 1.2 ─────────────────────────────────────────────────
    // A unique id combining manager and name, e.g. "brew:ripgrep".
    // Hint: string interpolation \( ) and the enum's rawValue.
    public var id: String {
        // TODO(you)
        return ""
    }

    // ── EXERCISE 1.3 ─────────────────────────────────────────────────
    // A package "has an issue" when it is deprecated OR disabled.
    public var hasIssue: Bool {
        // TODO(you)
        return false
    }

    // ── EXERCISE 1.4 ─────────────────────────────────────────────────
    // "Disabled" if disabled, otherwise "Deprecated".
    // Hint: the ternary operator  condition ? a : b
    public var issueLabel: String {
        // TODO(you)
        return ""
    }

    // ── EXERCISE 1.5 ─────────────────────────────────────────────────
    // The reason to show the user. The disable reason wins over the
    // deprecation reason when both exist.
    // Requirement: use the nil-coalescing operator  ??
    public var issueReason: String? {
        // TODO(you)
        return nil
    }
}
