import Foundation

struct CargoClient {
    private struct CrateResponse: Decodable {
        struct Crate: Decodable { let max_stable_version: String? }
        let crate: Crate
    }

    /// One top-level line of `cargo install --list`.
    struct InstalledCrate: Equatable {
        let name: String
        let version: String
        /// False for crates installed from a path or git URL, which crates.io says nothing about.
        let fromRegistry: Bool
    }

    func installedPackages() async throws -> [Package] {
        let output = try await Shell.run("cargo install --list")

        var packages: [Package] = []
        for crate in Self.parseInstallList(output) {
            let latest = crate.fromRegistry ? try? await latestVersion(of: crate.name) : nil

            packages.append(Package(
                manager: .cargo,
                name: crate.name,
                description: nil,
                installedVersion: crate.version,
                latestVersion: latest ?? crate.version,
                outdated: latest != nil && latest != crate.version,
                deprecated: false,
                deprecationReason: nil,
                disabled: false,
                disableReason: nil,
                replacement: nil
            ))
        }
        return packages
    }

    /// Top-level lines look like "ripgrep v14.1.0:" (or "tool v0.1.0 (/path/to/tool):" for a
    /// path or git install); indented lines are the binaries the crate installed.
    static func parseInstallList(_ output: String) -> [InstalledCrate] {
        var crates: [InstalledCrate] = []
        for line in output.split(separator: "\n") {
            guard !line.hasPrefix(" "), line.hasSuffix(":") else { continue }
            let parts = line.dropLast().split(separator: " ")
            guard parts.count >= 2, parts[1].hasPrefix("v") else { continue }
            crates.append(InstalledCrate(name: String(parts[0]),
                                         version: String(parts[1].dropFirst()),
                                         fromRegistry: parts.count == 2))
        }
        return crates
    }

    private func latestVersion(of name: String) async throws -> String? {
        guard let url = URL(string: "https://crates.io/api/v1/crates/\(name)") else { return nil }
        var request = URLRequest(url: url)
        request.setValue("DepDeck (local dependency dashboard)", forHTTPHeaderField: "User-Agent")
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(CrateResponse.self, from: data).crate.max_stable_version
    }

    func search(_ query: String) async throws -> [SearchResult] {
        let output = try await Shell.run("cargo search \(Shell.quote(query)) --limit 20")
        return Self.parseSearch(output)
    }

    /// Result lines look like `ripgrep = "14.1.0"    # description`; trailing notes are ignored.
    static func parseSearch(_ output: String) -> [SearchResult] {
        output
            .split(separator: "\n")
            .compactMap { line -> SearchResult? in
                guard let name = line.split(separator: " ").first, line.contains(" = \"") else { return nil }
                return SearchResult(manager: .cargo, name: String(name))
            }
    }

    func install(_ name: String) async throws {
        try await Shell.run("cargo install \(Shell.quote(name))")
    }

    func upgrade(_ name: String) async throws {
        try await Shell.run("cargo install \(Shell.quote(name)) --force")
    }

    func uninstall(_ name: String) async throws {
        try await Shell.run("cargo uninstall \(Shell.quote(name))")
    }
}
