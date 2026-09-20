import Testing
@testable import Telly

/// The pure programme-timing classification + badge label: airing → `.now`,
/// wholly future → `.upcoming`, ended → `.past`; `.next` is contextual and only
/// its label is asserted (never inferred by `of`).
struct ProgramTimingTests {
    static let now = 1_000_000_000_000

    @Test func airingIsNow() {
        #expect(ProgramTiming.of(startMs: Self.now - 100, endMs: Self.now + 100,
                                 nowMs: Self.now) == .now)
    }

    @Test func startInstantIsNowHalfOpen() {
        #expect(ProgramTiming.of(startMs: Self.now, endMs: Self.now + 100,
                                 nowMs: Self.now) == .now)
    }

    @Test func endInstantIsPastHalfOpen() {
        #expect(ProgramTiming.of(startMs: Self.now - 100, endMs: Self.now,
                                 nowMs: Self.now) == .past)
    }

    @Test func futureIsUpcoming() {
        #expect(ProgramTiming.of(startMs: Self.now + 100, endMs: Self.now + 200,
                                 nowMs: Self.now) == .upcoming)
    }

    @Test func labels() {
        #expect(ProgramTiming.now.label == "Now")
        #expect(ProgramTiming.next.label == "Next")
        #expect(ProgramTiming.upcoming.label == nil)
        #expect(ProgramTiming.past.label == nil)
    }
}
