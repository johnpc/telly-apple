import CoreGraphics
import Foundation

/// Pure layout math for the TV-guide grid: it maps epoch-millis instants onto
/// horizontal points at a fixed 30-min column scale, and back. Kept View-free
/// so every conversion is unit-testable headlessly. Time-zone is injected (never
/// read from the locale) so the half-hour floor is deterministic in tests, and
/// the UTC/injected-`Calendar` idiom mirrors `XmltvTimestamp`.
enum GuideGeometry {
    /// Points spanned by one 30-minute column (the timeline's fixed scale).
    static let pointsPer30Min: CGFloat = 160
    /// Milliseconds in one 30-minute column.
    static let halfHourMs = 30 * 60_000
    /// Milliseconds in one day (48 half-hour columns).
    static let dayMs = 48 * halfHourMs
    /// Width of the fixed left channel column.
    static let channelColumnWidth: CGFloat = 270
    /// Height of one channel row.
    static let rowHeight: CGFloat = 64

    /// Points per millisecond at the fixed 30-min column scale.
    static var pointsPerMs: CGFloat { pointsPer30Min / CGFloat(halfHourMs) }

    /// Floors an epoch-millis instant to the start of its half-hour, evaluated
    /// in `timeZone` (so :00/:30 land on the zone's civil clock, not UTC — even
    /// for zones whose offset is not a whole 30 minutes, e.g. +05:45). Floors in
    /// the zone-shifted space, then unshifts back to the real epoch instant.
    static func halfHourFloor(_ nowMs: Int, timeZone: TimeZone) -> Int {
        let offsetMs = timeZone.secondsFromGMT(for: date(ofMs: nowMs)) * 1000
        let localMs = nowMs + offsetMs
        return localMs - localMs % halfHourMs - offsetMs
    }

    /// Horizontal offset in points for `timeMs`, measured from the window origin
    /// (0 at `originMs`, growing 160 points per 30 minutes).
    static func xOf(_ timeMs: Int, originMs: Int) -> CGFloat {
        CGFloat(timeMs - originMs) * pointsPerMs
    }

    /// Inverse of `xOf`: the epoch-millis instant at horizontal offset `x`.
    static func timeAt(_ x: CGFloat, originMs: Int) -> Int {
        originMs + Int((x / pointsPerMs).rounded())
    }

    /// Points wide for a `[startMs, endMs)` duration; a non-positive duration
    /// clamps to 0 (never a negative width).
    static func widthOf(startMs: Int, endMs: Int) -> CGFloat {
        max(CGFloat(endMs - startMs) * pointsPerMs, 0)
    }

    private static func date(ofMs ms: Int) -> Date {
        Date(timeIntervalSince1970: Double(ms) / 1000)
    }
}
