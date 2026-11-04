import XCTest
@testable import DepDeck

final class BrewParsingTests: XCTestCase {
    private let json = """
    {"formulae": [
      {"name": "ripgrep", "desc": "Search tool", "versions": {"stable": "14.1.1"},
       "installed": [{"version": "14.1.0"}], "outdated": true,
       "deprecated": false, "deprecation_reason": null,
       "deprecation_replacement_formula": null, "deprecation_replacement_cask": null,
       "disabled": false, "disable_reason": null,
       "disable_replacement_formula": null, "disable_replacement_cask": null},
      {"name": "oldtool", "desc": null, "versions": {"stable": "1.0"},
       "installed": [{"version": "0.9"}, {"version": "1.0"}], "outdated": false,
       "deprecated": true, "deprecation_reason": "unmaintained",
       "deprecation_replacement_formula": "newtool", "deprecation_replacement_cask": null,
       "disabled": true, "disable_reason": "no longer works",
       "disable_replacement_formula": null, "disable_replacement_cask": "newcask"},
      {"name": "notinstalled", "desc": null, "versions": {"stable": "2.0"},
       "installed": [], "outdated": false,
       "deprecated": false, "deprecation_reason": null,
       "deprecation_replacement_formula": null, "deprecation_replacement_cask": null,
       "disabled": false, "disable_reason": null,
       "disable_replacement_formula": null, "disable_replacement_cask": null}
    ], "casks": []}
    """

    func testParsesInstalledFormulaeAndSkipsUninstalledOnes() throws {
        let packages = try BrewClient.parseInstalled(json)
        XCTAssertEqual(packages.map(\.name), ["ripgrep", "oldtool"])
        let rg = packages[0]
        XCTAssertEqual(rg.manager, .brew)
        XCTAssertEqual(rg.installedVersion, "14.1.0")
        XCTAssertEqual(rg.latestVersion, "14.1.1")
        XCTAssertTrue(rg.outdated)
        XCTAssertFalse(rg.hasIssue)
        XCTAssertEqual(rg.id, "brew:ripgrep")
    }

    func testUsesTheNewestInstalledVersionAndPrefersDisableInfo() throws {
        let old = try BrewClient.parseInstalled(json)[1]
        XCTAssertEqual(old.installedVersion, "1.0")
        XCTAssertTrue(old.hasIssue)
        XCTAssertEqual(old.issueLabel, "Disabled")
        XCTAssertEqual(old.issueReason, "no longer works")
        // disable_replacement_formula is nil, so the deprecation formula wins over the disable cask.
        XCTAssertEqual(old.replacement, "newtool")
    }

    func testInvalidJSONThrows() {
        XCTAssertThrowsError(try BrewClient.parseInstalled("not json"))
    }

    func testSearchSkipsHeadingsAndBlankLines() {
        let out = "==> Formulae\nripgrep\nripgrep-all\n\n==> Casks\nfoo\n"
        XCTAssertEqual(BrewClient.parseSearch(out).map(\.name), ["ripgrep", "ripgrep-all", "foo"])
        XCTAssertTrue(BrewClient.parseSearch(out).allSatisfy { $0.manager == .brew })
    }
}

final class CargoParsingTests: XCTestCase {
    func testParsesTopLevelLinesOnly() {
        let out = """
        bat v0.24.0:
            bat
        ripgrep v14.1.0:
            rg
        """
        XCTAssertEqual(CargoClient.parseInstallList(out), [
            .init(name: "bat", version: "0.24.0", fromRegistry: true),
            .init(name: "ripgrep", version: "14.1.0", fromRegistry: true),
        ])
    }

    func testPathAndGitInstallsAreNotFromTheRegistry() {
        let out = "mytool v0.1.0 (/Users/me/mytool):\n    mytool\nother v2.0.0 (https://github.com/x/other#abc123):\n    other\n"
        let crates = CargoClient.parseInstallList(out)
        XCTAssertEqual(crates.map(\.name), ["mytool", "other"])
        XCTAssertEqual(crates.map(\.fromRegistry), [false, false])
    }

    func testIgnoresLinesThatAreNotCrates() {
        XCTAssertEqual(CargoClient.parseInstallList(""), [])
        XCTAssertEqual(CargoClient.parseInstallList("garbage:\nname 1.0.0:\n"), [])
    }

