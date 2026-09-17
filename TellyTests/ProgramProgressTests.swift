import Testing
@testable import Telly

/// Unit coverage for the info-overlay progress-bar fraction math.
struct ProgramProgressTests {
    @Test func nilWhenEndEqualsStart() {
        #expect(ProgramProgress.fraction(nowMs: 100, startMs: 100, endMs: 100) == nil)
    }

    @Test func nilWhenEndBeforeStart() {
        #expect(ProgramProgress.fraction(nowMs: 100, startMs: 300, endMs: 200) == nil)
    }

    @Test func zeroBeforeStart() {
        #expect(ProgramProgress.fraction(nowMs: 50, startMs: 100, endMs: 300) == 0)
    }

    @Test func zeroAtStart() {
        #expect(ProgramProgress.fraction(nowMs: 100, startMs: 100, endMs: 300) == 0)
    }

    @Test func oneAtEnd() {
        #expect(ProgramProgress.fraction(nowMs: 300, startMs: 100, endMs: 300) == 1)
    }

    @Test func oneAfterEnd() {
        #expect(ProgramProgress.fraction(nowMs: 999, startMs: 100, endMs: 300) == 1)
    }

    @Test func halfwayIsPointFive() {
        #expect(ProgramProgress.fraction(nowMs: 200, startMs: 100, endMs: 300) == 0.5)
    }

    @Test func quarterIsPointTwoFive() {
        #expect(ProgramProgress.fraction(nowMs: 150, startMs: 100, endMs: 300) == 0.25)
    }
}
