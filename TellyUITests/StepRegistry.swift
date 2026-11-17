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

    /// The channel the last playback step opened (so later steps can assert on it).
    var lastOpenedChannel = ""

    /// Opens one of the channel list's toolbar screens by name. On a compact
    /// iPhone the bar collapses later items into an overflow menu, so when the
    /// item is not directly on the bar the overflow ("More") is opened first. On
    /// tvOS every item is an icon pill on the bar; the group-filter chips share
    /// labels ("Movies", "Favorites"), so the topmost match is the toolbar's.
    func openToolbarItem(_ name: String) {
        XCTAssertTrue(sees("Channels"), "Expected the channel list")
        #if os(tvOS)
        // The bar exposes each icon-only Label under its title; the group-filter chips
        // reuse some titles ("Movies", "Favorites"), so take the topmost match.
        _ = app.buttons.matching(NSPredicate(format: "label == %@", name)).firstMatch.waitForExistence(timeout: 5)
        let matches = app.buttons.matching(NSPredicate(format: "label == %@", name)).allElementsBoundByIndex
        guard let item = matches.min(by: { $0.frame.minY < $1.frame.minY }) else {
            dumpTree("no toolbar item \(name)")
            return XCTFail("No toolbar item “\(name)”")
        }
        activate(item)
        // Pushed screens leave the list; Settings is a full-screen sheet whose title
        // appears while the list stays in the tree underneath.
        XCTAssertTrue(leftChannelList(within: 5) || sees(name, timeout: 2),
                      "Selecting “\(name)” should open it")
        #else
        let bar = app.navigationBars["Channels"]
        let direct = bar.buttons["toolbar.\(name)"].exists ? bar.buttons["toolbar.\(name)"] : bar.buttons[name]
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
        #endif
    }

    /// True once the channel list is no longer the frontmost screen.
    func leftChannelList(within seconds: TimeInterval) -> Bool {
        eventually(within: seconds) { !app.navigationBars["Channels"].exists && !app.staticTexts["Channels"].exists }
    }

    /// Opens the `index`-th visible programme cell on the guide row for `channel`.
    /// iOS taps the cell; tvOS moves the grid's D-pad cursor: focus the grid, then
    /// step DOWN to the row (rows are in channel-list order) and RIGHT `index` times.
    func openGuideCell(onRow channel: String, index: Int) {
        #if os(tvOS)
        XCTAssertTrue(focusGuideGrid(), "The guide grid should take remote focus")
        let names = app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH 'guide.cell.'")).allElementsBoundByIndex
            .map { $0.identifier.dropFirst("guide.cell.".count).dropLast() }
        let rowOrder = NSOrderedSet(array: names.map(String.init)).array as? [String] ?? []
        let row = rowOrder.firstIndex(of: channel) ?? 0
        press(.down, times: row)
        press(.right, times: index)
        remote.press(.select); settle(0.8)
        #else
        let cells = app.staticTexts.matching(NSPredicate(format: "identifier == %@", "guide.cell.\(channel)|"))
        let cell = cells.element(boundBy: index)
        XCTAssertTrue(cell.waitForExistence(timeout: 10), "Guide row “\(channel)” should have programme cells")
        activate(cell)
        #endif
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
