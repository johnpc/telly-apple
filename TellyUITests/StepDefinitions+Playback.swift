import XCTest

/// Live playback steps. The shared live stage is identified by its close
/// affordance (`player.close`); whether video decodes is a network matter and is
/// deliberately NOT asserted here (unit tests cover the engine state machine).
extension StepDefinitions {
    static func registerPlayback(_ r: StepRegistry) {
        r.define("I open the channel \"([^\"]+)\"") { w in
            let name = w.capture()
            w.lastOpenedChannel = name
            #if os(tvOS)
            // tvOS rows are focusable buttons labelled "<number>, <name>, <group>".
            let row = w.app.buttons.matching(NSPredicate(format: "label CONTAINS %@", ", \(name), ")).firstMatch
            #else
            let row = w.app.staticTexts[name]
            #endif
            XCTAssertTrue(row.waitForExistence(timeout: medium))
            w.activate(row)
        }
        r.define("I should see the live player") { w in
            #if os(tvOS)
            // No chrome at bare playback on Apple TV: the video surface is the stage's
            // signature, and OK raises the info overlay naming the tuned channel.
            let surface = w.app.otherElements["player.surface"]
            if !surface.waitForExistence(timeout: medium) { w.dumpTree("live player surface missing") }
            XCTAssertTrue(surface.exists, "Expected the live player")
            w.press(.select)
            XCTAssertTrue(w.app.staticTexts[w.lastOpenedChannel].waitForExistence(timeout: medium),
                          "OK should raise the info overlay naming “\(w.lastOpenedChannel)”")
            #else
            XCTAssertTrue(w.app.buttons["player.close"].waitForExistence(timeout: medium), "Expected the live player")
            XCTAssertTrue(w.app.buttons["Guide"].waitForExistence(timeout: short), "Live player should offer the Guide")
            #endif
        }
        r.define("I close the player") { w in
            #if os(tvOS)
            // MENU dismisses an overlay, then opens the guide, then leaves live: press
            // until the channel list is back (bounded).
            for _ in 0..<4 where !w.sees("Channels", timeout: 1) { w.press(.menu) }
            #else
            let close = w.app.buttons["player.close"]
            XCTAssertTrue(close.waitForExistence(timeout: medium))
            w.activate(close)
            #endif
        }
    }
}
