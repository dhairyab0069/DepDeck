import Foundation

enum ShellError: LocalizedError {
    case failed(command: String, code: Int32, output: String)

    var errorDescription: String? {
        switch self {
        case .failed(let command, let code, let output):
            let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
            return "`\(command)` exited with code \(code)\(trimmed.isEmpty ? "" : ":\n\(trimmed)")"
        }
    }
}

enum Shell {
    /// Runs a command through a login shell so brew/cargo/npm are on PATH.
    @discardableResult
    static func run(_ command: String) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/bin/zsh")
                process.arguments = ["-lc", command]

                let stdout = Pipe()
                let stderr = Pipe()
                process.standardOutput = stdout
                process.standardError = stderr

                do {
                    try process.run()
                } catch {
                    continuation.resume(throwing: error)
                    return
                }

                // Drain both pipes concurrently so neither fills and blocks the process.
                var errData = Data()
                let errDone = DispatchSemaphore(value: 0)
                DispatchQueue.global(qos: .userInitiated).async {
                    errData = stderr.fileHandleForReading.readDataToEndOfFile()
                    errDone.signal()
                }
                let outData = stdout.fileHandleForReading.readDataToEndOfFile()
                errDone.wait()
                process.waitUntilExit()

                let out = String(data: outData, encoding: .utf8) ?? ""
                let err = String(data: errData, encoding: .utf8) ?? ""

                if process.terminationStatus == 0 {
                    continuation.resume(returning: out)
                } else {
                    continuation.resume(throwing: ShellError.failed(
                        command: command,
                        code: process.terminationStatus,
                        output: err.isEmpty ? out : err
                    ))
                }
            }
        }
    }
}
