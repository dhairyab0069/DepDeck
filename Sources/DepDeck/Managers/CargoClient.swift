import Foundation

struct CargoClient {
    private struct CrateResponse: Decodable {
        struct Crate: Decodable { let max_stable_version: String? }
        let crate: Crate
    }

    func installedPackages() async throws -> [Package] {
        let output = try await Shell.run("cargo install --list")

        // Top-level lines look like "ripgrep v14.1.0:"; indented lines are binaries.
        var packages: [Package] = []
        for line in output.split(separator: "\n") {
            guard !line.hasPrefix(" "), line.hasSuffix(":") else { continue }
            let parts = line.dropLast().split(separator: " ")
            guard parts.count >= 2, parts[1].hasPrefix("v") else { continue }
            let name = String(parts[0])
            let version = String(parts[1].dropFirst())

            let latest = try? await latestVersion(of: name)

            packages.append(Package(
                manager: .cargo,
                name: name,
                description: nil,
                installedVersion: version,
                latestVersion: latest ?? version,
                outdated: latest != nil && latest != version,
                deprecated: false,
                deprecationReason: nil,
                disabled: false,
                disableReason: nil,
                replacement: nil
            ))
        }
        return packages
    }

    private func latestVersion(of name: String) async throws -> String? {
        guard let url = URL(string: "https://crates.io/api/v1/crates/\(name)") else { return nil }
        var request = URLRequest(url: url)
        request.setValue("DepDeck (local dependency dashboard)", forHTTPHeaderField: "User-Agent")
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(CrateResponse.self, from: data).crate.max_stable_version
    }

    func search(_ query: String) async throws -> [SearchResult] {
        let escaped = query.replacingOccurrences(of: "'", with: "")
        let output = try await Shell.run("cargo search '\(escaped)' --limit 20")
        return output
            .split(separator: "\n")
            .compactMap { line -> SearchResult? in
                guard let name = line.split(separator: " ").first, line.contains(" = \"") else { return nil }
                return SearchResult(manager: .cargo, name: String(name))
            }
    }

    func install(_ name: String) async throws {
        try await Shell.run("cargo install '\(name)'")
    }

    func upgrade(_ name: String) async throws {
        try await Shell.run("cargo install '\(name)' --force")
    }

    func uninstall(_ name: String) async throws {
        try await Shell.run("cargo uninstall '\(name)'")
    }
}
