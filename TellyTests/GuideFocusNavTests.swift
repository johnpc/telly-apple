import Testing
@testable import Telly

/// Unit coverage for the guide's focus transforms: right/left stepping and the
/// left-edge/window boundary, cellAt containment vs edge-clamping, initialFocus
/// on row 0's now cell, and resolve keeping the row + anchor stable across
/// re-materialisation. Also exercises the `GuideFocus` data struct.
struct GuideFocusNavTests {
    private let half = GuideGeometry.halfHourMs

    private func channel(number: Int, tvgId: String?) -> ChannelEntity {
        ChannelEntity(playlistId: 1, number: number, sortIndex: number,
                      source: ChannelSource(name: "Ch\(number)", streamUrl: "u", tvgId: tvgId))
    }

    private func program(_ tvgId: String, _ start: Int, _ end: Int, _ title: String) -> ProgramEntity {
        ProgramEntity(channelTvgId: tvgId, startMs: start, endMs: end,
                      details: ProgramDetails(title: title))
    }

    /// Three contiguous half-open cells: [0,100) [100,200) [200,300).
    private func strip() -> [GuideCell] {
        [GuideCell(startMs: 0, endMs: 100, program: nil),
         GuideCell(startMs: 100, endMs: 200, program: nil),
         GuideCell(startMs: 200, endMs: 300, program: nil)]
    }

    // MARK: rightOf

    @Test func rightOfStepsToNextCell() {
        let cells = strip()
        #expect(GuideFocusNav.rightOf(cells: cells, focused: cells[0]) == cells[1])
        #expect(GuideFocusNav.rightOf(cells: cells, focused: cells[1]) == cells[2])
    }

    @Test func rightOfIsNilAtLastCell() {
        let cells = strip()
        #expect(GuideFocusNav.rightOf(cells: cells, focused: cells[2]) == nil)
    }

    // MARK: leftOf

    @Test func leftOfStepsToPreviousCell() {
        let cells = strip()
        #expect(GuideFocusNav.leftOf(cells: cells, focused: cells[2], windowStartMs: 0) == cells[1])
        #expect(GuideFocusNav.leftOf(cells: cells, focused: cells[1], windowStartMs: 0) == cells[0])
    }

    @Test func leftOfIsNilAtFirstCell() {
        let cells = strip()
        #expect(GuideFocusNav.leftOf(cells: cells, focused: cells[0], windowStartMs: 0) == nil)
    }

    @Test func leftOfIsNilWhenPreviousBeginsBeforeWindowStart() {
        let cells = strip()
        // windowStart at 150: the previous cell [100,200) begins before it → hold.
        #expect(GuideFocusNav.leftOf(cells: cells, focused: cells[2], windowStartMs: 150) == nil)
        // Exactly on the previous cell's start is reachable (>=).
        #expect(GuideFocusNav.leftOf(cells: cells, focused: cells[2], windowStartMs: 100) == cells[1])
    }

    // MARK: cellAt

    @Test func cellAtReturnsContainingCell() {
        let cells = strip()
        #expect(GuideFocusNav.cellAt(cells: cells, anchorMs: 0) == cells[0])
        #expect(GuideFocusNav.cellAt(cells: cells, anchorMs: 150) == cells[1])
        #expect(GuideFocusNav.cellAt(cells: cells, anchorMs: 299) == cells[2])
    }

    @Test func cellAtClampsToFirstWhenAnchorBeforeStrip() {
        let cells = [GuideCell(startMs: 100, endMs: 200, program: nil),
                     GuideCell(startMs: 200, endMs: 300, program: nil)]
        #expect(GuideFocusNav.cellAt(cells: cells, anchorMs: 50) == cells[0])
    }

    @Test func cellAtClampsToLastWhenAnchorAfterStrip() {
        let cells = strip()
        #expect(GuideFocusNav.cellAt(cells: cells, anchorMs: 300) == cells[2])   // == end is excluded
        #expect(GuideFocusNav.cellAt(cells: cells, anchorMs: 999) == cells[2])
    }

    @Test func cellAtIsNilForEmptyStrip() {
        #expect(GuideFocusNav.cellAt(cells: [], anchorMs: 0) == nil)
    }

    // MARK: initialFocus

    @Test func initialFocusPicksNowCellOnRowZero() {
        let span = GuideSpan(fromMs: 0, toMs: 2 * half)
        let rows = GuideRowsBuilder.build(
            channels: [channel(number: 1, tvgId: "a"), channel(number: 2, tvgId: "b")],
            programs: [program("a", 0, half, "Early"), program("a", half, 2 * half, "Late")],
            span: span)
        let focus = GuideFocusNav.initialFocus(rows: rows, nowMs: half + 10)
        #expect(focus?.rowIndex == 0)
        #expect(focus?.anchorMs == half + 10)
        #expect(focus?.cell.program?.details.title == "Late")
    }

    @Test func initialFocusIsNilForEmptyRows() {
        #expect(GuideFocusNav.initialFocus(rows: [], nowMs: 0) == nil)
    }

    // MARK: resolve

    @Test func resolveFallsBackToInitialFocusWhenCurrentIsNil() {
        let span = GuideSpan(fromMs: 0, toMs: 2 * half)
        let rows = GuideRowsBuilder.build(
            channels: [channel(number: 1, tvgId: "a")],
            programs: [program("a", 0, 2 * half, "Show")], span: span)
        let focus = GuideFocusNav.resolve(rows: rows, nowMs: 5, current: nil)
        #expect(focus?.rowIndex == 0)
        #expect(focus?.anchorMs == 5)
    }

    @Test func resolveKeepsRowIndexAndRepicksCellByAnchor() {
        let span = GuideSpan(fromMs: 0, toMs: 2 * half)
        // Old focus on row 1, anchored inside the first half hour.
        let current = GuideFocus(
            rowIndex: 1,
            cell: GuideCell(startMs: 0, endMs: half, program: nil),
            anchorMs: 10)
        // Rows re-materialise; row 1 now carries a programme covering the anchor.
        let rows = GuideRowsBuilder.build(
            channels: [channel(number: 1, tvgId: "a"), channel(number: 2, tvgId: "b")],
            programs: [program("b", 0, half, "OnB")], span: span)
        let focus = GuideFocusNav.resolve(rows: rows, nowMs: 999, current: current)
        #expect(focus?.rowIndex == 1)
        #expect(focus?.anchorMs == 10)
        #expect(focus?.cell.program?.details.title == "OnB")
    }

    @Test func resolveClampsRowIndexWhenRowsShrink() {
        let span = GuideSpan(fromMs: 0, toMs: 2 * half)
        let current = GuideFocus(
            rowIndex: 5,
            cell: GuideCell(startMs: 0, endMs: half, program: nil),
            anchorMs: half + 5)
        let rows = GuideRowsBuilder.build(
            channels: [channel(number: 1, tvgId: "a")],
            programs: [program("a", 0, 2 * half, "Only")], span: span)
        let focus = GuideFocusNav.resolve(rows: rows, nowMs: 0, current: current)
        #expect(focus?.rowIndex == 0)                       // clamped to last row
        #expect(focus?.cell.program?.details.title == "Only")
    }

    @Test func resolveIsNilForEmptyRows() {
        let current = GuideFocus(
            rowIndex: 0, cell: GuideCell(startMs: 0, endMs: 100, program: nil), anchorMs: 0)
        #expect(GuideFocusNav.resolve(rows: [], nowMs: 0, current: current) == nil)
    }
}
