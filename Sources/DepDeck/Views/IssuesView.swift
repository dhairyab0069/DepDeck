import SwiftUI

struct IssuesView: View {
    @EnvironmentObject var store: DependencyStore

    var body: some View {
        if store.issuePackages.isEmpty {
            VStack(spacing: 8) {
                Spacer()
                Image(systemName: "checkmark.shield.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.green)
                Text("No deprecated or disabled packages")
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity)
        } else {
            List(store.issuePackages) { package in
                IssueRow(package: package)
            }
            .listStyle(.plain)
        }
    }
}

struct IssueRow: View {
    @EnvironmentObject var store: DependencyStore
    let package: Package

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(package.name).font(.system(.body, design: .monospaced))
                ManagerBadge(manager: package.manager)
                Text(package.issueLabel)
                    .font(.caption2.bold())
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(package.disabled ? Color.red : Color.orange))
                    .foregroundStyle(.white)
                Spacer()
            }

            if let reason = package.issueReason {
                Text(reason)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                if store.busyPackageIDs.contains(package.id) {
                    ProgressView().controlSize(.small)
                } else {
                    if let replacement = package.replacement {
                        Button("Replace with \(replacement)") {
                            Task { await store.replace(package, with: replacement) }
                        }
                        .controlSize(.small)
                    }
                    Button("Uninstall", role: .destructive) {
                        Task { await store.uninstall(package) }
                    }
                    .controlSize(.small)
                }
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}
