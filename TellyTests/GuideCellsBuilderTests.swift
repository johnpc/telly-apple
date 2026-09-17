import Testing
@testable import Telly

/// Unit coverage for the per-channel cell-strip fold: sorting, span clamping,
/// dropping out-of-window programmes, and grid-aligned "No information" filler.
struct GuideCellsBuilderTests {
    private let half = GuideGeometry.halfHourMs

    private func program(_ start: Int, _ end: Int, _ title: String = "show") -> ProgramEntity {
        ProgramEntity(channelTvgId: "a", startMs: start, endMs: end,
                      details: ProgramDetails(title: title))
    }

    /// Asserts the strip tiles `[from, to)` with no gaps and no overlaps.
    private func expectContiguous(_ cells: [GuideCell], from: Int, to: Int) {
        #expect(cells.first?.startMs == from)
        #expect(cells.last?.endMs == to)
        for index in 0..<(cells.count - 1) {
            #expect(cells[index].endMs == cells[index + 1].startMs)
        }
    }

    @Test func contiguousProgrammesProduceNoFiller() {
        let span = GuideSpan(fromMs: 0, toMs: 4 * half)
        let cells = GuideCellsBuilder.build(
            programs: [program(0, half), program(half, 2 * half),
                       program(2 * half, 3 * half), program(3 * half, 4 * half)],
            span: span)
        #expect(cells.count == 4)
        #expect(cells.allSatisfy { $0.hasInfo })
        expectContiguous(cells, from: 0, to: 4 * half)
    }

    @Test func gapBetweenProgrammesFillsOnTheGrid() {
        let span = GuideSpan(fromMs: 0, toMs: 4 * half)
        // P1 ends off-grid at half+300s; the gap up to 3*half splits on 2*half.
        let cells = GuideCellsBuilder.build(
            programs: [program(0, half + 300_000, "P1"), program(3 * half, 4 * half, "P2")],
            span: span)
        expectContiguous(cells, from: 0, to: 4 * half)
        let fillers = cells.filter { !$0.hasInfo }
        #expect(fillers.map(\.startMs) == [half + 300_000, 2 * half])
        #expect(fillers.map(\.endMs) == [2 * half, 3 * half])
    }

    @Test func programmeStartingLateGetsLeadingAndTrailingFiller() {
        let span = GuideSpan(fromMs: 0, toMs: 4 * half)
        let cells = GuideCellsBuilder.build(programs: [program(2 * half, 3 * half)], span: span)
        expectContiguous(cells, from: 0, to: 4 * half)
        #expect(cells.map(\.hasInfo) == [false, false, true, false])
        #expect(cells.filter { !$0.hasInfo }.allSatisfy { $0.endMs - $0.startMs == half })
    }

    @Test func emptyProgrammesProduceAllFillerCoveringSpan() {
        let span = GuideSpan(fromMs: 0, toMs: 4 * half)
        let cells = GuideCellsBuilder.build(programs: [], span: span)
        #expect(cells.count == 4)
        #expect(cells.allSatisfy { !$0.hasInfo })
        expectContiguous(cells, from: 0, to: 4 * half)
    }

    @Test func programmesAreClampedAndDroppedAtSpanEdges() {
        let span = GuideSpan(fromMs: 0, toMs: 4 * half)
        let cells = GuideCellsBuilder.build(
            programs: [program(-half, half, "clampLeft"), program(3 * half, 5 * half, "clampRight"),
                       program(-2 * half, -half, "before"), program(4 * half, 5 * half, "after")],
            span: span)
        expectContiguous(cells, from: 0, to: 4 * half)
        let titles = cells.compactMap { $0.program?.details.title }
        #expect(titles == ["clampLeft", "clampRight"])
        #expect(cells.first?.endMs == half)   // left edge clamped to span start
        #expect(cells.last?.startMs == 3 * half)  // right edge clamped to span end
    }

    @Test func overlappingProgrammeIsSkipped() {
        let span = GuideSpan(fromMs: 0, toMs: 2 * half)
        let cells = GuideCellsBuilder.build(
            programs: [program(0, 2 * half, "long"), program(half, 2 * half, "inner")],
            span: span)
        #expect(cells.count == 1)
        #expect(cells.first?.program?.details.title == "long")
    }
}
