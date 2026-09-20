import CoreGraphics
import Foundation

/// Pure day-paging maths for the guide timeline: how far one day is in scroll
/// points, the clamped scroll offset after paging by ±N days, whether the
/// prev/next controls are live at the horizon edges, and the day label for the
/// pane's left-edge anchor instant. Paging is ±24h from the current anchor (NOT
/// start-of-day) so it stays continuous with the existing point-based scroll,
/// and clamps to the same past/forward horizon regular panning uses. Time-zone
/// and `now` are injected so every value is deterministic in tests (no locale
/// `DateFormatter`, no real `Date()`), mirroring the `GuideTimeline` idiom.
enum GuideDayNavigation {
    /// Scroll points spanned by one day (48 half-hour columns).
    static var dayWidth: CGFloat { CGFloat(GuideGeometry.dayMs) * GuideGeometry.pointsPerMs }

    /// `x` clamped to `[floor, ceil]` (the shared scroll-horizon bounds).
    static func clamp(_ x: CGFloat, floor: CGFloat, ceil: CGFloat) -> CGFloat {
        min(max(x, floor), ceil)
    }

    /// The scroll offset after paging `days` days from `scrollX`, clamped to the
    /// horizon so paging never overshoots the EPG's coverage.
    static func paged(scrollX: CGFloat, days: Int, floor: CGFloat, ceil: CGFloat) -> CGFloat {
        clamp(scrollX + CGFloat(days) * dayWidth, floor: floor, ceil: ceil)
    }

    /// Whether the Previous-day control is live (room to pan earlier).
    static func canPageBack(scrollX: CGFloat, floor: CGFloat) -> Bool { scrollX > floor }

    /// Whether the Next-day control is live (room to pan later).
    static func canPageForward(scrollX: CGFloat, ceil: CGFloat) -> Bool { scrollX < ceil }

    /// The day label for the pane's left-edge instant relative to `nowMs`:
    /// "Today"/"Yesterday"/"Tomorrow", else a "Mon 22 Sep"-style civil date.
    static func dayLabel(scrollX: CGFloat, originMs: Int, timeZone: TimeZone, nowMs: Int) -> String {
        label(anchorMs: GuideGeometry.timeAt(scrollX, originMs: originMs), nowMs: nowMs, timeZone: timeZone)
    }

    /// The relative/civil label for `anchorMs`'s day versus `nowMs`'s day, both
    /// floored to the injected zone's midnight so the day delta is exact.
    static func label(anchorMs: Int, nowMs: Int, timeZone: TimeZone) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let anchorDay = calendar.startOfDay(for: date(anchorMs))
        let today = calendar.startOfDay(for: date(nowMs))
        switch calendar.dateComponents([.day], from: today, to: anchorDay).day ?? 0 {
        case 0: return "Today"
        case 1: return "Tomorrow"
        case -1: return "Yesterday"
        default: return civilLabel(anchorDay, calendar: calendar)
        }
    }

    /// "Mon 22 Sep" from the day's civil components (no locale `DateFormatter`).
    private static func civilLabel(_ day: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.weekday, .day, .month], from: day)
        let weekday = weekdays[(parts.weekday ?? 1) - 1]
        let month = months[(parts.month ?? 1) - 1]
        return "\(weekday) \(parts.day ?? 1) \(month)"
    }

    private static func date(_ ms: Int) -> Date { Date(timeIntervalSince1970: Double(ms) / 1000) }

    private static let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    private static let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                                 "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
}
