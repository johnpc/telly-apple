import Testing
@testable import Telly

/// Unit coverage for `SeekMath` — the pure catch-up seek/offset arithmetic.
struct SeekMathTests {

    @Test func seekByClampsLowAtZero() {
        #expect(SeekMath.seekBy(current: 2_000, delta: -5_000, duration: 10_000) == 0)
    }

    @Test func seekByClampsHighAtDuration() {
        #expect(SeekMath.seekBy(current: 8_000, delta: 5_000, duration: 10_000) == 10_000)
    }

    @Test func seekByMidPassesThrough() {
        #expect(SeekMath.seekBy(current: 3_000, delta: 2_000, duration: 10_000) == 5_000)
    }

    @Test func seekByNegativeDeltaWithinRange() {
        #expect(SeekMath.seekBy(current: 6_000, delta: -1_000, duration: 10_000) == 5_000)
    }

    @Test func seekByNegativeDurationFloorsAtZero() {
        #expect(SeekMath.seekBy(current: 1_000, delta: 500, duration: -1) == 0)
    }

    @Test func rewindLiveOffsetNormalCase() {
        #expect(SeekMath.rewindLiveOffset(nowMs: 10_000, deltaMs: 3_000, startMs: 2_000) == 5_000)
    }

    @Test func rewindLiveOffsetFloorsAtZero() {
        #expect(SeekMath.rewindLiveOffset(nowMs: 4_000, deltaMs: 3_000, startMs: 2_000) == 0)
    }
}
