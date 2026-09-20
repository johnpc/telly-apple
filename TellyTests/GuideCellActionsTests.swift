import Testing
@testable import Telly

/// The pure per-selection action set the info panel offers: an airing cell →
/// Watch, a catch-up-eligible past cell → catch-up, any other info cell → My
/// List, and a filler slot → nothing.
struct GuideCellActionsTests {
    private func channel() -> ChannelEntity {
        ChannelEntity(playlistId: 1, number: 1, sortIndex: 0,
                      source: ChannelSource(name: "c", streamUrl: "http://x", tvgId: "c"))
    }

    private func cell() -> GuideCell {
        GuideCell(startMs: 0, endMs: 100,
                  program: ProgramEntity(channelTvgId: "c", startMs: 0, endMs: 100,
                                         details: ProgramDetails(title: "P")))
    }

    @Test func tuneOffersWatch() {
        #expect(GuideCellActions.actions(for: .tune(channel())) == [.watch])
    }

    @Test func catchupOffersCatchup() {
        #expect(GuideCellActions.actions(for: .catchup(channel(), cell())) == [.catchup])
    }

    @Test func infoOffersMyList() {
        #expect(GuideCellActions.actions(for: .info(cell())) == [.myList])
    }

    @Test func noneOffersNothing() {
        #expect(GuideCellActions.actions(for: .none).isEmpty)
    }

    @Test func playTitlesAndIcons() {
        #expect(GuideProgramAction.watch.playTitle == "Watch")
        #expect(GuideProgramAction.catchup.playTitle == "Watch from start")
        #expect(GuideProgramAction.myList.playTitle == nil)
        #expect(GuideProgramAction.watch.playIcon == "play.fill")
        #expect(GuideProgramAction.catchup.playIcon == "arrow.counterclockwise")
        #expect(GuideProgramAction.myList.playIcon == "play.fill")
    }
}