    func testSearchKeepsOnlyResultLines() {
        let out = """
        ripgrep = "14.1.0"    # Fast search
        ripgrep_all = "0.10.6"    # Search PDFs too
        ... and 3 crates more (use --limit N to see more)
        """
        XCTAssertEqual(CargoClient.parseSearch(out).map(\.name), ["ripgrep", "ripgrep_all"])
    }
}

final class NpmParsingTests: XCTestCase {
    func testParsesGlobalList() throws {
        let json = """
        {"name": "lib", "dependencies": {"typescript": {"version": "5.4.5"}, "npm": {"version": "10.8.0"}, "broken": {}}}
        """
        XCTAssertEqual(try NpmClient.parseList(json), ["typescript": "5.4.5", "npm": "10.8.0"])
    }

    func testEmptyGlobalListHasNoDependenciesKey() throws {
        XCTAssertEqual(try NpmClient.parseList("{}"), [:])
    }

    func testParsesOutdatedAndToleratesEmptyOutput() {
        let json = #"{"typescript": {"current": "5.4.5", "wanted": "5.4.5", "latest": "5.6.2"}}"#
        XCTAssertEqual(NpmClient.parseOutdated(json), ["typescript": "5.6.2"])
        XCTAssertEqual(NpmClient.parseOutdated(""), [:])
        XCTAssertEqual(NpmClient.parseOutdated("not json"), [:])
    }

    func testMakePackageFlagsOutdatedAndDeprecated() {
        let p = NpmClient.makePackage(name: "request", version: "2.88.2", latest: "2.88.2",
                                      deprecationMessage: "  request has been deprecated\n")
        XCTAssertFalse(p.outdated)
        XCTAssertTrue(p.deprecated)
        XCTAssertEqual(p.deprecationReason, "request has been deprecated")
        XCTAssertNil(p.replacement)

        let q = NpmClient.makePackage(name: "typescript", version: "5.4.5", latest: "5.6.2", deprecationMessage: "\n")
        XCTAssertTrue(q.outdated)
        XCTAssertEqual(q.latestVersion, "5.6.2")
        XCTAssertFalse(q.deprecated)
        XCTAssertNil(q.deprecationReason)

        let r = NpmClient.makePackage(name: "x", version: "1.0.0", latest: nil, deprecationMessage: nil)
        XCTAssertFalse(r.outdated)
        XCTAssertEqual(r.latestVersion, "1.0.0")
    }
}

final class ShellTests: XCTestCase {
    func testQuotePlainAndAwkwardNames() {
        XCTAssertEqual(Shell.quote("ripgrep"), "'ripgrep'")
        XCTAssertEqual(Shell.quote("@scope/pkg@latest"), "'@scope/pkg@latest'")
        XCTAssertEqual(Shell.quote("a'b"), "'a'\\''b'")
    }

    func testQuotedValuesSurviveARealShell() async throws {
        let awkward = "it's $HOME `x` ; echo pwned"
        let out = try await Shell.run("printf %s \(Shell.quote(awkward))")
        XCTAssertEqual(out, awkward)
    }

    func testFailureCarriesCodeAndStderr() async {
        do {
            try await Shell.run("echo boom >&2; exit 3")
            XCTFail("expected a throw")
        } catch let ShellError.failed(_, code, output) {
            XCTAssertEqual(code, 3)
            XCTAssertEqual(output.trimmingCharacters(in: .whitespacesAndNewlines), "boom")
        } catch {
            XCTFail("unexpected error \(error)")
        }
    }
}

final class ModelTests: XCTestCase {
    func testDisplayNames() {
        XCTAssertEqual(PackageManager.allCases.map(\.displayName), ["Homebrew", "npm", "cargo"])
    }

    func testIssueLabelAndReasonPreferDisabled() {
        var p = Package(manager: .brew, name: "x", description: nil, installedVersion: "1", latestVersion: nil,
                        outdated: false, deprecated: true, deprecationReason: "old", disabled: false,
                        disableReason: nil, replacement: nil)
        XCTAssertEqual(p.issueLabel, "Deprecated")
        XCTAssertEqual(p.issueReason, "old")
        p.disabled = true
        p.disableReason = "gone"
        XCTAssertEqual(p.issueLabel, "Disabled")
        XCTAssertEqual(p.issueReason, "gone")
    }
}
