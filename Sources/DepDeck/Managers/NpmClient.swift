import Foundation

struct NpmClient {
    private struct ListResponse: Decodable {
        struct Dep: Decodable { let version: String? }
        let dependencies: [String: Dep]?
    }

    private struct OutdatedEntry: Decodable {
        let current: String?
        let latest: String?
    }

    func installedPackages() async throws -> [Package] {
        let listJSON = try await Shell.run("npm ls -g --json --depth=0")
        guard let listData = listJSON.data(using: .utf8) else { return [] }
        let list = try JSONDecoder().decode(ListResponse.self, from: listData)
        guard let deps = list.dependencies, !deps.isEmpty else { return [] }

        // npm outdated exits 1 when anything is outdated; swallow that.
        let outdatedJSON = (try? await Shell.run("npm outdated -g --json || true")) ?? "{}"
        let outdated = (try? JSONDecoder().decode(
            [String: OutdatedEntry].self,
            from: outdatedJSON.data(using: .utf8) ?? Data()
        )) ?? [:]

        var packages: [Package] = []
        for (name, dep) in deps {
            guard let version = dep.version else { continue }
            let entry = outdated[name]
            let latest = entry?.latest

            // `npm view <pkg> deprecated` prints the message only when deprecated.
            let deprecationMessage = (try? await Shell.run("npm view '\(name)' deprecated 2>/dev/null"))?
                .trimmingCharacters(in: .whitespacesAndNewlines)

            packages.append(Package(
                manager: .npm,
                name: name,
                description: nil,
                installedVersion: version,
                latestVersion: latest ?? version,
                outdated: latest != nil && latest != version,
                deprecated: !(deprecationMessage ?? "").isEmpty,
                deprecationReason: (deprecationMessage ?? "").isEmpty ? nil : deprecationMessage,
                disabled: false,
                disableReason: nil,
                replacement: nil
            ))
        }
        return packages.sorted { $0.name < $1.name }
    }

    func search(_ query: String) async throws -> [SearchResult] {
        let escaped = query.replacingOccurrences(of: "'", with: "")
        let output = try await Shell.run("npm search '\(escaped)' --json | head -c 200000")
        struct Hit: Decodable { let name: String }
        guard let data = output.data(using: .utf8),
              let hits = try? JSONDecoder().decode([Hit].self, from: data) else { return [] }
        return hits.prefix(20).map { SearchResult(manager: .npm, name: $0.name) }
    }

    func install(_ name: String) async throws {
        try await Shell.run("npm install -g '\(name)'")
    }

    func upgrade(_ name: String) async throws {
        try await Shell.run("npm install -g '\(name)@latest'")
    }

    func uninstall(_ name: String) async throws {
        try await Shell.run("npm uninstall -g '\(name)'")
    }
}
