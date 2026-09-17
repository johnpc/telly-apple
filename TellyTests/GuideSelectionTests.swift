import Testing
@testable import Telly

/// The guide cell-activation outcome: the three cases are distinct and carry the
/// expected payloads (Equatable is synthesised, so this pins the semantics).
struct GuideSelectionTests {
    private func channel(_ tvgId: String) -> ChannelEntity {
        ChannelEntity(playlistId: 1, number: 1, sortIndex: 0,
                      source: ChannelSource(name: tvgId, streamUrl: "http://x", tvgId: tvgId))
    }

    private var cell: GuideCell {
        GuideCell(startMs: 0, endMs: 100, program: nil)
    }

    @Test func casesAreDistinct() {
        #expect(GuideSelection.tune(channel("a")) != .info(cell))
        #expect(GuideSelection.info(cell) != GuideSelection.none)
        #expect(GuideSelection.none == GuideSelection.none)
        #expect(GuideSelection.catchup(channel("a"), cell) != .tune(channel("a")))
    }

    @Test func sameCasePayloadsCompareEqual() {
        #expect(GuideSelection.tune(channel("a")) == .tune(channel("a")))
        #expect(GuideSelection.tune(channel("a")) != .tune(channel("b")))
        #expect(GuideSelection.info(cell) == .info(cell))
        #expect(GuideSelection.catchup(channel("a"), cell) == .catchup(channel("a"), cell))
        #expect(GuideSelection.catchup(channel("a"), cell) != .catchup(channel("b"), cell))
    }
}
