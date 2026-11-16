import XCTest

/// Search steps: type a query into the `.searchable` field and assert on the
/// Channels shelf / Programs lane that the demo provider's data produces.
extension StepDefinitions {
    static func registerSearch(_ r: StepRegistry) {
        r.define("I search for \"([^\"]+)\"") { w in
            let field = w.app.searchFields.firstMatch
            XCTAssertTrue(field.waitForExistence(timeout: medium), "Expected a search field")
            field.tap()
            field.typeText(w.capture())
        }
        r.define("the results should list the channel \"([^\"]+)\"") { w in
            let name = w.capture()
            XCTAssertTrue(w.app.staticTexts[name].waitForExistence(timeout: medium), "Result “\(name)” missing")
        }
        r.define("the results should list the programme \"([^\"]+)\"") { w in
            let title = w.capture()
            XCTAssertTrue(w.app.staticTexts[title].waitForExistence(timeout: medium), "Programme “\(title)” missing")
        }
    }
}
