import Foundation

/// Pure formatting for the catch-up transport row: the read-only progress-bar
/// permille and the elapsed/duration spans. Ports the Android `ProgramTimes`
/// helpers (`ProgramTimes.kt:62-85`); the permille delegates to the shared
/// ``ProgramProgress/fraction(nowMs:startMs:endMs:)`` so the bar math lives in
/// one place.
enum TransportReadout {
    /// Progress through a finite stream in `0...1000`, `0` when the window is
    /// degenerate. `position` is measured from the archive start (0).
    static func permille(position: Int, duration: Int) -> Int {
        let fraction = ProgramProgress.fraction(nowMs: position, startMs: 0, endMs: duration) ?? 0
        return min(max(Int((fraction * 1000).rounded()), 0), 1000)
    }

    /// "M:SS" under an hour, "H:MM:SS" at or over it; a negative reads "0:00".
    static func span(_ ms: Int) -> String {
        guard ms > 0 else { return "0:00" }
        let total = ms / 1000
        let (hours, minutes, seconds) = (total / 3600, total / 60 % 60, total % 60)
        if hours > 0 { return String(format: "%d:%02d:%02d", hours, minutes, seconds) }
        return String(format: "%d:%02d", minutes, seconds)
    }
}
