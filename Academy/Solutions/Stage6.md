# Stage 6 — Reference Solution

## 6.1 — PackagesScreen

```swift
struct PackagesScreen: View {
    @EnvironmentObject var store: WindowedStore
    @State private var filter = ""

    private var filtered: [Package] {
        filterPackages(store.packages, query: filter)
    }

    var body: some View {
        VStack(spacing: 0) {
            TextField("Filter packages…", text: $filter)
                .textFieldStyle(.roundedBorder)
                .padding(10)

            List(filtered) { package in
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(package.name)
                            .font(.system(.body, design: .monospaced))
                        if package.hasIssue {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                                .font(.caption)
                        }
                    }
                    if let desc = package.description {
                        Text(desc).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    }
                    if package.outdated, let latest = package.latestVersion {
                        Text("\(package.installedVersion) → \(latest)")
                            .font(.caption2).foregroundStyle(.blue)
                    } else {
                        Text(package.installedVersion)
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 2)
            }
            .listStyle(.plain)
        }
    }
}
```

## 6.2 — IssuesScreen

```swift
struct IssuesScreen: View {
    @EnvironmentObject var store: WindowedStore

    var body: some View {
        if store.issuePackages.isEmpty {
            ContentUnavailableView(
                "No deprecated or disabled packages",
                systemImage: "checkmark.shield.fill"
            )
        } else {
            List(store.issuePackages) { package in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(package.name)
                            .font(.system(.body, design: .monospaced))
                        Text(package.issueLabel)
                            .font(.caption2.bold())
                            .padding(.horizontal, 6).padding(.vertical, 1)
                            .background(Capsule().fill(package.disabled ? Color.red : Color.orange))
                            .foregroundStyle(.white)
                    }
                    if let reason = package.issueReason {
                        Text(reason).font(.caption).foregroundStyle(.secondary)
                    }
                    if let replacement = package.replacement {
                        Button("Replace with \(replacement)") {
                            Task {
                                try? await Shell.run(
                                    "brew install '\(replacement)' && brew uninstall '\(package.name)'"
                                )
                                await store.load()
                            }
                        }
                        .controlSize(.small)
                    }
                }
                .padding(.vertical, 4)
            }
            .listStyle(.plain)
        }
    }
}
```

The stretch-goal replace button is included — note install runs *before*
uninstall so you're never left without either tool.
