import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: DependencyStore

    var body: some View {
        Form {
            Section {
                Toggle("Automatically install updates", isOn: store.$autoUpgrade)
                Text("When enabled, outdated packages are upgraded during each scheduled check.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Picker("Check for updates every", selection: store.$checkIntervalHours) {
                    Text("1 hour").tag(1.0)
                    Text("3 hours").tag(3.0)
                    Text("6 hours").tag(6.0)
                    Text("12 hours").tag(12.0)
                    Text("Daily").tag(24.0)
                }
                .onChange(of: store.checkIntervalHours) {
                    store.schedulePeriodicChecks()
                }
            }

            Section {
                LabeledContent("Tracked managers", value: "Homebrew, npm (global), cargo")
                LabeledContent("Packages tracked", value: "\(store.packages.count)")
            }
        }
        .formStyle(.grouped)
        .padding(.top, 4)
    }
}
