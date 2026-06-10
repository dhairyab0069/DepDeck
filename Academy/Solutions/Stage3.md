# Stage 3 — Reference Solution

```swift
private struct BrewInfoResponse: Decodable {
    let formulae: [BrewFormula]
}

private struct BrewFormula: Decodable {
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
    let deprecation_replacement_cask: String?
    let disabled: Bool
    let disable_reason: String?
    let disable_replacement_formula: String?
    let disable_replacement_cask: String?
}

public func parseBrewInfo(_ json: String) throws -> [Package] {
    guard let data = json.data(using: .utf8) else { return [] }
    let response = try JSONDecoder().decode(BrewInfoResponse.self, from: data)

    return response.formulae.compactMap { formula in
        guard let current = formula.installed.last?.version else { return nil }
        return Package(
            manager: .brew,
            name: formula.name,
            description: formula.desc,
            installedVersion: current,
            latestVersion: formula.versions.stable,
            outdated: formula.outdated,
            deprecated: formula.deprecated,
            deprecationReason: formula.deprecation_reason,
            disabled: formula.disabled,
            disableReason: formula.disable_reason,
            replacement: formula.disable_replacement_formula
                ?? formula.deprecation_replacement_formula
                ?? formula.disable_replacement_cask
                ?? formula.deprecation_replacement_cask
        )
    }
}
```

Key ideas: the Decodable structs are `private` — brew's JSON shape is an
implementation detail, the rest of the app only sees `Package` (adapter
pattern). `compactMap` + `guard let` skips never-installed formulae in one
clean motion.
