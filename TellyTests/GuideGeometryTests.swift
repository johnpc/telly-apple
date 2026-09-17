import CoreGraphics
import Foundation
import Testing
@testable import Telly

/// Unit coverage for the pure guide-grid layout math.
struct GuideGeometryTests {

    private let utc = TimeZone(identifier: "UTC")!

    @Test func constantsMatchTheFixedScale() {
        #expect(GuideGeometry.pointsPer30Min == 160)
        #expect(GuideGeometry.halfHourMs == 1_800_000)
        #expect(GuideGeometry.dayMs == 86_400_000)
        #expect(GuideGeometry.channelColumnWidth == 270)
        #expect(GuideGeometry.rowHeight == 64)
        #expect(GuideGeometry.pointsPerMs == 160 / CGFloat(1_800_000))
    }

    @Test func xOfIsZeroAtTheOrigin() {
        #expect(GuideGeometry.xOf(1_000_000, originMs: 1_000_000) == 0)
    }

    @Test func widthOfOneHalfHourIsOneColumn() {
        #expect(GuideGeometry.widthOf(startMs: 0, endMs: GuideGeometry.halfHourMs) == 160)
    }

    @Test func widthOfClampsNonPositiveDurationToZero() {
        #expect(GuideGeometry.widthOf(startMs: 100, endMs: 50) == 0)   // negative → 0
        #expect(GuideGeometry.widthOf(startMs: 100, endMs: 100) == 0)  // zero → 0
    }

    @Test func xOfAndTimeAtRoundTrip() {
        let originMs = 1_000_000
        let timeMs = 1_234_567
        let x = GuideGeometry.xOf(timeMs, originMs: originMs)
        #expect(GuideGeometry.timeAt(x, originMs: originMs) == timeMs)
    }

    @Test func halfHourFloorRoundsDownAndIsIdempotent() {
        let atTen47 = 47 * 60_000                     // 00:47:00 UTC
        let floored = GuideGeometry.halfHourFloor(atTen47, timeZone: utc)
        #expect(floored == 30 * 60_000)               // → 00:30:00
        #expect(GuideGeometry.halfHourFloor(floored, timeZone: utc) == floored)
    }

    @Test func halfHourFloorHonoursTheInjectedZone() {
        let instant = 21_720_000                      // 06:02:00 UTC / 11:47:00 in Nepal (+5:45)
        let nepal = TimeZone(secondsFromGMT: 20_700)!
        #expect(GuideGeometry.halfHourFloor(instant, timeZone: utc) == 21_600_000)   // 06:00 UTC
        #expect(GuideGeometry.halfHourFloor(instant, timeZone: nepal) == 20_700_000) // 11:30 local
    }
}
