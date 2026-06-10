import SwiftUI

enum Tab: String, CaseIterable, Identifiable {
    case installed = "Installed"
    case updates = "Updates"
    case issues = "Issues"
    case search = "Search"
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .installed: return "shippingbox"
        case .updates: return "arrow.triangle.2.circlepath"
        case .issues: return "exclamationmark.triangle"
        case .search: return "magnifyingglass"
        case .settings: return "gearshape"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var store: DependencyStore
    @State private var tab: Tab = .installed

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            tabBar
            Divider()

            Group {
                switch tab {
                case .installed: InstalledView()
                case .updates: UpdatesView()
                case .issues: IssuesView()
                case .search: SearchView()
                case .settings: SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if let error = store.lastError {
                Divider()
                HStack(spacing: 6) {
                    Image(systemName: "xmark.octagon.fill").foregroundStyle(.red)
                    Text(error).font(.caption).lineLimit(3)
                    Spacer()
                    Button {
                        store.lastError = nil
                    } label: {
                        Image(systemName: "xmark").font(.caption2)
                    }
                    .buttonStyle(.plain)
                }
                .padding(8)
            }
        }
        .frame(width: 420, height: 480)
    }

    private var header: some View {
        HStack {
            Text("DepDeck").font(.headline)
            Spacer()
            if let refreshed = store.lastRefreshed {
                Text("Updated \(refreshed.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Button {
                Task { await store.refresh(updateIndex: true) }
            } label: {
                if store.isRefreshing {
                    ProgressView().controlSize(.small)
                } else {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .buttonStyle(.plain)
            .disabled(store.isRefreshing)
            .help("Refresh (runs brew update)")

            Button {
                NSApp.terminate(nil)
            } label: {
                Image(systemName: "power")
            }
            .buttonStyle(.plain)
            .help("Quit DepDeck")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var tabBar: some View {
        HStack(spacing: 2) {
            ForEach(Tab.allCases) { item in
                Button {
                    tab = item
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: item.icon)
                        Text(item.rawValue)
                        if item == .updates && !store.outdatedPackages.isEmpty {
                            badge(store.outdatedPackages.count, color: .blue)
                        }
                        if item == .issues && !store.issuePackages.isEmpty {
                            badge(store.issuePackages.count, color: .orange)
                        }
                    }
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(tab == item ? Color.accentColor.opacity(0.2) : .clear)
                    )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    private func badge(_ count: Int, color: Color) -> some View {
        Text("\(count)")
            .font(.caption2.bold())
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(Capsule().fill(color))
            .foregroundStyle(.white)
    }
}

struct ManagerBadge: View {
    let manager: PackageManager

    var body: some View {
        Text(manager.rawValue)
            .font(.caption2.bold())
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(Capsule().fill(color.opacity(0.2)))
            .foregroundStyle(color)
    }

    private var color: Color {
        switch manager {
        case .brew: return .orange
        case .npm: return .red
        case .cargo: return .brown
        }
    }
}
