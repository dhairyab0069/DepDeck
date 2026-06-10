import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu bar only — no Dock icon.
        NSApp.setActivationPolicy(.accessory)
    }
}

@main
struct DepDeckApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var store = DependencyStore()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(store)
        } label: {
            let outdated = store.outdatedPackages.count
            let issues = store.issuePackages.count
            if issues > 0 {
                Image(systemName: "shippingbox.fill")
                Text("\(outdated)⚠︎\(issues)")
            } else if outdated > 0 {
                Image(systemName: "shippingbox.fill")
                Text("\(outdated)")
            } else {
                Image(systemName: "shippingbox")
            }
        }
        .menuBarExtraStyle(.window)
    }
}
