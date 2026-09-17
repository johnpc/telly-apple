import Foundation
import Testing
@testable import Telly

/// The pure panel-row builder: display-number rule (channel number in "All
/// channels", 1-based position in a group), and now/next title/range/progress
/// reuse of the info-overlay helpers. UTC so the range labels are deterministic.
struct PanelRowInfoTests {
    private let utc = TimeZone(identifier: "UTC")!

    private func ch(_ id: Int, number: Int, group: String? = "Live") -> ChannelEntity {
        ChannelEntity(id: id, playlistId: 1, number: number, sortIndex: number,
                      source: ChannelSource(name: "Ch\(id)", groupTitle: group,
                                            streamUrl: "http://127.0.0.1/\(id).ts"))
    }

    private func nowNext(_ startMs: Int, _ endMs: Int, next: String?) -> NowNext {
        NowNext(
            now: ProgramEntity(channelTvgId: "e", startMs: startMs, endMs: endMs,
                               details: ProgramDetails(title: "Now Show")),
            next: next.map {
                ProgramEntity(channelTvgId: "e", startMs: endMs, endMs: endMs + 1,
                              details: ProgramDetails(title: $0))
            })
    }

    @Test func displayNumberIsChannelNumberInAllChannels() {
        let rows = PanelRowBuilder.rows([ch(1, number: 7), ch(2, number: 9)],
                                        group: ChannelPanelGroups.allChannels,
                                        nowNext: { _ in nil }, nowMs: 0)
        #expect(rows.map(\.displayNumber) == [7, 9])
    }

    @Test func displayNumberIsRowPositionInAGroup() {
        let rows = PanelRowBuilder.rows([ch(1, number: 7), ch(2, number: 9)],
                                        group: "Live", nowNext: { _ in nil }, nowMs: 0)
        #expect(rows.map(\.displayNumber) == [1, 2])
    }

    @Test func rowCarriesNowTitleRangeProgress() {
        let start = 10_000_000
        let end = start + 3_600_000
        let rows = PanelRowBuilder.rows([ch(1, number: 1)],
                                        group: ChannelPanelGroups.allChannels,
                                        nowNext: { _ in nowNext(start, end, next: "Later") },
                                        nowMs: start + 1_800_000, timeZone: utc)
        #expect(rows[0].nowTitle == "Now Show")
        #expect(rows[0].nextTitle == "Later")
        #expect(rows[0].progress == 0.5)
        #expect(rows[0].nowRange == "02:46 – 03:46")
    }

    @Test func rowWithoutProgrammeHasNilFields() {
        let rows = PanelRowBuilder.rows([ch(1, number: 1)],
                                        group: ChannelPanelGroups.allChannels,
                                        nowNext: { _ in nil }, nowMs: 0, timeZone: utc)
        #expect(rows[0].nowTitle == nil)
        #expect(rows[0].nowRange == nil)
        #expect(rows[0].progress == nil)
    }
}
