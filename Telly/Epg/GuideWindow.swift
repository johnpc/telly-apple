import CoreGraphics
import Foundation

/// A half-open epoch-millis time range on the guide timeline.
struct GuideSpan: Equatable {
    let fromMs: Int
    let toMs: Int
}

/// Pure windowing maths for the guide grid: which time range is on-screen, the
/// wider range to materialise programmes for, and how far the horizontal scroll
/// may pan. Every conversion reuses `GuideGeometry`; nothing here touches
/// SwiftUI, so all bounds are unit-testable headlessly.
enum GuideWindowMath {
    /// Extra time materialised beyond the viewport on each side (3 hours).
    static let prefetchMs = 3 * 60 * 60_000
    /// Forward scroll horizon in days from the window origin.
    static let forwardDays = 7

    /// The on-screen time range for the current scroll offset and viewport width.
    static func visibleSpan(originMs: Int, scrollX: CGFloat, viewport: CGFloat) -> GuideSpan {
        GuideSpan(fromMs: GuideGeometry.timeAt(scrollX, originMs: originMs),
                  toMs: GuideGeometry.timeAt(scrollX + viewport, originMs: originMs))
    }

    /// The visible span widened by `prefetchMs` on each side, with both edges
    /// floored onto the enclosing 30-min grid mark so cell strips tile cleanly.
    static func materializeSpan(originMs: Int, scrollX: CGFloat, viewport: CGFloat) -> GuideSpan {
        let visible = visibleSpan(originMs: originMs, scrollX: scrollX, viewport: viewport)
        return GuideSpan(fromMs: quantizeDown(timeMs: visible.fromMs - prefetchMs, originMs: originMs),
                         toMs: quantizeDown(timeMs: visible.toMs + prefetchMs, originMs: originMs))
    }

    /// Floors `timeMs` to the nearest lower 30-min grid mark measured from
    /// `originMs`. Idempotent: quantising an already-quantised value is a no-op.
    static func quantizeDown(timeMs: Int, originMs: Int) -> Int {
        let marks = (Double(timeMs - originMs) / Double(GuideGeometry.halfHourMs)).rounded(.down)
        return originMs + Int(marks) * GuideGeometry.halfHourMs
    }

    /// Minimum scroll offset in points: never pan earlier than `pastDays` before
    /// the origin (clamped to 0 for a non-positive `pastDays`).
    static func scrollFloor(pastDays: Int) -> CGFloat {
        guard pastDays > 0 else { return 0 }
        return -CGFloat(pastDays * GuideGeometry.dayMs) * GuideGeometry.pointsPerMs
    }

    /// Maximum scroll offset in points: `forwardDays` ahead of the origin.
    static func scrollCeil() -> CGFloat {
        CGFloat(forwardDays * GuideGeometry.dayMs) * GuideGeometry.pointsPerMs
    }
}
