import XCTest

/// Live playback steps. The shared live stage is identified by its close
/// affordance (`player.close`); whether video decodes is a network matter and is
/// deliberately NOT asserted here (unit tests cover the engine state machine).
extension StepDefinitions {
    static func registerPlayback(_ r: StepRegistry) {
        r.define("I open the channel \"([^\"]+)\"") { w in
            let row = w.app.staticTexts[w.capture()]
            XCTAssertTrue(row.waitForExistence(timeout: medium))
            w.activate(row)
        }
        r.define("I should see the live player") { w in
            XCTAssertTrue(w.app.buttons["player.close"].waitForExistence(timeout: medium), "Expected the live player")
            XCTAssertTrue(w.app.buttons["Guide"].waitForExistence(timeout: short), "Live player should offer the Guide")
        }
        r.define("I close the player") { w in
            let close = w.app.buttons["player.close"]
            XCTAssertTrue(close.waitForExistence(timeout: medium))
            w.activate(close)
        }
    }
}
