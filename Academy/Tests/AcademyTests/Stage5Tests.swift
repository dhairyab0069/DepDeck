import XCTest
@testable import AcademyCore

final class Stage5Tests: XCTestCase {

    let sample = [
        Package(manager: .brew, name: "ripgrep"),
        Package(manager: .brew, name: "Zellij"),
        Package(manager: .npm, name: "typescript"),
        Package(manager: .cargo, name: "apple-codesign")
    ]

    func testEmptyQueryReturnsEverything_5_1() {
        XCTAssertEqual(filterPackages(sample, query: "").count, 4)
        XCTAssertEqual(filterPackages(sample, query: "   ").count, 4, "whitespace-only counts as empty")
    }

    func testFilterIsCaseInsensitive_5_1() {
        XCTAssertEqual(filterPackages(sample, query: "RIP").map(\.name), ["ripgrep"])
        XCTAssertEqual(filterPackages(sample, query: "zell").map(\.name), ["Zellij"])
    }

    func testFilterMatchesSubstrings_5_1() {
        XCTAssertEqual(filterPackages(sample, query: "script").map(\.name), ["typescript"])
        XCTAssertEqual(filterPackages(sample, query: "nomatch").count, 0)
    }

    func testSortIsCaseInsensitive_5_2() {
        let sorted = sortedByName(sample).map(\.name)
        XCTAssertEqual(sorted, ["apple-codesign", "ripgrep", "typescript", "Zellij"],
                       "Zellij must sort after lowercase names — compare lowercased")
    }

    func testReplacementPriority_5_3() {
        XCTAssertEqual(
            chooseReplacement(disableFormula: "a", deprecationFormula: "b", disableCask: "c", deprecationCask: "d"),
            "a"
        )
        XCTAssertEqual(
            chooseReplacement(disableFormula: nil, deprecationFormula: "b", disableCask: "c", deprecationCask: "d"),
            "b"
        )
        XCTAssertEqual(
            chooseReplacement(disableFormula: nil, deprecationFormula: nil, disableCask: "c", deprecationCask: "d"),
            "c"
        )
        XCTAssertEqual(
            chooseReplacement(disableFormula: nil, deprecationFormula: nil, disableCask: nil, deprecationCask: "d"),
            "d"
        )
        XCTAssertNil(
            chooseReplacement(disableFormula: nil, deprecationFormula: nil, disableCask: nil, deprecationCask: nil)
        )
    }
}
