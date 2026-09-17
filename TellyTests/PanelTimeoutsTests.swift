import Testing
@testable import Telly

/// The Panels-timeout setting resolved to per-overlay auto-hide durations.
struct PanelTimeoutsTests {
    @Test func defaultMatchesMeasuredConstants() {
        #expect(PanelTimeouts.default == PanelTimeouts(infoMs: 5_350, zapMs: 5_500, quickBarMs: 5_000))
    }

    @Test func forSecondsFiveEqualsDefault() {
        #expect(PanelTimeouts.forSeconds(5) == PanelTimeouts.default)
    }

    @Test func forSecondsScalesBaseKeepingOffsets() {
        #expect(PanelTimeouts.forSeconds(3) == PanelTimeouts(infoMs: 3_350, zapMs: 3_500, quickBarMs: 3_000))
        #expect(PanelTimeouts.forSeconds(10) == PanelTimeouts(infoMs: 10_350, zapMs: 10_500, quickBarMs: 10_000))
    }
}
