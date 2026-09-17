import CoreGraphics
import Foundation
import Testing
@testable import Telly

/// Unit coverage for the pure guide-timeline maths (ticks, now-line, labels).
struct GuideTimelineTests {

    private let utc = TimeZone(identifier: "UTC")!
    private let est = TimeZone(secondsFromGMT: -5 * 3600)!   // fixed −05:00, no DST
    private let half = GuideGeometry.halfHourMs

    @Test func ticksCoverTheVisibleSpanAtColumnSpacing() {
        let ticks = GuideTimeline.ticks(originMs: 0, scrollX: 0, viewport: 640,
                                        timeZone: utc, is24h: true)
        #expect(ticks.count == 5)                                   // 0…2h inclusive
        #expect(ticks.map(\.offset) == [0, 160, 320, 480, 640])     // one column apart
        #expect(ticks.first?.label == "00:00")
    }

    @Test func ticksSubtractScrollToStayOnScreen() {
        let ticks = GuideTimeline.ticks(originMs: 0, scrollX: 160, viewport: 320,
                                        timeZone: utc, is24h: true)
        #expect(ticks.first?.offset == 0)          // first visible mark sits at the left edge
    }

    @Test func nowLineIsNilWhenOffTheViewport() {
        #expect(GuideTimeline.nowLineOffset(nowMs: 9_000_000, originMs: 0, scrollX: 0, viewport: 640) == nil)
        #expect(GuideTimeline.nowLineOffset(nowMs: -half, originMs: 0, scrollX: 0, viewport: 640) == nil)
    }

    @Test func nowLineOnScreenAccountsForScroll() {
        #expect(GuideTimeline.nowLineOffset(nowMs: half, originMs: 0, scrollX: 0, viewport: 640) == 160)
        #expect(GuideTimeline.nowLineOffset(nowMs: half, originMs: 0, scrollX: 160, viewport: 640) == 0)
        #expect(GuideTimeline.nowLineOffset(nowMs: 7_200_000, originMs: 0, scrollX: 0, viewport: 640) == 640)
    }

    @Test func timeLabel24HourZeroPadsHourAndMinute() {
        #expect(GuideTimeline.timeLabel(47_100_000, timeZone: utc, is24h: true) == "13:05")
        #expect(GuideTimeline.timeLabel(3_900_000, timeZone: utc, is24h: true) == "01:05")
        #expect(GuideTimeline.timeLabel(0, timeZone: utc, is24h: true) == "00:00")
        #expect(GuideTimeline.timeLabel(43_200_000, timeZone: utc, is24h: true) == "12:00")
    }

    @Test func timeLabel12HourUsesMeridiemAndMidnightNoonEdges() {
        #expect(GuideTimeline.timeLabel(47_100_000, timeZone: utc, is24h: false) == "1:05 PM")
        #expect(GuideTimeline.timeLabel(3_900_000, timeZone: utc, is24h: false) == "1:05 AM")
        #expect(GuideTimeline.timeLabel(0, timeZone: utc, is24h: false) == "12:00 AM")
        #expect(GuideTimeline.timeLabel(43_200_000, timeZone: utc, is24h: false) == "12:00 PM")
    }

    @Test func timeLabelHonoursTheInjectedZone() {
        // 13:05 UTC is 08:05 at −05:00.
        #expect(GuideTimeline.timeLabel(47_100_000, timeZone: est, is24h: true) == "08:05")
        #expect(GuideTimeline.timeLabel(47_100_000, timeZone: est, is24h: false) == "8:05 AM")
    }
}
