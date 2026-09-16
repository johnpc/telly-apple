import XCTest

/// All Given/When/Then step definitions, mapping Gherkin lines to XCUITest
/// actions/assertions. Keywords are interchangeable at match time, so each step
/// is registered once regardless of whether specs phrase it as Given/When/Then.
///
/// Telly is backend-free, so there is no sign-in flow — scenarios assert against
/// the on-device UI directly. As feature slices land (guide, playback, settings,
/// …) their steps are added here; the parser/registry/runner stay untouched.
enum StepDefinitions {

    private static let short: TimeInterval = 5
    private static let medium: TimeInterval = 10

    static func makeRegistry() -> StepRegistry {
        let r = StepRegistry()

        // MARK: Lifecycle
        r.define("the app is launched") { _ in }

        // MARK: Onboarding / welcome
        r.define("I should see the welcome screen") { w in
            XCTAssertTrue(w.app.staticTexts["Telly"].waitForExistence(timeout: medium),
                          "Welcome screen should show the app title")
        }
        r.define("I should see a prompt to add a playlist") { w in
            let prompt = w.app.staticTexts.containing(
                NSPredicate(format: "label CONTAINS[c] %@", "playlist")
            ).firstMatch
            XCTAssertTrue(prompt.waitForExistence(timeout: short),
                          "Welcome screen should prompt the user to add a playlist")
        }

        return r
    }
}
