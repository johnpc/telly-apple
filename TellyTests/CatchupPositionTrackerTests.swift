import Testing
@testable import Telly

/// Unit coverage for `CatchupPositionTracker` — driven against `FakePlayerEngine`
/// so position moves only on explicit refresh/set, never a wall clock.
@MainActor
struct CatchupPositionTrackerTests {

    @Test func startsAtZero() {
        let tracker = CatchupPositionTracker()
        #expect(tracker.position == 0)
    }

    @Test func resetReturnsToZero() {
        var tracker = CatchupPositionTracker()
        tracker.set(5_000)
        tracker.reset()
        #expect(tracker.position == 0)
    }

    @Test func refreshPullsEnginePosition() {
        var tracker = CatchupPositionTracker()
        let engine = FakePlayerEngine()
        engine.positionMs = 7_500
        tracker.refresh(from: engine)
        #expect(tracker.position == 7_500)
    }

    @Test func setStoresAbsoluteValue() {
        var tracker = CatchupPositionTracker()
        tracker.set(3_200)
        #expect(tracker.position == 3_200)
    }
}
