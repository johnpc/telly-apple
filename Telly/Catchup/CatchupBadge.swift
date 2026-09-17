import Foundation

/// The catch-up chrome subset shown over the archive player: a programme title
/// (when known) and its wall-clock time range. Pure and unit-tested; the range
/// reuses the guide's ``GuideTimeline/timeLabel(_:timeZone:is24h:)`` so 12h/24h
/// formatting lives in exactly one place. Slice 4 ships this subset only — the
/// position/permille overlay is deferred (§9).
struct CatchupBadge: Equatable {
    let title: String?
    let startMs: Int
    let endMs: Int

    /// "{title} · {start}–{end}", or just the range when the title is blank,
    /// each boundary formatted by the shared ``GuideTimeline`` helper.
    func label(is24h: Bool, timeZone: TimeZone) -> String {
        let range = GuideTimeline.timeLabel(startMs, timeZone: timeZone, is24h: is24h)
            + "–" + GuideTimeline.timeLabel(endMs, timeZone: timeZone, is24h: is24h)
        guard let title, !title.isEmpty else { return range }
        return "\(title) · \(range)"
    }
}
