import XCTest

/// Shared state passed to every step handler: the launched app plus the capture
/// groups matched from the step's regex (e.g. the tab name in `I open the
/// (\w+) screen`).
final class GherkinWorld {
    let app: XCUIApplication
    var captures: [String] = []

    init(app: XCUIApplication) {
        self.app = app
    }

    /// Activates a control the way the platform does: a tap on iPhone/iPad, and
    /// on tvOS a focus walk (DOWN until the element has focus) then Select.
    func activate(_ element: XCUIElement) {
        #if os(tvOS)
        let remote = XCUIRemote.shared
        var presses = 0
        while !element.hasFocus && presses < 8 { remote.press(.down); presses += 1 }
        remote.press(.select)
        #else
        // A control can exist while a transition is still animating; tapping then is
        // swallowed. Wait (bounded) for it to become hittable before the tap.
        let deadline = Date().addingTimeInterval(5)
        while !element.isHittable && Date() < deadline { RunLoop.current.run(until: Date().addingTimeInterval(0.1)) }
        element.tap()
        #endif
    }

    /// Opens one of the channel list's toolbar screens by name. On a compact
    /// iPhone the bar collapses later items into an overflow menu, so when the
    /// item is not directly on the bar the overflow ("More") is opened first.
    func openToolbarItem(_ name: String) {
        let bar = app.navigationBars["Channels"]
        XCTAssertTrue(bar.waitForExistence(timeout: 10), "Expected the channel list")
        // Scoped to the bar: the group-filter strip has chips with the same labels
        // ("Movies", "Favorites"), so an app-wide `buttons[name]` would be ambiguous.
        let direct = bar.buttons[name]
        if direct.waitForExistence(timeout: 2) {
            activate(direct)
            if leftChannelList(within: 3) { return }
            activate(direct)   // the bar was still morphing in; one more press
            XCTAssertTrue(leftChannelList(within: 5), "Tapping “\(name)” should leave the channel list")
            return
        }
        let overflow = bar.buttons["More"]
        XCTAssertTrue(overflow.waitForExistence(timeout: 5), "“\(name)” is not on the bar and no overflow menu exists")
        activate(overflow)
        let item = app.buttons[name].firstMatch
        XCTAssertTrue(item.waitForExistence(timeout: 5), "Overflow menu should list “\(name)”")
        activate(item)
    }

    /// True once the channel list's bar is no longer the frontmost one.
    private func leftChannelList(within seconds: TimeInterval) -> Bool {
        let gone = NSPredicate(format: "exists == false")
        let wait = XCTNSPredicateExpectation(predicate: gone, object: app.navigationBars["Channels"])
        return XCTWaiter().wait(for: [wait], timeout: seconds) == .completed
    }

    /// Taps the `index`-th visible programme cell on the guide row for `channel`.
    func openGuideCell(onRow channel: String, index: Int) {
        let cells = app.staticTexts.matching(NSPredicate(format: "identifier == %@", "guide.cell.\(channel)|"))
        let cell = cells.element(boundBy: index)
        XCTAssertTrue(cell.waitForExistence(timeout: 10), "Guide row “\(channel)” should have programme cells")
        activate(cell)
    }

    /// Terminates and relaunches WITHOUT the state reset, so persistence across
    /// launches can be asserted (the only launch that keeps state).
    func relaunchKeepingState() {
        app.terminate()
        app.launchArguments = ["-tellyKeepState"]
        app.launch()
    }

    /// First positional capture group, or fails the test with a clear message.
    func capture(_ index: Int = 0, _ file: StaticString = #file, _ line: UInt = #line) -> String {
        guard index < captures.count else {
            XCTFail("Step expected capture group #\(index) but none was matched", file: file, line: line)
            return ""
        }
        return captures[index]
    }
}

/// A registered step: its compiled regex and the closure that runs it.
private struct StepDefinition {
    let regex: NSRegularExpression
    let handler: (GherkinWorld) -> Void
}

/// Registry of Given/When/Then step definitions keyed by regex. Keywords are
/// interchangeable at match time (Cucumber semantics): a `Given` line can match
/// a step defined with `then`, and `And`/`But` inherit the previous keyword's
/// pool — so we just match against one shared pool.
final class StepRegistry {
    private var steps: [StepDefinition] = []

    /// Register a step. `pattern` is a full-match regex; capture groups are
    /// passed to the handler via `world.captures`.
    func define(_ pattern: String, _ handler: @escaping (GherkinWorld) -> Void) {
        let anchored = pattern.hasPrefix("^") ? pattern : "^\(pattern)$"
        guard let regex = try? NSRegularExpression(pattern: anchored) else {
            fatalError("Invalid step regex: \(pattern)")
        }
        steps.append(StepDefinition(regex: regex, handler: handler))
    }

    /// Find the single definition matching `text`. Returns the handler with its
    /// captures bound, or nil if no (or ambiguous) match.
    func match(_ text: String) -> ((GherkinWorld) -> Void)? {
        let range = NSRange(text.startIndex..., in: text)
        let matches = steps.compactMap { def -> (StepDefinition, NSTextCheckingResult)? in
            guard let m = def.regex.firstMatch(in: text, range: range) else { return nil }
            return (def, m)
        }
        guard matches.count == 1, let (def, result) = matches.first else { return nil }

        var captures: [String] = []
        for i in 1..<result.numberOfRanges {
            if let r = Range(result.range(at: i), in: text) {
                captures.append(String(text[r]))
            }
        }
        return { world in
            world.captures = captures
            def.handler(world)
        }
    }

    /// Whether more than one definition matches (ambiguous step) — surfaced as a
    /// distinct failure so specs don't silently run the wrong handler.
    func isAmbiguous(_ text: String) -> Bool {
        let range = NSRange(text.startIndex..., in: text)
        return steps.filter { $0.regex.firstMatch(in: text, range: range) != nil }.count > 1
    }
}
