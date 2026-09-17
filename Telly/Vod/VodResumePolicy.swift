import Foundation

/// When a stored position is worth resuming (ux-spec §VOD): between 5% and 95%
/// of the duration telly offers Resume/Start-over; past 95% the item counts as
/// finished and its position is cleared. Unknown/≤0 duration never resumes or
/// persists. Pure integer permille math ported 1:1 from the Android
/// `VodResumePolicy`.
enum VodResumePolicy {
    private static let permille = 1000
    private static let minResumePermille = 50
    private static let maxResumePermille = 950

    static func offerResume(positionMs: Int, durationMs: Int) -> Bool {
        (minResumePermille...maxResumePermille).contains(permilleOf(positionMs: positionMs, durationMs: durationMs))
    }

    static func finished(positionMs: Int, durationMs: Int) -> Bool {
        permilleOf(positionMs: positionMs, durationMs: durationMs) > maxResumePermille
    }

    private static func permilleOf(positionMs: Int, durationMs: Int) -> Int {
        durationMs <= 0 ? -1 : positionMs * permille / durationMs
    }
}
