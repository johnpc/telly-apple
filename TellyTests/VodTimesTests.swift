import Testing
@testable import Telly

/// Transport clock formatting: `m:ss` under an hour, `h:mm:ss` at/above one, and
/// negative inputs clamping to zero. Boundaries mirror the Android `VodTimesTest`.
struct VodTimesTests {
    @Test func underAnHourRendersMinutesAndSeconds() {
        #expect(VodTimes.format(ms: 0) == "0:00")
        #expect(VodTimes.format(ms: 59_000) == "0:59")
        #expect(VodTimes.format(ms: 60_000) == "1:00")
        #expect(VodTimes.format(ms: 3_599_000) == "59:59")
    }

    @Test func atOrAboveAnHourAddsTheHourFigure() {
        #expect(VodTimes.format(ms: 3_600_000) == "1:00:00")
        #expect(VodTimes.format(ms: 7_507_000) == "2:05:07")
    }

    @Test func negativeInputsClampToZero() {
        #expect(VodTimes.format(ms: -5_000) == "0:00")
    }
}
