import CoreGraphics
import Foundation

/// The guide grid's day-paging actions + derived state, split out of the core
/// model so both files stay within the source-line budget. Paging shifts the
/// visible window by ±24h (via the pure `GuideDayNavigation`), clamps to the
/// same horizon as drag-panning, and re-materialises. "Now" reuses `jumpToNow`.
extension GuideGridModel {
    /// Minimum scroll offset (never earlier than `pastDays` before the origin).
    var scrollFloorPoints: CGFloat { GuideWindowMath.scrollFloor(pastDays: Self.pastDays) }
    /// Maximum scroll offset (`forwardDays` ahead of the origin).
    var scrollCeilPoints: CGFloat { GuideWindowMath.scrollCeil() }

    /// The day label for the pane's left edge ("Today"/"Yesterday"/civil date).
    var dayLabel: String {
        GuideDayNavigation.dayLabel(scrollX: scrollX, originMs: originMs, timeZone: timeZone, nowMs: now())
    }

    /// Whether the Previous-day control is live (unclamped room to pan earlier).
    var canPageDayBack: Bool { GuideDayNavigation.canPageBack(scrollX: scrollX, floor: scrollFloorPoints) }

    /// Whether the Next-day control is live (unclamped room to pan later).
    var canPageDayForward: Bool { GuideDayNavigation.canPageForward(scrollX: scrollX, ceil: scrollCeilPoints) }

    /// Pages the timeline by `days` days, clamped to the horizon, then re-materialises.
    func pageDay(_ days: Int) {
        scrollX = GuideDayNavigation.paged(scrollX: scrollX, days: days,
                                           floor: scrollFloorPoints, ceil: scrollCeilPoints)
        materializeRows()
    }
}
