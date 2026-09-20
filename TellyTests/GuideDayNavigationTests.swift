import CoreGraphics
import Foundation
import Testing
@testable import Telly

/// Unit coverage for the pure guide day-paging maths: day width, clamped paging,
/// prev/next enabled flags, and the relative/civil day label. UTC zone + fixed
/// `now` keep every assertion deterministic (no locale, no real `Date()`).
struct GuideDayNavigationTests {

    private let utc = TimeZone(identifier: "UTC")!
    private let dayMs = 86_400_000

    @Test func dayWidthIsFortyEightHalfHourColumns() {
        #expect(GuideDayNavigation.dayWidth == 7680)   // 48 × 160 points
    }

    @Test func pagedShiftsByWholeDaysWithinBounds() {
        #expect(GuideDayNavigation.paged(scrollX: 0, days: 1, floor: -20000, ceil: 20000) == 7680)
        #expect(GuideDayNavigation.paged(scrollX: 7680, days: -1, floor: -20000, ceil: 20000) == 0)
        #expect(GuideDayNavigation.paged(scrollX: 0, days: 2, floor: -20000, ceil: 20000) == 15360)
    }

    @Test func pagedClampsAtBothHorizonEdges() {
        #expect(GuideDayNavigation.paged(scrollX: 0, days: 1, floor: 0, ceil: 1000) == 1000)     // ceil
        #expect(GuideDayNavigation.paged(scrollX: 0, days: -1, floor: -1000, ceil: 0) == -1000)  // floor
    }

    @Test func canPageBackOnlyWithRoomBeforeTheFloor() {
        #expect(GuideDayNavigation.canPageBack(scrollX: 0, floor: -1000))
        #expect(!GuideDayNavigation.canPageBack(scrollX: -1000, floor: -1000))
    }

    @Test func canPageForwardOnlyWithRoomBeforeTheCeil() {
        #expect(GuideDayNavigation.canPageForward(scrollX: 500, ceil: 1000))
        #expect(!GuideDayNavigation.canPageForward(scrollX: 1000, ceil: 1000))
    }

    @Test func labelIsRelativeWithinOneDayEitherSide() {
        #expect(GuideDayNavigation.label(anchorMs: 3_600_000, nowMs: 0, timeZone: utc) == "Today")
        #expect(GuideDayNavigation.label(anchorMs: dayMs, nowMs: 0, timeZone: utc) == "Tomorrow")
        #expect(GuideDayNavigation.label(anchorMs: -dayMs, nowMs: 0, timeZone: utc) == "Yesterday")
    }

    @Test func labelIsCivilDateBeyondOneDay() {
        // 1970-01-01 is Thursday; +3 days → 1970-01-04, a Sunday.
        #expect(GuideDayNavigation.label(anchorMs: 3 * dayMs, nowMs: 0, timeZone: utc) == "Sun 4 Jan")
    }

    @Test func dayLabelMapsScrollOffsetThroughTheOrigin() {
        #expect(GuideDayNavigation.dayLabel(scrollX: 0, originMs: 0, timeZone: utc, nowMs: 0) == "Today")
        #expect(GuideDayNavigation.dayLabel(scrollX: GuideDayNavigation.dayWidth,
                                            originMs: 0, timeZone: utc, nowMs: 0) == "Tomorrow")
    }
}
