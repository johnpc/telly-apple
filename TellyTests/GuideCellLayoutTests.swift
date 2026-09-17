import CoreGraphics
import Foundation
import Testing
@testable import Telly

/// Unit coverage for the pure guide-cell placement maths.
struct GuideCellLayoutTests {

    private let half = GuideGeometry.halfHourMs        // 1_800_000 ms == 160 pt
    private let column = GuideGeometry.pointsPer30Min  // 160

    private func cell(_ start: Int, _ end: Int) -> GuideCell {
        GuideCell(startMs: start, endMs: end, program: nil)
    }

    @Test func minCellMatchesThePlan() {
        #expect(GuideCellLayout.minCell == 8)
    }

    @Test func returnsNilWhenEntirelyOffTheLeftEdge() {
        // Cell ends at the origin; with scrollX 0 its right edge is at 0.
        let placement = GuideCellLayout.place(cell(-half, 0), originMs: 0, scrollX: 0, viewport: 640)
        #expect(placement == nil)
    }

    @Test func returnsNilWhenEntirelyOffTheRightEdge() {
        // Cell starts a full viewport to the right of the visible window.
        let placement = GuideCellLayout.place(cell(4 * half, 5 * half), originMs: 0, scrollX: 0, viewport: 640)
        #expect(placement == nil)
    }

    @Test func placesAFullyVisibleCellAtItsTrueOffsetAndWidth() {
        // One 30-min cell starting one column in, no scroll: offset 160, width 160.
        let placement = GuideCellLayout.place(cell(half, 2 * half), originMs: 0, scrollX: 0, viewport: 640)
        #expect(placement?.offset == column)
        #expect(placement?.width == column)
        #expect(placement?.clipped == false)
    }

    @Test func appliesScrollOffsetToTheOffset() {
        let placement = GuideCellLayout.place(cell(half, 2 * half), originMs: 0, scrollX: 40, viewport: 640)
        #expect(placement?.offset == column - 40)
        #expect(placement?.width == column)
    }

    @Test func clampsLeftToZeroAndFlagsClippedWhenStartedBeforeTheWindow() {
        // Programme runs [-30min, +30min): its left edge is at -160, clamped to 0.
        let placement = GuideCellLayout.place(cell(-half, half), originMs: 0, scrollX: 0, viewport: 640)
        #expect(placement?.offset == 0)
        #expect(placement?.clipped == true)
        #expect(placement?.width == column)   // 0...160 of the 320-pt cell
    }

    @Test func clampsWidthToTheViewportForAVeryLongProgramme() {
        // A 24-column programme far wider than the 640-pt viewport.
        let placement = GuideCellLayout.place(cell(0, 24 * half), originMs: 0, scrollX: 0, viewport: 640)
        #expect(placement?.offset == 0)
        #expect(placement?.width == 640)
        #expect(placement?.clipped == false)
    }

    @Test func floorsADegenerateCellToMinCell() {
        // A 1-ms cell one column in: raw width is sub-pixel → floors to minCell.
        let placement = GuideCellLayout.place(cell(half, half + 1), originMs: 0, scrollX: 0, viewport: 640)
        #expect(placement?.width == GuideCellLayout.minCell)
        #expect(placement?.offset == column)
    }
}
