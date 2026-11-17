import XCTest

/// Settings steps over the sheet's Form: section headers and toggles, including
/// the relaunch-persistence check (`-tellyKeepState` keeps the state between
/// launches; every other harness launch starts clean).
extension StepDefinitions {
    static func registerSettings(_ r: StepRegistry) {
        r.define("I should see the settings section \"([^\"]+)\"") { w in
            // tvOS renders Form section headers uppercased; match the title case-insensitively.
            let title = w.capture()
            let header = w.app.staticTexts.matching(NSPredicate(format: "label ==[c] %@", title)).firstMatch
            XCTAssertTrue(header.waitForExistence(timeout: medium), "Section “\(title)” missing")
        }
        r.define("I turn on the \"([^\"]+)\" toggle") { w in
            let toggle = w.toggle(named: w.capture())
            XCTAssertTrue(toggle.waitForExistence(timeout: medium), "Toggle missing")
            if toggle.isOn == false { w.activate(toggle) }
            XCTAssertTrue(toggle.isOn, "Toggle should be on after activating")
        }
        r.define("the \"([^\"]+)\" toggle should be on") { w in
            let toggle = w.toggle(named: w.capture())
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

extension GherkinWorld {
    /// A SwiftUI `Toggle` row: a `switch` on iPhone/iPad; on Apple TV it is exposed
    /// as a focusable button carrying the label, so match either.
    func toggle(named name: String) -> XCUIElement {
        let sw = app.switches[name]
        if sw.exists { return sw }
        return app.descendants(matching: .any).matching(NSPredicate(format: "label == %@ AND (elementType == %d OR elementType == %d)",
            name, XCUIElement.ElementType.switch.rawValue, XCUIElement.ElementType.button.rawValue)).firstMatch
    }
}
