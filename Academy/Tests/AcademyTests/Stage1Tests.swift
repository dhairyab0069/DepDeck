import XCTest
@testable import AcademyCore

final class Stage1Tests: XCTestCase {

    func testDisplayNames_1_1() {
        XCTAssertEqual(PackageManager.brew.displayName, "Homebrew")
        XCTAssertEqual(PackageManager.npm.displayName, "npm")
        XCTAssertEqual(PackageManager.cargo.displayName, "cargo")
    }

    func testUniqueID_1_2() {
        let pkg = Package(manager: .brew, name: "ripgrep")
        XCTAssertEqual(pkg.id, "brew:ripgrep")
        XCTAssertEqual(Package(manager: .cargo, name: "zellij").id, "cargo:zellij")
    }

    func testHasIssue_1_3() {
        XCTAssertFalse(Package(manager: .brew, name: "healthy").hasIssue)
        XCTAssertTrue(Package(manager: .brew, name: "old", deprecated: true).hasIssue)
        XCTAssertTrue(Package(manager: .brew, name: "dead", disabled: true).hasIssue)
    }

    func testIssueLabelPrefersDisabled_1_4() {
        XCTAssertEqual(Package(manager: .brew, name: "a", deprecated: true).issueLabel, "Deprecated")
        XCTAssertEqual(Package(manager: .brew, name: "b", disabled: true).issueLabel, "Disabled")
        XCTAssertEqual(
            Package(manager: .brew, name: "c", deprecated: true, disabled: true).issueLabel,
            "Disabled",
            "When both flags are set, Disabled is the more severe label"
        )
    }

    func testIssueReasonCoalescing_1_5() {
        let both = Package(
            manager: .brew, name: "x",
            deprecated: true, deprecationReason: "old and busted",
            disabled: true, disableReason: "completely dead"
        )
        XCTAssertEqual(both.issueReason, "completely dead", "disable reason must win")

        let deprecatedOnly = Package(
            manager: .brew, name: "y",
            deprecated: true, deprecationReason: "use the new thing"
        )
        XCTAssertEqual(deprecatedOnly.issueReason, "use the new thing")

        XCTAssertNil(Package(manager: .brew, name: "z").issueReason)
    }
}
