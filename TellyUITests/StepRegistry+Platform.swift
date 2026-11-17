import XCTest

/// Platform input for the acceptance steps. iPhone/iPad tap; Apple TV drives the
/// focus engine through `XCUIRemote`: focus is walked onto the target by pressing
/// toward its frame (bounded), then Select. Every step uses these two verbs
/// (`activate`, `sees`) so the SAME `.feature` files run on both platforms.
extension GherkinWorld {
    /// Activates a control the way the platform does.
    func activate(_ element: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        #if os(tvOS)
        if !focus(element) { dumpTree("focus walk failed") }
        XCTAssertTrue(element.hasFocus, "Could not move focus onto \(element)", file: file, line: line)
        XCUIRemote.shared.press(.select)
        settle(0.6)
        #else
        // A control can exist while a transition is still animating; tapping then is
        // swallowed. Wait (bounded) for it to become hittable before the tap.
        let deadline = Date().addingTimeInterval(5)
        while !element.isHittable && Date() < deadline { RunLoop.current.run(until: Date().addingTimeInterval(0.1)) }
        element.tap()
        #endif
    }

    /// Whether a screen titled `title` is showing: a navigation bar on iOS, the
    /// large title text on tvOS (which has no navigation-bar element).
    func sees(_ title: String, timeout: TimeInterval = 10) -> Bool {
        let bar = app.navigationBars[title]
        let text = app.staticTexts[title]
        return eventually(within: timeout) { bar.exists || text.exists }
    }

    /// Polls `condition` every quarter second until it holds or `seconds` elapse —
    /// the one way steps wait for the UI to reach a state (never a fixed sleep).
    func eventually(within seconds: TimeInterval, _ condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(seconds)
        while Date() < deadline {
            if condition() { return true }
            settle(0.25)
        }
        return condition()
    }

    /// Attach the current accessibility tree to the test (and echo its head to the
    /// log) so a navigation failure on a headless simulator is diagnosable.
    func dumpTree(_ reason: String) {
        let tree = app.debugDescription
        let attachment = XCTAttachment(string: tree)
        attachment.name = "AX tree — \(reason)"
        attachment.lifetime = .keepAlways
        XCTContext.runActivity(named: "AX tree — \(reason)") { $0.add(attachment) }
        print("AX TREE (\(reason)):\n" + tree.split(separator: "\n").prefix(140).joined(separator: "\n"))
    }

    /// Let the run loop turn so focus / transitions settle.
    func settle(_ seconds: TimeInterval) { RunLoop.current.run(until: Date().addingTimeInterval(seconds)) }

    #if os(tvOS)
    var remote: XCUIRemote { .shared }

    /// The element the focus engine currently highlights.
    var focusedElement: XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true")).firstMatch
    }

    /// Moves focus into the guide grid (one focusable cursor surface, so it is
    /// found by identifier, not by element): from the day chrome above, DOWN.
    func focusGuideGrid() -> Bool {
        for _ in 0..<4 {
            if focusedElement.identifier == "guide.grid" { return true }
            remote.press(.down); settle(0.5)
        }
        return focusedElement.identifier == "guide.grid"
    }

    /// Walks focus onto `element` by pressing toward its frame — vertical first,
    /// and when a press does not move focus (the engine found nothing in that
    /// direction, e.g. no horizontal overlap) the other axis next — at most
    /// `maxPresses` times. Deterministic: same layout, same path.
    @discardableResult
    func focus(_ element: XCUIElement, maxPresses: Int = 30) -> Bool {
        guard element.waitForExistence(timeout: 10) else { return false }
        var preferVertical = true
        for _ in 0..<maxPresses {
            if element.hasFocus { return true }
            let from = focusedElement.exists ? focusedElement.frame : .zero
            let to = element.frame
            let dy = to.midY - from.midY, dx = to.midX - from.midX
            let needsVertical = abs(dy) > max(24, from.height / 2)
            let needsHorizontal = abs(dx) > max(24, from.width / 2)
            let vertical = needsVertical && (preferVertical || !needsHorizontal)
            remote.press(vertical ? (dy > 0 ? .down : .up) : (dx > 0 ? .right : .left))
            settle(0.35)
            let after = focusedElement.exists ? focusedElement.frame : .zero
            if after == from { preferVertical.toggle() }   // blocked that way: try the other axis
        }
        return element.hasFocus
    }

    /// Presses a remote button `times` times with a settle between presses.
    func press(_ button: XCUIRemote.Button, times: Int = 1) {
        for _ in 0..<times { remote.press(button); settle(0.45) }
    }
    #endif
}
