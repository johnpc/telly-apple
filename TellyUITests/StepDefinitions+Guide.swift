import XCTest

/// Guide, programme-details, My List and catch-up steps. Guide cells carry the
/// identifier `guide.cell.<channel name>`, so a step can address "the Nth visible
/// programme on the row for channel X" without depending on time-of-day titles.
extension StepDefinitions {
    static func registerGuide(_ r: StepRegistry) {
        r.define("I should see the guide grid") { w in
            XCTAssertTrue(w.app.buttons["Now"].waitForExistence(timeout: medium), "Guide should show the Now control")
            XCTAssertTrue(w.app.staticTexts["Today"].waitForExistence(timeout: short), "Guide should label today")
        }
        r.define("the guide should list the channel \"([^\"]+)\"") { w in
            let name = w.capture()
            XCTAssertTrue(w.app.staticTexts[name].waitForExistence(timeout: medium), "Guide row “\(name)” missing")
        }
        r.define("I open the details of the next programme on the first row") { w in
            // Page a day ahead so every visible cell is a FUTURE programme (the airing
            // one can span the whole compact pane), then open the first on News One.
            let next = w.app.buttons["Next day"]
            XCTAssertTrue(next.waitForExistence(timeout: medium))
            w.activate(next)
            XCTAssertTrue(w.app.staticTexts["Tomorrow"].waitForExistence(timeout: short), "Day label should read Tomorrow")
            w.openGuideCell(onRow: "News One", index: 0)
        }
        r.define("I open the details of the first programme on the row \"([^\"]+)\"") { w in
            w.openGuideCell(onRow: w.capture(), index: 0)
        }
        r.define("I should see the programme details") { w in
            XCTAssertTrue(w.app.navigationBars["Programme"].waitForExistence(timeout: medium),
                          "Expected the programme info panel")
        }
        r.define("I add the programme to My List") { w in
            let add = w.app.buttons["Add to My List"]
            XCTAssertTrue(add.waitForExistence(timeout: medium), "Panel should offer Add to My List")
            w.activate(add)
            XCTAssertTrue(w.app.buttons["Remove from My List"].waitForExistence(timeout: short),
                          "The My List button should flip to Remove")
            w.activate(w.app.buttons["Done"])
        }
        r.define("My List should show a saved programme") { w in
            XCTAssertTrue(w.app.cells.firstMatch.waitForExistence(timeout: medium), "Expected a saved row")
            XCTAssertFalse(w.app.staticTexts["No saved programmes"].exists)
        }
        r.define("I page the guide to the previous day") { w in
            let prev = w.app.buttons["Previous day"]
            XCTAssertTrue(prev.waitForExistence(timeout: medium))
            w.activate(prev)
            XCTAssertTrue(w.app.staticTexts["Yesterday"].waitForExistence(timeout: short), "Day label should read Yesterday")
        }
        r.define("I should see the catch-up action") { w in
            XCTAssertTrue(w.app.buttons["Watch from start"].waitForExistence(timeout: medium),
                          "An aired programme on a catch-up channel should offer Watch from start")
        }
        r.define("I start the catch-up playback") { w in w.activate(w.app.buttons["Watch from start"]) }
        r.define("I should see the archive player") { w in
            XCTAssertTrue(w.app.buttons["player.close"].waitForExistence(timeout: medium), "Expected the archive player")
            XCTAssertFalse(w.app.buttons["Watch from start"].exists, "The info panel should have dismissed")
        }
    }
}
