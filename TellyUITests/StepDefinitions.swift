import XCTest

/// All Given/When/Then step definitions, mapping Gherkin lines to XCUITest
/// actions/assertions. Keywords are interchangeable at match time, so each step
/// is registered once regardless of whether specs phrase it as Given/When/Then.
///
/// Telly is backend-free: scenarios run against the on-device UI over the
/// in-process demo provider (`DemoContent`), never a server. Each feature area
/// registers its steps from a sibling `StepDefinitions+*.swift` file; the
/// parser/registry/runner stay untouched as areas land.
enum StepDefinitions {
    static let short: TimeInterval = 5
    static let medium: TimeInterval = 10

    static func makeRegistry() -> StepRegistry {
        let r = StepRegistry()
        registerOnboarding(r)
        registerNavigation(r)
        registerGuide(r)
        registerSearch(r)
        registerPlayback(r)
        registerSettings(r)
        return r
    }

    // MARK: Lifecycle / onboarding / demo provider
    static func registerOnboarding(_ r: StepRegistry) {
        r.define("the app is launched") { _ in }
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
        r.define("I tap Add playlist") { w in
            let button = w.app.buttons["welcome.add"]
            XCTAssertTrue(button.waitForExistence(timeout: medium))
            w.activate(button)
        }
        r.define("I should see the add-playlist wizard") { w in
            XCTAssertTrue(w.sees("Add playlist"), "Expected the add-playlist wizard")
        }
        r.define("I cancel the wizard") { w in w.activate(w.app.buttons["Cancel"]) }
        r.define("I choose the demo playlist") { w in
            let button = w.app.buttons["welcome.demo"]
            XCTAssertTrue(button.waitForExistence(timeout: medium), "Welcome screen should offer the demo")
            w.activate(button)
        }
        r.define("the demo playlist is installed") { w in
            let button = w.app.buttons["welcome.demo"]
            XCTAssertTrue(button.waitForExistence(timeout: medium), "Welcome screen should offer the demo")
            w.activate(button)
            XCTAssertTrue(w.sees("Channels"), "Installing the demo playlist should land on the channel list")
            // Settled: the rows are in, so the route crossfade (and the bar's morph) is over.
            XCTAssertTrue(w.app.staticTexts["News One"].waitForExistence(timeout: medium),
                          "Demo channels should be listed")
        }
        r.define("I should see the channel list") { w in
            XCTAssertTrue(w.sees("Channels"), "Expected the channel list")
        }
        r.define("I should see the channel \"([^\"]+)\"") { w in
            let name = w.capture()
            XCTAssertTrue(w.app.staticTexts[name].waitForExistence(timeout: medium),
                          "Channel “\(name)” should be listed")
        }
        r.define("the channel list should not list \"([^\"]+)\"") { w in
            let name = w.capture()
            XCTAssertTrue(w.sees("Channels"))
            XCTAssertFalse(w.app.staticTexts[name].exists, "“\(name)” must not appear as a channel")
        }
        r.define("I relaunch the app keeping its state") { w in w.relaunchKeepingState() }
    }
}
