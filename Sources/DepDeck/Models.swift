import Foundation

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

    var badgeColor: String {
        switch self {
        case .brew: return "orange"
        case .npm: return "red"
        case .cargo: return "brown"
        }
    }
}

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
    /// Suggested replacement formula/package, if the manager provides one.
    var replacement: String?

    var id: String { "\(manager.rawValue):\(name)" }

    var hasIssue: Bool { deprecated || disabled }

    var issueLabel: String { disabled ? "Disabled" : "Deprecated" }

    var issueReason: String? { disableReason ?? deprecationReason }
}

struct SearchResult: Identifiable, Hashable {
    let manager: PackageManager
    let name: String

    var id: String { "\(manager.rawValue):\(name)" }
}
