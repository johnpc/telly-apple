import Testing
@testable import Telly

/// The pure cell-activation decision: catch-up wins first on a playable past
/// cell, an airing cell tunes (even when the channel could serve catch-up), an
/// info-carrying non-airing cell shows detail, and a filler cell is inert.
struct GuideActivationTests {
    static let now = 1_000_000_000_000

    private func catchupChannel() -> ChannelEntity {
        ChannelEntity(
            playlistId: 1, number: 1, sortIndex: 0,
            source: ChannelSource(name: "c", streamUrl: "http://x", tvgId: "c"),
            catchup: ChannelCatchup(catchupType: "default",
                                    catchupSource: "http://x/archive?utc=${start}",
                                    catchupDays: nil))
    }

    private func plainChannel() -> ChannelEntity {
        ChannelEntity(playlistId: 1, number: 1, sortIndex: 0,
                      source: ChannelSource(name: "c", streamUrl: "http://x", tvgId: "c"))
    }

    private func program(_ start: Int, _ end: Int) -> ProgramEntity {
        ProgramEntity(channelTvgId: "c", startMs: start, endMs: end,
                      details: ProgramDetails(title: "P"))
    }

    private func row(_ channel: ChannelEntity) -> GuideRow {
        GuideRow(channel: channel, displayNumber: 1, cells: [])
    }

    private func activate(_ channel: ChannelEntity, _ cell: GuideCell) -> GuideSelection {
        GuideActivation.activate(row: row(channel), cell: cell, nowMs: Self.now)
    }

    @Test func playablePastCellReturnsCatchup() {
        let channel = catchupChannel()
        let cell = GuideCell(startMs: Self.now - 5_400_000, endMs: Self.now - 1_800_000,
                             program: program(Self.now - 5_400_000, Self.now - 1_800_000))
        #expect(activate(channel, cell) == .catchup(channel, cell))
    }

    @Test func airingCellTunesEvenWhenCatchupCapable() {
        // Airing cell on a catch-up channel: playability is false (endMs > now),
        // so the airing branch wins and it tunes live.
        let channel = catchupChannel()
        let cell = GuideCell(startMs: Self.now - 1_800_000, endMs: Self.now + 1_800_000,
                             program: program(Self.now - 1_800_000, Self.now + 1_800_000))
        #expect(activate(channel, cell) == .tune(channel))
    }

    @Test func fillerCellIsNone() {
        let cell = GuideCell(startMs: Self.now - 3_600_000, endMs: Self.now - 1_800_000,
                             program: nil)
        #expect(activate(catchupChannel(), cell) == GuideSelection.none)
    }

    @Test func pastInfoCellWithoutCatchupShowsInfo() {
        // A real past programme on a plain channel: no catch-up, not airing → info.
        let cell = GuideCell(startMs: Self.now - 3_600_000, endMs: Self.now - 1_800_000,
                             program: program(Self.now - 3_600_000, Self.now - 1_800_000))
        #expect(activate(plainChannel(), cell) == .info(cell))
    }
}
