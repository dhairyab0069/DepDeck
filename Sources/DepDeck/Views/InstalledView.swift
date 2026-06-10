import SwiftUI

struct InstalledView: View {
    @EnvironmentObject var store: DependencyStore
    @State private var filter = ""

    private var filtered: [Package] {
        let query = filter.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else { return store.packages }
        return store.packages.filter { $0.name.lowercased().contains(query) }
    }

    var body: some View {
        VStack(spacing: 0) {
            TextField("Filter installed packages…", text: $filter)
                .textFieldStyle(.roundedBorder)
                .padding(8)

            if store.packages.isEmpty && store.isRefreshing {
                Spacer()
                ProgressView("Loading packages…")
                Spacer()
            } else {
                List(filtered) { package in
                    PackageRow(package: package)
                }
                .listStyle(.plain)
            }
        }
    }
}

struct PackageRow: View {
    @EnvironmentObject var store: DependencyStore
    let package: Package

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(package.name).font(.system(.body, design: .monospaced))
                    ManagerBadge(manager: package.manager)
                    if package.hasIssue {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                            .help(package.issueReason ?? package.issueLabel)
                    }
                }
                if let desc = package.description {
                    Text(desc).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
                Text(versionText)
                    .font(.caption2)
                    .foregroundStyle(package.outdated ? .blue : .secondary)
            }
            Spacer()

            if store.busyPackageIDs.contains(package.id) {
                ProgressView().controlSize(.small)
            } else {
                if package.outdated {
                    Button("Update") {
                        Task { await store.upgrade(package) }
                    }
                    .controlSize(.small)
                }
                Button {
                    Task { await store.uninstall(package) }
                } label: {
                    Image(systemName: "trash")
                }
                .controlSize(.small)
                .help("Uninstall \(package.name)")
            }
        }
        .padding(.vertical, 2)
    }

    private var versionText: String {
        if package.outdated, let latest = package.latestVersion {
            return "\(package.installedVersion) → \(latest)"
        }
        return package.installedVersion
    }
}
