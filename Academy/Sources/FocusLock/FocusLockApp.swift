import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    // ⌘Q during a session doesn't kill the guard — it opens the
    // confession sheet instead.
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if SessionModel.shared.isActive {
            SessionModel.shared.showEarlyEndSheet = true
            NSApp.activate(ignoringOtherApps: true)
            return .terminateCancel
        }
        return .terminateNow
    }
}

@main
struct FocusLockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var model = SessionModel.shared

    var body: some Scene {
        WindowGroup("FocusLock") {
            ContentView()
                .environmentObject(model)
                .background(WindowAccessor { window in
                    SessionModel.shared.attach(window: window)
                })
        }
        .defaultSize(width: 460, height: 560)

        // Built-in offline tutorial viewer, so browsers can stay blocked.
        WindowGroup("Tutorial Reference", id: "reference") {
            ReferenceView()
        }
        .defaultSize(width: 980, height: 720)
    }
}

struct ContentView: View {
    @EnvironmentObject var model: SessionModel

    var body: some View {
        Group {
            switch model.state {
            case .idle: SetupView()
            case .running: SessionView()
            case .finished: FinishedView()
            }
        }
        .sheet(isPresented: $model.showEarlyEndSheet) {
            EarlyEndSheet()
        }
    }
}

struct WindowAccessor: NSViewRepresentable {
    let callback: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { callback(view.window) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
