# Stage 5 — Reference Solution

```swift
// 5.1
public func filterPackages(_ packages: [Package], query: String) -> [Package] {
    let q = query.trimmingCharacters(in: .whitespaces).lowercased()
    guard !q.isEmpty else { return packages }
    return packages.filter { $0.name.lowercased().contains(q) }
}

// 5.2
public func sortedByName(_ packages: [Package]) -> [Package] {
    packages.sorted { $0.name.lowercased() < $1.name.lowercased() }
}

// 5.3
public func chooseReplacement(
    disableFormula: String?,
    deprecationFormula: String?,
    disableCask: String?,
    deprecationCask: String?
) -> String? {
    disableFormula ?? deprecationFormula ?? disableCask ?? deprecationCask
}
```

Note the single-expression bodies: when a function is one expression, Swift
lets you omit `return`. 5.3 really is one line — the `??` chain *is* the
priority order, written directly.
