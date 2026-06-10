import XCTest
@testable import AcademyCore

final class Stage4Tests: XCTestCase {

    func testParsesCargoList_4_1() {
        let output = """
        ripgrep v14.1.0:
            rg
        cargo-edit v0.12.2 (/Users/you/src/cargo-edit):
            cargo-add
            cargo-rm
        zellij v0.40.1:
            zellij
        """
        let tools = parseCargoInstallList(output)
        XCTAssertEqual(tools, [
            CargoTool(name: "ripgrep", version: "14.1.0"),
            CargoTool(name: "cargo-edit", version: "0.12.2"),
            CargoTool(name: "zellij", version: "0.40.1")
        ])
    }

    func testIgnoresJunkLines_4_1() {
        XCTAssertEqual(parseCargoInstallList(""), [])
        XCTAssertEqual(parseCargoInstallList("warning: something unrelated\n"), [])
        XCTAssertEqual(parseCargoInstallList("    only-indented v1.0.0:\n"), [])
    }

    func testVersionComparison_4_2() {
        XCTAssertTrue(isVersion("1.10.0", newerThan: "1.9.9"), "numeric compare, not string compare!")
        XCTAssertTrue(isVersion("2.0.0", newerThan: "1.99.99"))
        XCTAssertFalse(isVersion("1.0.0", newerThan: "1.0.0"), "equal versions are not newer")
        XCTAssertFalse(isVersion("2.0", newerThan: "10.0"), "string compare would get this wrong too")
    }

    func testVersionComparisonWithDifferentLengths_4_2() {
        XCTAssertTrue(isVersion("1.2.3", newerThan: "1.2"), "missing components count as 0")
        XCTAssertFalse(isVersion("1.2", newerThan: "1.2.0"), "1.2 equals 1.2.0")
        XCTAssertFalse(isVersion("1.2", newerThan: "1.2.3"))
    }
}
