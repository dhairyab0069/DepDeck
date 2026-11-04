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
        let installed = try Self.parseList(listJSON)
        guard !installed.isEmpty else { return [] }

        // npm outdated exits 1 when anything is outdated; swallow that.
        let outdatedJSON = (try? await Shell.run("npm outdated -g --json || true")) ?? "{}"
        let latest = Self.parseOutdated(outdatedJSON)

        var packages: [Package] = []
        for (name, version) in installed {
            // `npm view <pkg> deprecated` prints the message only when deprecated.
            let deprecationMessage = (try? await Shell.run("npm view \(Shell.quote(name)) deprecated 2>/dev/null"))
            packages.append(Self.makePackage(name: name, version: version, latest: latest[name],
                                             deprecationMessage: deprecationMessage))
        }
        return packages.sorted { $0.name < $1.name }
    }

    /// Global packages and their installed versions, from `npm ls -g --json --depth=0`
    /// (entries without a version, such as broken links, are skipped).
    static func parseList(_ json: String) throws -> [String: String] {
        let list = try JSONDecoder().decode(ListResponse.self, from: Data(json.utf8))
        return (list.dependencies ?? [:]).compactMapValues(\.version)
    }

    /// Latest versions of the outdated packages, from `npm outdated -g --json`
    /// (empty output or invalid JSON means nothing is outdated).
    static func parseOutdated(_ json: String) -> [String: String] {
        let entries = (try? JSONDecoder().decode([String: OutdatedEntry].self, from: Data(json.utf8))) ?? [:]
        return entries.compactMapValues(\.latest)
    }

    static func makePackage(name: String, version: String, latest: String?, deprecationMessage: String?) -> Package {
        let message = deprecationMessage?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return Package(
            manager: .npm,
            name: name,
            description: nil,
            installedVersion: version,
            latestVersion: latest ?? version,
            outdated: latest != nil && latest != version,
            deprecated: !message.isEmpty,
            deprecationReason: message.isEmpty ? nil : message,
            disabled: false,
            disableReason: nil,
            replacement: nil
        )
    }

    func install(_ name: String) async throws {
        try await Shell.run("npm install -g \(Shell.quote(name))")
    }

    func upgrade(_ name: String) async throws {
        try await Shell.run("npm install -g \(Shell.quote(name + "@latest"))")
    }

    func uninstall(_ name: String) async throws {
        try await Shell.run("npm uninstall -g \(Shell.quote(name))")
    }
}
