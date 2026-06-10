import Foundation
import SwiftUI

@MainActor
final class DependencyStore: ObservableObject {
    @Published var packages: [Package] = []
    @Published var searchResults: [SearchResult] = []
    @Published var isRefreshing = false
    @Published var isSearching = false
    @Published var busyPackageIDs: Set<String> = []
    @Published var lastError: String?
    @Published var lastRefreshed: Date?

    @AppStorage("autoUpgrade") var autoUpgrade = false
    @AppStorage("checkIntervalHours") var checkIntervalHours = 6.0

    private let brew = BrewClient()
    private let npm = NpmClient()
    private let cargo = CargoClient()
    private var timerTask: Task<Void, Never>?

    var outdatedPackages: [Package] { packages.filter(\.outdated) }
    var issuePackages: [Package] { packages.filter(\.hasIssue) }

    init() {
        schedulePeriodicChecks()
        Task { await refresh(updateIndex: false) }
    }

    func schedulePeriodicChecks() {
        timerTask?.cancel()
        let hours = max(checkIntervalHours, 0.5)
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(hours * 3600))
                guard let self, !Task.isCancelled else { return }
                await self.refresh(updateIndex: true)
                if self.autoUpgrade {
                    await self.upgradeAll()
                }
            }
        }
    }

    func refresh(updateIndex: Bool) async {
        guard !isRefreshing else { return }
        isRefreshing = true
        lastError = nil
        defer {
            isRefreshing = false
            lastRefreshed = Date()
        }

        if updateIndex {
            do { try await brew.updateIndex() } catch { lastError = error.localizedDescription }
        }

        async let brewResult = gather { try await self.brew.installedPackages() }
        async let npmResult = gather { try await self.npm.installedPackages() }
        async let cargoResult = gather { try await self.cargo.installedPackages() }

        let results = await [brewResult, npmResult, cargoResult]
        packages = results.flatMap(\.0).sorted { $0.name.lowercased() < $1.name.lowercased() }
        if let firstError = results.compactMap(\.1).first {
            lastError = firstError
        }
    }

    private func gather(_ work: @escaping () async throws -> [Package]) async -> ([Package], String?) {
        do { return (try await work(), nil) }
        catch { return ([], error.localizedDescription) }
    }

    func search(_ query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            searchResults = []
            return
        }
        isSearching = true
        defer { isSearching = false }

        async let brewHits = (try? brew.search(trimmed)) ?? []
        async let cargoHits = (try? cargo.search(trimmed)) ?? []
        searchResults = await brewHits + cargoHits
    }

    func upgrade(_ package: Package) async {
        await perform(on: package) {
            switch package.manager {
            case .brew: try await self.brew.upgrade(package.name)
            case .npm: try await self.npm.upgrade(package.name)
            case .cargo: try await self.cargo.upgrade(package.name)
            }
        }
    }

    func upgradeAll() async {
        for package in outdatedPackages {
            await upgrade(package)
        }
    }

    func uninstall(_ package: Package) async {
        await perform(on: package) {
            switch package.manager {
            case .brew: try await self.brew.uninstall(package.name)
            case .npm: try await self.npm.uninstall(package.name)
            case .cargo: try await self.cargo.uninstall(package.name)
            }
        }
    }

    /// Installs the suggested replacement, then removes the deprecated package.
    func replace(_ package: Package, with replacement: String) async {
        await perform(on: package) {
            switch package.manager {
            case .brew:
                try await self.brew.install(replacement)
                try await self.brew.uninstall(package.name)
            case .npm:
                try await self.npm.install(replacement)
                try await self.npm.uninstall(package.name)
            case .cargo:
                try await self.cargo.install(replacement)
                try await self.cargo.uninstall(package.name)
            }
        }
    }

    func install(_ result: SearchResult) async {
        busyPackageIDs.insert(result.id)
        defer { busyPackageIDs.remove(result.id) }
        do {
            switch result.manager {
            case .brew: try await brew.install(result.name)
            case .npm: try await npm.install(result.name)
            case .cargo: try await cargo.install(result.name)
            }
            await refresh(updateIndex: false)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func perform(on package: Package, _ work: () async throws -> Void) async {
        busyPackageIDs.insert(package.id)
        defer { busyPackageIDs.remove(package.id) }
        do {
            try await work()
            await refresh(updateIndex: false)
        } catch {
            lastError = error.localizedDescription
        }
    }
}
