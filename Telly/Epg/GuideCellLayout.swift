import CoreGraphics
import Foundation

/// Where a `GuideCell` sits within the current viewport: its horizontal `offset`
/// and `width` in points, and whether it was `clipped` at the left edge because
/// the programme started before the visible window.
struct GuideCellPlacement: Equatable {
    let offset: CGFloat
    let width: CGFloat
    let clipped: Bool
}

/// Pure placement maths that turns a `GuideCell` into on-screen points for the
/// current scroll offset and viewport width. Reuses `GuideGeometry`; nothing
/// here touches SwiftUI, so every branch is unit-testable headlessly.
enum GuideCellLayout {
    /// Minimum rendered width so a degenerate or barely-visible cell is still a
    /// tappable sliver.
    static let minCell: CGFloat = 8

    /// The cell's placement, or `nil` when it is entirely off the viewport. The
    /// left edge clamps to 0 (flagging `clipped` when the true edge was before
    /// the window), the right edge clamps to `viewport`, and the width floors to
    /// `minCell`.
    static func place(_ cell: GuideCell, originMs: Int, scrollX: CGFloat,
                      viewport: CGFloat) -> GuideCellPlacement? {
        let left = GuideGeometry.xOf(cell.startMs, originMs: originMs) - scrollX
        let right = GuideGeometry.xOf(cell.endMs, originMs: originMs) - scrollX
        guard right > 0, left < viewport else { return nil }
        let clampedLeft = max(left, 0)
        let clampedRight = min(right, viewport)
        return GuideCellPlacement(offset: clampedLeft,
                                  width: max(clampedRight - clampedLeft, minCell),
                                  clipped: left < 0)
    }
}
