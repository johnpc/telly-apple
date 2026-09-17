import Foundation

/// The now/next progress-bar math for the info overlay: how far through the
/// current programme the wall clock is. Pure and clock-injected (`nowMs` comes
/// from the model's `now` seam) so the bar is unit-tested without a real clock.
enum ProgramProgress {
    /// Fraction in `0...1` of `[startMs, endMs)` elapsed at `nowMs`, or nil when
    /// the window is degenerate (`endMs <= startMs`) so the view hides the bar.
    static func fraction(nowMs: Int, startMs: Int, endMs: Int) -> Double? {
        guard endMs > startMs else { return nil }
        if nowMs <= startMs { return 0 }
        if nowMs >= endMs { return 1 }
        return Double(nowMs - startMs) / Double(endMs - startMs)
    }
}
