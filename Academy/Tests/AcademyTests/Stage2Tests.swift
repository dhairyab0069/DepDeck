import XCTest
@testable import AcademyCore

final class Stage2Tests: XCTestCase {

    func testCapturesStdout_2_1() async throws {
        let out = try await Shell.run("printf 'hello'")
        XCTAssertEqual(out, "hello")
    }

    func testCapturesMultilineOutput_2_1() async throws {
        let out = try await Shell.run("printf 'one\\ntwo\\n'")
        XCTAssertEqual(out, "one\ntwo\n")
    }

    func testFailureThrowsWithExitCodeAndStderr_2_1() async {
        do {
            _ = try await Shell.run("printf 'boom' >&2; exit 3")
            XCTFail("A non-zero exit must throw ShellError.failed")
        } catch ShellError.failed(let command, let code, let output) {
            XCTAssertEqual(code, 3)
            XCTAssertTrue(output.contains("boom"), "stderr should be captured in the error")
            XCTAssertTrue(command.contains("exit 3"))
        } catch {
            XCTFail("Expected ShellError.failed, got \(error)")
        }
    }

    func testLoginShellSeesRealPATH_2_1() async throws {
        // -l (login shell) loads your profile, so brew must be findable.
        let out = try await Shell.run("command -v brew")
        XCTAssertTrue(out.contains("brew"), "Did you pass -lc (not just -c) to zsh?")
    }
}
