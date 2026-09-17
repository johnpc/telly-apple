import CoreGraphics
import Foundation

/// One 30-min timeline tick: its on-screen x offset and its clock label.
struct GuideTick: Equatable {
    let offset: CGFloat
    let label: String
}

/// Pure timeline maths for the guide header: the 30-min ticks across the visible
/// span, the now-line's on-screen position, and clock labels. Labels are built
/// from `DateComponents` in an injected zone (never a locale `DateFormatter`) so
/// they stay deterministic in tests, mirroring the `XmltvTimestamp` idiom.
enum GuideTimeline {
    /// One tick per 30-min grid mark across the visible span; `offset` is the
    /// mark's absolute x minus `scrollX`, i.e. its position on-screen.
    static func ticks(originMs: Int, scrollX: CGFloat, viewport: CGFloat,
                      timeZone: TimeZone, is24h: Bool) -> [GuideTick] {
        let visible = GuideWindowMath.visibleSpan(originMs: originMs, scrollX: scrollX, viewport: viewport)
        var mark = GuideWindowMath.quantizeDown(timeMs: visible.fromMs, originMs: originMs)
        var result: [GuideTick] = []
        while mark <= visible.toMs {
            let offset = GuideGeometry.xOf(mark, originMs: originMs) - scrollX
            result.append(GuideTick(offset: offset, label: timeLabel(mark, timeZone: timeZone, is24h: is24h)))
            mark += GuideGeometry.halfHourMs
        }
        return result
    }

    /// The now-line's on-screen x, or nil when it falls outside `0...viewport`.
    static func nowLineOffset(nowMs: Int, originMs: Int, scrollX: CGFloat, viewport: CGFloat) -> CGFloat? {
        let offset = GuideGeometry.xOf(nowMs, originMs: originMs) - scrollX
        guard offset >= 0, offset <= viewport else { return nil }
        return offset
    }

    /// "HH:mm" (24-hour) or "h:mm AM/PM" (12-hour) for `ms`, evaluated in
    /// `timeZone`, with zero-padded minutes and no locale `DateFormatter`.
    static func timeLabel(_ ms: Int, timeZone: TimeZone, is24h: Bool) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let at = Date(timeIntervalSince1970: Double(ms) / 1000)
        let hour = calendar.component(.hour, from: at)
        let mm = String(format: "%02d", calendar.component(.minute, from: at))
        guard !is24h else { return "\(String(format: "%02d", hour)):\(mm)" }
        return "\(hour12(hour)):\(mm) \(hour < 12 ? "AM" : "PM")"
    }

    /// Maps a 0...23 hour onto its 1...12 twelve-hour-clock counterpart.
    private static func hour12(_ hour: Int) -> Int {
        let h = hour % 12
        return h == 0 ? 12 : h
    }
}
