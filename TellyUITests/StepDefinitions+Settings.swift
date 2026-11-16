import XCTest

/// Settings steps over the sheet's Form: section headers and toggles, including
/// the relaunch-persistence check (`-tellyKeepState` keeps the state between
/// launches; every other harness launch starts clean).
extension StepDefinitions {
    static func registerSettings(_ r: StepRegistry) {
        r.define("I should see the settings section \"([^\"]+)\"") { w in
            let title = w.capture()
            XCTAssertTrue(w.app.staticTexts[title].waitForExistence(timeout: medium), "Section “\(title)” missing")
        }
        r.define("I turn on the \"([^\"]+)\" toggle") { w in
            let toggle = w.app.switches[w.capture()]
            XCTAssertTrue(toggle.waitForExistence(timeout: medium), "Toggle missing")
            if toggle.isOn == false { w.activate(toggle) }
            XCTAssertTrue(toggle.isOn, "Toggle should be on after tapping")
        }
        r.define("the \"([^\"]+)\" toggle should be on") { w in
            let toggle = w.app.switches[w.capture()]
            XCTAssertTrue(toggle.waitForExistence(timeout: medium), "Toggle missing")
            XCTAssertTrue(toggle.isOn, "Toggle should have persisted as on")
        }
    }
}

extension XCUIElement {
    /// A SwiftUI `Toggle` reports its value as "1"/"0" (or on/off).
    var isOn: Bool {
        let value = (self.value as? String) ?? ""
        return value == "1" || value.lowercased() == "on"
    }
}
