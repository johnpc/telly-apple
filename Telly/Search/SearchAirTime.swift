import Foundation

/// The search air-time label (Android `SearchResultsBuilder.airTime`): a bare
/// "HH:mm — HH:mm" range for programmes airing on `atMs`'s local day, prefixed
/// with "EEE, MMM d, " on any other day. The em dash and en-US date pattern
/// mirror Android `ProgramTimes.range` / its `SimpleDateFormat(Locale.US)`.
enum SearchAirTime {
    static func text(program: ProgramEntity, atMs: Int, timeZone: TimeZone) -> String {
        let start = InfoOverlayText.timeLabel(program.startMs, timeZone: timeZone)
        let range = "\(start) — \(InfoOverlayText.timeLabel(program.endMs, timeZone: timeZone))"
        if sameDay(program.startMs, atMs, timeZone: timeZone) { return range }
        return "\(datePrefix(program.startMs, timeZone: timeZone)), \(range)"
    }

    /// A single-instant air-time stamp (Android My List `ProgramTimes.clock`):
    /// "EEE, MMM d, HH:mm" for `atMs` in `timeZone`, reusing the same date-prefix
    /// and time-label helpers as `text(...)` so both share one formatter config.
    static func stamp(atMs: Int, timeZone: TimeZone) -> String {
        "\(datePrefix(atMs, timeZone: timeZone)), \(InfoOverlayText.timeLabel(atMs, timeZone: timeZone))"
    }

    private static func sameDay(_ aMs: Int, _ bMs: Int, timeZone: TimeZone) -> Bool {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        return cal.isDate(date(aMs), inSameDayAs: date(bMs))
    }

    private static func datePrefix(_ ms: Int, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date(ms))
    }

    private static func date(_ ms: Int) -> Date { Date(timeIntervalSince1970: Double(ms) / 1_000) }
}
