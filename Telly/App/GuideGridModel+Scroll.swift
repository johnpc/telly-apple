import CoreGraphics
import Foundation

/// The guide grid's scroll/pan actions, split out of the core model so both
/// files stay within the source-line budget. Every mutation clamps to the
/// past/forward horizon and re-materialises the visible window.
extension GuideGridModel {
    /// Pans the timeline by `delta` points, clamped to the horizon, then re-materialises.
    func scrollTime(byPoints delta: CGFloat) {
        scrollX = clampScroll(scrollX + delta)
        materializeRows()
    }

    /// Re-anchors the scroll to the now column (the origin sits at `scrollX == 0`).
    func jumpToNow() {
        scrollX = 0
        materializeRows()
    }

    /// Sets focus to `cell` on `rowIndex`, pans it into view, then re-materialises.
    func applyFocus(rowIndex: Int, cell: GuideCell, anchorMs: Int) {
        focus = GuideFocus(rowIndex: rowIndex, cell: cell, anchorMs: anchorMs)
        scrollX = clampScroll(pannedScroll(toShow: cell))
        materializeRows()
    }

    /// The scroll offset bringing `cell` on-screen, panning only at a viewport edge.
    func pannedScroll(toShow cell: GuideCell) -> CGFloat {
        let left = GuideGeometry.xOf(cell.startMs, originMs: originMs)
        let right = GuideGeometry.xOf(cell.endMs, originMs: originMs)
        if left < scrollX { return left }
        if right > scrollX + viewport { return right - viewport }
        return scrollX
    }

    func clampScroll(_ x: CGFloat) -> CGFloat {
        GuideDayNavigation.clamp(x, floor: scrollFloorPoints, ceil: scrollCeilPoints)
    }
}
