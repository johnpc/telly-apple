import Foundation

/// Pure staleness policy for EPG refresh: decides when a playlist's guide data
/// is due for another fetch and converts user-facing hour/day settings into the
/// millisecond intervals the scheduler and retention trim work in. No clock, no
/// I/O — callers supply `nowMs` and the stored `lastUpdatedMs`.
enum RefreshScheduler {
    static let hourMs = 3_600_000
    static let dayMs = 24 * hourMs
    /// Refresh at most once per day by default.
    static let defaultIntervalMs = dayMs
    /// Keep a week of ended programmes before trimming by default.
    static let defaultKeepPastMs = 7 * dayMs

    /// Due when never fetched (`lastUpdatedMs <= 0`) or aged past the default interval.
    static func isDue(lastUpdatedMs: Int, nowMs: Int) -> Bool {
        isDue(lastUpdatedMs: lastUpdatedMs, nowMs: nowMs, intervalMs: defaultIntervalMs)
    }

    /// Due when never fetched, or `intervalMs > 0` and the gap has reached it;
    /// `intervalMs <= 0` disables interval refresh, so only never-fetched is due.
    static func isDue(lastUpdatedMs: Int, nowMs: Int, intervalMs: Int) -> Bool {
        lastUpdatedMs <= 0 || (intervalMs > 0 && nowMs - lastUpdatedMs >= intervalMs)
    }

    /// Hours to millis; `h <= 0` means "None" (never due by interval) → 0.
    static func hoursToMs(_ h: Int) -> Int {
        h <= 0 ? 0 : h * hourMs
    }

    /// Days to millis, clamping negatives to 0.
    static func daysToMs(_ d: Int) -> Int {
        max(d, 0) * dayMs
    }
}
