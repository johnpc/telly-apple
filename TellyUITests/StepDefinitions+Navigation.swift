import XCTest

/// Steps that move between Telly's top-level screens from the channel list's
/// toolbar (Guide / Search / Movies / My List / Settings) and generic
/// "I should see …" assertions shared by several features.
extension StepDefinitions {
    static func registerNavigation(_ r: StepRegistry) {
        r.define("I open the Guide") { w in w.openToolbarItem("Guide") }
        r.define("I open Search") { w in w.openToolbarItem("Search") }
        r.define("I open the Movies browser") { w in
            w.openToolbarItem("Movies")
            XCTAssertTrue(w.sees("Movies"), "Expected the Movies browser")
        }
        r.define("I open My List") { w in
            w.openToolbarItem("My List")
            XCTAssertTrue(w.sees("My List"), "Expected My List")
        }
        r.define("I open Settings") { w in
            w.openToolbarItem("Settings")
            XCTAssertTrue(w.sees("Settings"), "Expected Settings")
        }
        r.define("I go back to the channel list") { w in
            #if os(tvOS)
            w.press(.menu)
            #else
            let back = w.app.navigationBars.buttons.element(boundBy: 0)
            XCTAssertTrue(back.waitForExistence(timeout: short), "Expected a navigation back button")
            w.activate(back)
            #endif
            XCTAssertTrue(w.sees("Channels"), "Expected to be back on the channel list")
        }
        r.define("I should see the empty message \"([^\"]+)\"") { w in
            let text = w.capture()
            XCTAssertTrue(w.app.staticTexts[text].waitForExistence(timeout: medium), "Expected “\(text)”")
        }
        r.define("I should see the film \"([^\"]+)\"") { w in
            let name = w.capture()
            XCTAssertTrue(w.app.staticTexts[name].waitForExistence(timeout: medium), "Film “\(name)” should be listed")
        }
    }
}
