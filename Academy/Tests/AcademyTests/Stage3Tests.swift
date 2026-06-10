import XCTest
@testable import AcademyCore

final class Stage3Tests: XCTestCase {

    // A trimmed-down but structurally faithful brew JSON fixture:
    // one healthy-but-outdated formula, one deprecated with a replacement,
    // and one never-installed formula that must be skipped.
    let fixture = """
    {
      "formulae": [
        {
          "name": "wget",
          "desc": "Internet file retriever",
          "versions": { "stable": "1.24.5" },
          "installed": [ { "version": "1.24.0" } ],
          "outdated": true,
          "deprecated": false,
          "deprecation_reason": null,
          "deprecation_replacement_formula": null,
          "deprecation_replacement_cask": null,
          "disabled": false,
          "disable_reason": null,
          "disable_replacement_formula": null,
          "disable_replacement_cask": null
        },
        {
          "name": "youtube-dl",
          "desc": "Download YouTube videos",
          "versions": { "stable": "2021.12.17" },
          "installed": [ { "version": "2021.12.17" } ],
          "outdated": false,
          "deprecated": true,
          "deprecation_reason": "Unmaintained upstream",
          "deprecation_replacement_formula": "yt-dlp",
          "deprecation_replacement_cask": null,
          "disabled": false,
          "disable_reason": null,
          "disable_replacement_formula": null,
          "disable_replacement_cask": null
        },
        {
          "name": "ghost-formula",
          "desc": "Listed but not installed",
          "versions": { "stable": "1.0.0" },
          "installed": [],
          "outdated": false,
          "deprecated": false,
          "deprecation_reason": null,
          "deprecation_replacement_formula": null,
          "deprecation_replacement_cask": null,
          "disabled": false,
          "disable_reason": null,
          "disable_replacement_formula": null,
          "disable_replacement_cask": null
        }
      ]
    }
    """

    func testParsesInstalledFormulae_3_1() throws {
        let packages = try parseBrewInfo(fixture)
        XCTAssertEqual(packages.count, 2, "ghost-formula has no installed versions and must be skipped")

        guard let wget = packages.first(where: { $0.name == "wget" }) else {
            return XCTFail("wget missing from parsed packages")
        }
        XCTAssertEqual(wget.manager, .brew)
        XCTAssertEqual(wget.description, "Internet file retriever")
        XCTAssertEqual(wget.installedVersion, "1.24.0")
        XCTAssertEqual(wget.latestVersion, "1.24.5")
        XCTAssertTrue(wget.outdated)
        XCTAssertFalse(wget.deprecated)
        XCTAssertNil(wget.replacement)
    }

    func testParsesDeprecationAndReplacement_3_1() throws {
        let packages = try parseBrewInfo(fixture)
        guard let ytdl = packages.first(where: { $0.name == "youtube-dl" }) else {
            return XCTFail("youtube-dl missing from parsed packages")
        }
        XCTAssertTrue(ytdl.deprecated)
        XCTAssertEqual(ytdl.deprecationReason, "Unmaintained upstream")
        XCTAssertEqual(ytdl.replacement, "yt-dlp")
        XCTAssertTrue(ytdl.hasIssue)
    }

    func testThrowsOnGarbage_3_1() {
        XCTAssertThrowsError(try parseBrewInfo("{ not json at all"))
    }
}
