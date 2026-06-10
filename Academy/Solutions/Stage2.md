# Stage 2 — Reference Solution

```swift
@discardableResult
public static func run(_ command: String) async throws -> String {
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

            let outData = stdout.fileHandleForReading.readDataToEndOfFile()
            let errData = stderr.fileHandleForReading.readDataToEndOfFile()
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
```

## Stretch goal — the deadlock fix

The version above reads stdout fully, *then* stderr. If a command writes more
than ~64KB to stderr while stdout is still open, the child blocks writing and
you block reading: deadlock. The fix — drain stderr on its own queue:

```swift
var errData = Data()
let errDone = DispatchSemaphore(value: 0)
DispatchQueue.global(qos: .userInitiated).async {
    errData = stderr.fileHandleForReading.readDataToEndOfFile()
    errDone.signal()
}
let outData = stdout.fileHandleForReading.readDataToEndOfFile()
errDone.wait()
process.waitUntilExit()
```

The real app (`../Sources/DepDeck/Shell.swift`) ships with this fix.
