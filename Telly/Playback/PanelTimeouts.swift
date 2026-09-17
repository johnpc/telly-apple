import Foundation

/// Appearance -> Player -> "Panels timeout, sec", resolved to the three overlay
/// auto-hide durations. The default (5 s) maps to today's measured constants
/// (5.35 s info / 5.5 s zap / 5 s quick-bar); other choices keep the same
/// measured offsets over the chosen base. Ported from Android `PanelTimeouts`.
struct PanelTimeouts: Equatable {
    let infoMs: Int
    let zapMs: Int
    let quickBarMs: Int

    private static let msPerSecond = 1_000
    private static let infoExtraMs = 350   // PlaybackViewModel.kt:178 (5_350)
    private static let zapExtraMs = 500    // PlaybackViewModel.kt:181 (5_500)

    static let `default` = PanelTimeouts(infoMs: 5_350, zapMs: 5_500, quickBarMs: 5_000)

    static func forSeconds(_ seconds: Int) -> PanelTimeouts {
        PanelTimeouts(
            infoMs: seconds * msPerSecond + infoExtraMs,
            zapMs: seconds * msPerSecond + zapExtraMs,
            quickBarMs: seconds * msPerSecond
        )
    }
}
