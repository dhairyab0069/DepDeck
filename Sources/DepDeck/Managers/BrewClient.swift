import Foundation

struct BrewClient {
    private struct InfoResponse: Decodable {
        let formulae: [Formula]
    }

    private struct Formula: Decodable {
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

    func installedPackages() async throws -> [Package] {
        let json = try await Shell.run("brew info --json=v2 --installed")
        return try Self.parseInstalled(json)
    }

    /// Turns the output of `brew info --json=v2 --installed` into packages
    /// (formulae that are not actually installed are skipped).
    static func parseInstalled(_ json: String) throws -> [Package] {
        guard let data = json.data(using: .utf8) else { return [] }
        let response = try JSONDecoder().decode(InfoResponse.self, from: data)

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

    func updateIndex() async throws {
        try await Shell.run("brew update")
    }

    func search(_ query: String) async throws -> [SearchResult] {
        let output = try await Shell.run("brew search --formula \(Shell.quote(query))")
        return Self.parseSearch(output)
    }

    /// `brew search` prints one formula per line, with `==>` section headings when it searches several kinds.
    static func parseSearch(_ output: String) -> [SearchResult] {
        output
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("==>") }
            .map { SearchResult(manager: .brew, name: $0) }
    }

    func install(_ name: String) async throws {
        try await Shell.run("brew install \(Shell.quote(name))")
    }

    func upgrade(_ name: String) async throws {
        try await Shell.run("brew upgrade \(Shell.quote(name))")
    }

    func uninstall(_ name: String) async throws {
        try await Shell.run("brew uninstall \(Shell.quote(name))")
    }
}
