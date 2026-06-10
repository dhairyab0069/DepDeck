import SwiftUI
import WebKit

// ───────────────────────── Setup ─────────────────────────

struct SetupView: View {
    @EnvironmentObject var model: SessionModel
    @State private var minutes = 25

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("🔒 FocusLock")
                .font(.largeTitle.bold())
            Text("Pick a session length and which apps stay usable. Everything else gets locked out — and any LLM (Claude, ChatGPT, Claude Code…) pauses your timer until you close it.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Picker("Session", selection: $minutes) {
                Text("25 min").tag(25)
                Text("45 min").tag(45)
                Text("60 min").tag(60)
                Text("90 min").tag(90)
            }
            .pickerStyle(.segmented)

            HStack {
                Text("Allowed apps").font(.headline)
                Spacer()
                Button("Refresh") { model.refreshRunningApps() }
                    .controlSize(.small)
            }

            List(model.runningApps) { app in
                Toggle(app.name, isOn: Binding(
                    get: { model.allowedIDs.contains(app.id) },
                    set: { _ in model.toggleAllowed(app.id) }
                ))
            }
            .frame(minHeight: 180)

            Label("This is friction, not handcuffs — it can't stop a determined quitter (or your phone). Its job is to make drifting away loud and immediate.",
                  systemImage: "info.circle")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                model.start(minutes: minutes)
            } label: {
                Text("Lock in for \(minutes) minutes")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
        .padding(20)
        .onAppear { model.refreshRunningApps() }
    }
}

// ───────────────────────── Active session ─────────────────────────

struct SessionView: View {
    @EnvironmentObject var model: SessionModel
    @Environment(\.openWindow) private var openWindow

    private var timeText: String {
        String(format: "%02d:%02d", model.remaining / 60, model.remaining % 60)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(model.llmPaused ? "⏸ PAUSED — LLM detected" : "🔒 Locked in")
                .font(.headline)
                .foregroundStyle(model.llmPaused ? .red : .green)

            Text(timeText)
                .font(.system(size: 64, weight: .bold, design: .monospaced))
                .contentTransition(.numericText())

            ProgressView(value: Double(model.totalSeconds - model.remaining),
                         total: Double(model.totalSeconds))

            HStack(spacing: 18) {
                VStack {
                    Text("\(model.violations)").font(.title2.bold())
                    Text("escape attempts").font(.caption).foregroundStyle(.secondary)
                }
                if let violator = model.lastViolator {
                    VStack {
                        Text(violator).font(.title3)
                        Text("last temptation").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }

            Divider()

            Button("📖 Open Tutorial (offline, built-in)") {
                openWindow(id: "reference")
            }

            Text("Check stages in your terminal:\n./academy check <stage>")
                .font(.system(.caption, design: .monospaced))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Spacer()

            Button("End session early…", role: .destructive) {
                model.showEarlyEndSheet = true
            }
            .controlSize(.small)
        }
        .padding(20)
    }
}

// ───────────────────────── Finished ─────────────────────────

struct FinishedView: View {
    @EnvironmentObject var model: SessionModel

    var body: some View {
        VStack(spacing: 14) {
            Text("🎉").font(.system(size: 56))
            Text("Session complete").font(.title.bold())
            Text("\(model.totalSeconds / 60) focused minutes · \(model.violations) escape attempt\(model.violations == 1 ? "" : "s")")
                .foregroundStyle(.secondary)
            Button("Start another") { model.state = .idle }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
        }
        .padding(40)
    }
}

// ───────────────────────── Early-exit confession ─────────────────────────

struct EarlyEndSheet: View {
    @EnvironmentObject var model: SessionModel
    @State private var typed = ""
    private let phrase = "I am choosing to stop early"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ending early?").font(.title2.bold())
            Text("Type exactly:  \(phrase)")
                .foregroundStyle(.secondary)
            TextField("", text: $typed)
                .textFieldStyle(.roundedBorder)
            HStack {
                Button("Never mind — back to work") {
                    model.showEarlyEndSheet = false
                    typed = ""
                }
                .buttonStyle(.borderedProminent)
                Spacer()
                Button("End session", role: .destructive) {
                    model.showEarlyEndSheet = false
                    typed = ""
                    model.end(completed: false)
                }
                .disabled(typed != phrase)
            }
        }
        .padding(20)
        .frame(width: 420)
    }
}

// ───────────────────────── Overlays ─────────────────────────

struct ViolationOverlay: View {
    let appName: String
    let violations: Int

    var body: some View {
        ZStack {
            Color.black.opacity(0.93)
            VStack(spacing: 16) {
                Text("🔒").font(.system(size: 72))
                Text("Locked in.").font(.system(size: 40, weight: .bold))
                Text("\(appName) can wait. Your code can't.")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("Escape attempt #\(violations) — sending you back in a moment…")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .ignoresSafeArea()
        .foregroundStyle(.white)
    }
}

struct LLMOverlay: View {
    let processes: [String]

    var body: some View {
        ZStack {
            Color(red: 0.25, green: 0.02, blue: 0.02).opacity(0.96)
            VStack(spacing: 16) {
                Text("🤖").font(.system(size: 72))
                Text("No LLM shortcuts.").font(.system(size: 40, weight: .bold))
                Text("Running: \(processes.joined(separator: ", "))")
                    .font(.title3.monospaced())
                Text("The struggle is the workout — outsourcing it skips the rep.\nYour timer is paused until they're closed. It resumes automatically.")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding(40)
        }
        .ignoresSafeArea()
        .foregroundStyle(.white)
    }
}

// ───────────────────────── Offline tutorial viewer ─────────────────────────

struct ReferenceView: View {
    private var tutorialURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Developer/DepDeck/Tutorial/index.html")
    }

    var body: some View {
        if FileManager.default.fileExists(atPath: tutorialURL.path) {
            LocalWebView(url: tutorialURL)
        } else {
            ContentUnavailableView(
                "Tutorial not found",
                systemImage: "questionmark.folder",
                description: Text(tutorialURL.path)
            )
        }
    }
}

struct LocalWebView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}
}
