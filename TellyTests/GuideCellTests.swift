import Testing
@testable import Telly

/// Unit coverage for the guide cell model: info flag + half-open containment.
struct GuideCellTests {

    private func program(_ start: Int, _ end: Int, _ title: String = "show") -> ProgramEntity {
        ProgramEntity(channelTvgId: "a", startMs: start, endMs: end,
                      details: ProgramDetails(title: title))
    }

    @Test func hasInfoReflectsWhetherAProgrammeIsAttached() {
        let withProgram = GuideCell(startMs: 0, endMs: 100, program: program(0, 100))
        let filler = GuideCell(startMs: 0, endMs: 100, program: nil)
        #expect(withProgram.hasInfo)
        #expect(!filler.hasInfo)
    }

    @Test func containsIsHalfOpenAtBothEdges() {
        let cell = GuideCell(startMs: 100, endMs: 200, program: nil)
        #expect(cell.contains(100))      // start instant is inside
        #expect(cell.contains(150))      // interior
        #expect(!cell.contains(200))     // end instant is excluded
        #expect(!cell.contains(50))      // before the start
        #expect(!cell.contains(250))     // after the end
    }
}
