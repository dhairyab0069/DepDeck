# Stage 1 — Reference Solution

```swift
// 1.1
public var displayName: String {
    switch self {
    case .brew: return "Homebrew"
    case .npm: return "npm"
    case .cargo: return "cargo"
    }
}

// 1.2
public var id: String { "\(manager.rawValue):\(name)" }

// 1.3
public var hasIssue: Bool { deprecated || disabled }

// 1.4
public var issueLabel: String { disabled ? "Disabled" : "Deprecated" }

// 1.5
public var issueReason: String? { disableReason ?? deprecationReason }
```

Why it matters: the exhaustive switch in 1.1 is the contract that makes adding
a fourth package manager safe — the compiler finds every place that needs
updating. 1.5's `??` reads as "prefer the disable reason, fall back to the
deprecation reason."
