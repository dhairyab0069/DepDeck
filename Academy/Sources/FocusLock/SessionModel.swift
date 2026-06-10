import AppKit
import SwiftUI

@MainActor
final class SessionModel: ObservableObject {
    static let shared = SessionModel()

    enum State { case idle, running, finished }

    struct AppChoice: Identifiable {
        let id: String   // bundle id, falling back to app name
        let name: String
    }

    @Published var state: State = .idle
    @Published var remaining = 0
    @Published var totalSeconds = 0
    @Published var violations = 0
    @Published var lastViolator: String?
    @Published var llmProcesses: [String] = []
    @Published var runningApps: [AppChoice] = []
    @Published var allowedIDs: Set<String> = []
    @Published var showEarlyEndSheet = false

    var isActive: Bool { state == .running }
    var llmPaused: Bool { !llmProcesses.isEmpty }

    private let overlay = OverlayController()
    private var timerTask: Task<Void, Never>?
    private var llmTask: Task<Void, Never>?
    private var observer: NSObjectProtocol?
    private var lastAllowedApp: NSRunningApplication?
    private weak var window: NSWindow?
    private let myPID = ProcessInfo.processInfo.processIdentifier

    // Terminals and editors get a head start; everything else is opt-in.
    private static let defaultAllowed: Set<String> = [
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "com.github.wez.wezterm",
        "io.alacritty",
        "com.microsoft.VSCode",
        "com.apple.dt.Xcode",
        "dev.zed.Zed",
        "com.sublimetext.4",
        "org.vim.MacVim"
    ]

    init() {
        let saved = UserDefaults.standard.stringArray(forKey: "allowedIDs") ?? []
        allowedIDs = Set(saved).union(Self.defaultAllowed)
        refreshRunningApps()
    }

    func refreshRunningApps() {
        runningApps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular && $0.processIdentifier != myPID }
            .map { AppChoice(id: $0.bundleIdentifier ?? ($0.localizedName ?? "?"),
                             name: $0.localizedName ?? "Unknown") }
            .sorted { $0.name.lowercased() < $1.name.lowercased() }
    }

    func toggleAllowed(_ id: String) {
        if allowedIDs.contains(id) { allowedIDs.remove(id) } else { allowedIDs.insert(id) }
        UserDefaults.standard.set(Array(allowedIDs), forKey: "allowedIDs")
    }

    func attach(window: NSWindow?) {
        self.window = window
    }

    // ───────────────────────── session lifecycle ─────────────────────────

    func start(minutes: Int) {
        guard state != .running else { return }
        totalSeconds = max(minutes, 1) * 60
        remaining = totalSeconds
        violations = 0
        lastViolator = nil
        llmProcesses = []
        state = .running

        // The session window floats above your editor on every Space.
        window?.level = .floating
        window?.collectionBehavior.insert(.canJoinAllSpaces)

        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil, queue: .main
        ) { [weak self] note in
            guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
            Task { @MainActor in self?.appActivated(app) }
        }

        timerTask = Task { @MainActor [weak self] in
            while let self, self.isActive, self.remaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                guard self.isActive else { return }
                if !self.llmPaused { self.remaining -= 1 }
            }
            guard let self, self.isActive, self.remaining <= 0 else { return }
            self.end(completed: true)
        }

        llmTask = Task { @MainActor [weak self] in
            while let self, self.isActive {
                let found = await Self.scanLLMProcesses()
                guard self.isActive else { return }
                let hadLLMs = !self.llmProcesses.isEmpty
                self.llmProcesses = found
                if !found.isEmpty {
                    self.overlay.show(LLMOverlay(processes: found))
                } else if hadLLMs {
                    self.overlay.hide()
                    self.lastAllowedApp?.activate()
                }
                try? await Task.sleep(for: .seconds(5))
            }
        }
    }

    func end(completed: Bool) {
        state = completed ? .finished : .idle
        timerTask?.cancel()
        llmTask?.cancel()
        if let observer { NSWorkspace.shared.notificationCenter.removeObserver(observer) }
        observer = nil
        llmProcesses = []
        overlay.hide()
        window?.level = .normal
        NSApp.activate(ignoringOtherApps: true)
    }

    // ───────────────────────── app-switch guard ─────────────────────────

    private func appActivated(_ app: NSRunningApplication) {
        guard isActive else { return }
        if app.processIdentifier == myPID { return }

        let id = app.bundleIdentifier ?? (app.localizedName ?? "?")
        if allowedIDs.contains(id) {
            lastAllowedApp = app
            return
        }

        violations += 1
        lastViolator = app.localizedName ?? id
        app.hide()
        overlay.show(ViolationOverlay(appName: lastViolator ?? "that app", violations: violations))

        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(2.5))
            guard let self, self.llmProcesses.isEmpty else { return }
            self.overlay.hide()
            self.lastAllowedApp?.activate()
        }
    }

    // ───────────────────────── LLM watchdog ─────────────────────────

    // Two detection layers, because pgrep can't be trusted here:
    // Claude Code rewrites its kernel process name to its version string,
    // so we (1) ask NSWorkspace for desktop LLM apps by name, and
    // (2) scan full command lines from `ps` for CLI tools.
    private static let llmAppNames: Set<String> = [
        "Claude", "ChatGPT", "Perplexity", "Copilot", "Gemini"
    ]

    private static func scanLLMProcesses() async -> [String] {
        let desktopApps = NSWorkspace.shared.runningApplications
            .compactMap(\.localizedName)
            .filter { llmAppNames.contains($0) }
            .map { "\($0) (app)" }

        let cliTools = await scanCommandLines()
        return Array(Set(desktopApps + cliTools)).sorted()
    }

    nonisolated private static func scanCommandLines() async -> [String] {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/bin/ps")
                process.arguments = ["-axo", "command="]
                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = Pipe()
                do {
                    try process.run()
                } catch {
                    continuation.resume(returning: [])
                    return
                }
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()

                var found = Set<String>()
                for rawLine in (String(data: data, encoding: .utf8) ?? "").split(separator: "\n") {
                    let line = rawLine.trimmingCharacters(in: .whitespaces)
                    // "claude" or ".../claude" as the executable (any args)
                    if line == "claude" || line.hasPrefix("claude ")
                        || line.range(of: #"^[^ ]*/claude( |$)"#, options: .regularExpression) != nil {
                        found.insert("Claude Code (CLI)")
                    }
                    if line.contains("Claude.app/") { found.insert("Claude (app)") }
                    if line.contains("ChatGPT.app/") { found.insert("ChatGPT (app)") }
                    if line.contains("Perplexity.app/") { found.insert("Perplexity (app)") }
                }
                continuation.resume(returning: Array(found))
            }
        }
    }
}

// ───────────────────────── fullscreen overlay ─────────────────────────

@MainActor
final class OverlayController {
    private var window: NSWindow?

    func show<Content: View>(_ view: Content) {
        if window == nil {
            let frame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
            let w = NSWindow(contentRect: frame, styleMask: [.borderless], backing: .buffered, defer: false)
            w.level = .screenSaver
            w.isOpaque = false
            w.backgroundColor = .clear
            w.isReleasedWhenClosed = false
            w.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            window = w
        }
        if let frame = NSScreen.main?.frame {
            window?.setFrame(frame, display: true)
        }
        window?.contentView = NSHostingView(rootView: AnyView(view))
        window?.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }

    func hide() {
        window?.orderOut(nil)
    }
}
