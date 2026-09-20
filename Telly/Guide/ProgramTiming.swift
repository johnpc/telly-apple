import Foundation

/// Where a programme sits relative to the wall clock, driving the info panel's
/// "Now"/"Next" badge. `.next` is contextual — only the channel-detail now/next
/// block knows the immediately-upcoming programme — so `of(...)` never infers it;
/// it distinguishes only airing / future / past from the time boundaries.
enum ProgramTiming: Equatable {
    case now, next, upcoming, past

    /// The badge text, or nil when the air-time range / date already conveys it.
    var label: String? {
        switch self {
        case .now: return "Now"
        case .next: return "Next"
        case .upcoming, .past: return nil
        }
    }

    /// Classifies `[startMs, endMs)` against `nowMs` (half-open, matching
    /// ``GuideCell/contains(_:)``): airing → `.now`, wholly future → `.upcoming`,
    /// already ended → `.past`.
    static func of(startMs: Int, endMs: Int, nowMs: Int) -> ProgramTiming {
        if startMs <= nowMs && nowMs < endMs { return .now }
        return startMs > nowMs ? .upcoming : .past
    }
}
