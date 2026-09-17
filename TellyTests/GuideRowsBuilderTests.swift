import Testing
@testable import Telly

/// Unit coverage for row assembly: grouping programmes by tvg-id, matching each
/// channel via `epgId`, all-filler rows for nil/unmatched ids, and displayNumber.
struct GuideRowsBuilderTests {
    private let half = GuideGeometry.halfHourMs

    private func channel(number: Int, tvgId: String?) -> ChannelEntity {
        ChannelEntity(playlistId: 1, number: number, sortIndex: number,
                      source: ChannelSource(name: "Ch\(number)", streamUrl: "u", tvgId: tvgId))
    }

    private func program(_ tvgId: String, _ start: Int, _ end: Int, _ title: String) -> ProgramEntity {
        ProgramEntity(channelTvgId: tvgId, startMs: start, endMs: end,
                      details: ProgramDetails(title: title))
    }

    @Test func groupsProgrammesByEpgIdAndKeepsChannelOrder() {
        let span = GuideSpan(fromMs: 0, toMs: 2 * half)
        let rows = GuideRowsBuilder.build(
            channels: [channel(number: 7, tvgId: "a"), channel(number: 8, tvgId: "b")],
            programs: [program("a", 0, 2 * half, "OnA"), program("b", 0, half, "OnB")],
            span: span)
        #expect(rows.map(\.channel.source.tvgId) == ["a", "b"])
        #expect(rows[0].displayNumber == 7)
        #expect(rows[1].displayNumber == 8)
        #expect(rows[0].cells.first?.program?.details.title == "OnA")
        #expect(rows[0].cells.allSatisfy { $0.hasInfo })   // single programme fills the span
        #expect(rows[1].cells.contains { !$0.hasInfo })     // OnB leaves a trailing gap
    }

    @Test func nilEpgIdChannelBecomesAllFillerRow() {
        let span = GuideSpan(fromMs: 0, toMs: 2 * half)
        let rows = GuideRowsBuilder.build(
            channels: [channel(number: 1, tvgId: nil)],
            programs: [program("a", 0, half, "OnA")],
            span: span)
        #expect(rows.count == 1)
        #expect(rows[0].cells.allSatisfy { !$0.hasInfo })
        #expect(rows[0].cells.first?.startMs == 0)
        #expect(rows[0].cells.last?.endMs == 2 * half)
    }

    @Test func channelWithoutMatchingProgrammesIsAllFiller() {
        let span = GuideSpan(fromMs: 0, toMs: 2 * half)
        let rows = GuideRowsBuilder.build(
            channels: [channel(number: 3, tvgId: "z")],
            programs: [program("a", 0, half, "OnA")],
            span: span)
        #expect(rows[0].cells.allSatisfy { !$0.hasInfo })
        #expect(rows[0].displayNumber == 3)
    }
}
