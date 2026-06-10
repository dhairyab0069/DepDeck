import Foundation

// ╔════════════════════════════════════════════════════════════════════╗
// ║  STAGE 2 — Run shell commands with async/await                    ║
// ║                                                                    ║
// ║  Grade yourself:  ./academy check 2                                ║
// ║  Concepts:        Tutorial chapter 3                               ║
// ╚════════════════════════════════════════════════════════════════════╝

// Given to you: the error type (Stage 1 taught you enums with payloads).
public enum ShellError: Error {
    case failed(command: String, code: Int32, output: String)
}

public enum Shell {

    // ── EXERCISE 2.1 ─────────────────────────────────────────────────
    // Run `command` through a login shell and return its stdout.
    // This is the engine the whole app runs on. Build it in steps:
    //
    //   1. Wrap everything in:
    //        try await withCheckedThrowingContinuation { continuation in
    //            DispatchQueue.global(qos: .userInitiated).async {
    //                ...
    //            }
    //        }
    //
    //   2. Create a Process:
    //        executableURL = URL(fileURLWithPath: "/bin/zsh")
    //        arguments     = ["-lc", command]        // -l = login shell → real PATH
    //
    //   3. Create two Pipe()s; assign to standardOutput / standardError.
    //
    //   4. try process.run() — if it throws, resume(throwing:) and return.
    //
    //   5. Read stdout to the end:
    //        let outData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
    //      then stderr the same way, then process.waitUntilExit().
    //      (Stretch goal, after tests pass: read the two pipes on separate
    //       queues — see Tutorial ch. 3 for the 64KB deadlock story.)
    //
    //   6. Convert Data → String with String(data:encoding:) ?? "".
    //
    //   7. If process.terminationStatus == 0 → resume(returning: stdout).
    //      Otherwise → resume(throwing: ShellError.failed(...)) and pass
    //      stderr as the output (fall back to stdout if stderr is empty).
    //
    // Rule: resume the continuation EXACTLY ONCE on every path.
    @discardableResult
    public static func run(_ command: String) async throws -> String {
        // TODO(you): replace this placeholder with the real implementation
        return ""
    }
}
