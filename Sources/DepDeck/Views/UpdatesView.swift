import SwiftUI

struct UpdatesView: View {
    @EnvironmentObject var store: DependencyStore

    var body: some View {
        VStack(spacing: 0) {
            if store.outdatedPackages.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.green)
                    Text("Everything is up to date")
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                HStack {
                    Text("\(store.outdatedPackages.count) update\(store.outdatedPackages.count == 1 ? "" : "s") available")
                        .font(.callout)
                    Spacer()
                    Button("Update All") {
                        Task { await store.upgradeAll() }
                    }
                    .disabled(!store.busyPackageIDs.isEmpty)
                }
                .padding(8)
                Divider()
                List(store.outdatedPackages) { package in
                    PackageRow(package: package)
                }
                .listStyle(.plain)
            }
        }
    }
}
