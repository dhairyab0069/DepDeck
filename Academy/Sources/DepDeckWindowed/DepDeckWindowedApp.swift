import SwiftUI
import AcademyCore

// ╔════════════════════════════════════════════════════════════════════╗
// ║  STAGE 6 — The windowed app                                        ║
// ║                                                                    ║
// ║  Run it:    ./academy run                                          ║
// ║  Concepts:  Tutorial chapters 7–9                                  ║
// ║                                                                    ║
// ║  This file is GIVEN — read it and note what's different from the   ║
// ║  menu bar version: WindowGroup instead of MenuBarExtra, and a      ║
// ║  resizable window with a sidebar instead of a fixed panel.         ║
// ╚════════════════════════════════════════════════════════════════════╝

@main
struct DepDeckWindowedApp: App {
    @StateObject private var store = WindowedStore()

    var body: some Scene {
        WindowGroup("DepDeck") {
            MainWindow()
                .environmentObject(store)
                .task { await store.load() }
        }
        .defaultSize(width: 780, height: 540)
    }
}

enum SidebarSection: String, CaseIterable, Identifiable {
    case packages = "Packages"
    case issues = "Issues"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .packages: return "shippingbox"
        case .issues: return "exclamationmark.triangle"
        }
    }
}

struct MainWindow: View {
    @EnvironmentObject var store: WindowedStore
    @State private var section: SidebarSection = .packages

    var body: some View {
        NavigationSplitView {
            List(SidebarSection.allCases, selection: $section) { item in
                Label(item.rawValue, systemImage: item.icon).tag(item)
            }
            .navigationSplitViewColumnWidth(min: 160, ideal: 180)
        } detail: {
            switch section {
            case .packages: PackagesScreen()
            case .issues: IssuesScreen()
            }
        }
        .toolbar {
            ToolbarItem {
                Button {
                    Task { await store.load() }
                } label: {
                    if store.isLoading {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .disabled(store.isLoading)
                .help("Reload installed packages")
            }
        }
    }
}
