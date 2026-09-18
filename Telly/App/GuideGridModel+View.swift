import CoreGraphics
import Foundation

/// View-facing derived geometry for the guide grid: the header's timeline ticks
/// and the now-line's on-screen position for the current window. Both defer to
/// the pure `GuideTimeline` maths (folding in the model's injected time-zone /
/// clock / 24-h flag) so the SwiftUI layer stays arithmetic-free.
extension GuideGridModel {
    /// The 30-min timeline ticks across the visible pane (header labels).
    var timelineTicks: [GuideTick] {
        GuideTimeline.ticks(originMs: originMs, scrollX: scrollX, viewport: viewport,
                            timeZone: timeZone, is24h: is24h)
    }

    /// The now-line's on-screen x, or nil when the current instant is off-pane.
    /// Reads `nowMs` (not `now()`) so it re-renders only when `tick()` advances it.
    var nowLineOffset: CGFloat? {
        GuideTimeline.nowLineOffset(nowMs: nowMs, originMs: originMs,
                                    scrollX: scrollX, viewport: viewport)
    }

    /// Re-reads the injected clock so the now-line advances to the current
    /// instant on the next render; the view fires this once a minute.
    func tick() { nowMs = now() }
}
