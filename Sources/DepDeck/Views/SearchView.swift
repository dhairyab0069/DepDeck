import SwiftUI

struct SearchView: View {
    @EnvironmentObject var store: DependencyStore
    @State private var query = ""

    private var installedNames: Set<String> {
        Set(store.packages.map(\.id))
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                TextField("Search Homebrew and crates.io…", text: $query)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { runSearch() }
                Button("Search") { runSearch() }
                    .disabled(query.trimmingCharacters(in: .whitespaces).isEmpty || store.isSearching)
            }
            .padding(8)

            if store.isSearching {
                Spacer()
                ProgressView("Searching…")
                Spacer()
            } else if store.searchResults.isEmpty {
                Spacer()
                Text("Search for a tool to install")
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                List(store.searchResults) { result in
                    HStack {
                        Text(result.name).font(.system(.body, design: .monospaced))
                        ManagerBadge(manager: result.manager)
                        Spacer()
                        if store.busyPackageIDs.contains(result.id) {
                            ProgressView().controlSize(.small)
                        } else if installedNames.contains(result.id) {
                            Text("Installed")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Button("Install") {
                                Task { await store.install(result) }
                            }
                            .controlSize(.small)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private func runSearch() {
        Task { await store.search(query) }
    }
}
