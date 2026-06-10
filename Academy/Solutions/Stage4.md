# Stage 4 — Reference Solution

```swift
// 4.1
public func parseCargoInstallList(_ output: String) -> [CargoTool] {
    var tools: [CargoTool] = []
    for line in output.split(separator: "\n") {
        guard !line.hasPrefix(" "), line.hasSuffix(":") else { continue }
        let parts = line.dropLast().split(separator: " ")
        guard parts.count >= 2, parts[1].hasPrefix("v") else { continue }
        tools.append(CargoTool(
            name: String(parts[0]),
            version: String(parts[1].dropFirst())
        ))
    }
    return tools
}

// 4.2
public func isVersion(_ a: String, newerThan b: String) -> Bool {
    let aParts = a.split(separator: ".").map { Int($0) ?? 0 }
    let bParts = b.split(separator: ".").map { Int($0) ?? 0 }
    for i in 0..<max(aParts.count, bParts.count) {
        let x = i < aParts.count ? aParts[i] : 0
        let y = i < bParts.count ? bParts[i] : 0
        if x != y { return x > y }
    }
    return false
}
```

Notes: in 4.1 the `(/path)` variant works for free — `parts[1]` is still the
version because we only split on spaces and only checked the first two parts.
In 4.2 the early `return x > y` on the *first* difference is the whole
algorithm; the final `return false` handles exact equality.
