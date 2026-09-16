import Testing
@testable import Telly

/// Unit coverage for channel identity + import (flags carried across refresh).
struct ChannelImporterTests {

    private func parsed(_ title: String, _ url: String, tvgID: String? = nil,
                        group: String? = nil) -> M3uChannel {
        M3uChannel(title: title, streamURL: url, tvgID: tvgID, tvgName: nil, tvgLogo: nil,
                   groupTitle: group, catchup: nil, catchupSource: nil, catchupDays: nil)
    }

    @Test func identityPrefersTvgIdElseUrlAndName() {
        #expect(ChannelImporter.identityOf(tvgId: "n1", streamUrl: "u", name: "N") == "n1")
        #expect(ChannelImporter.identityOf(tvgId: "  ", streamUrl: "u", name: "N") == "u|N")
        #expect(ChannelImporter.identityOf(tvgId: nil, streamUrl: "u", name: "N") == "u|N")
    }

    @Test func importNumbersChannelsFromPlaylistOrder() {
        let rows = ChannelImporter.importChannels(
            playlistId: 7,
            parsed: [parsed("A", "a", group: "News"), parsed("B", "b")],
            previous: [])
        #expect(rows.map(\.number) == [1, 2])
        #expect(rows.map(\.sortIndex) == [0, 1])
        #expect(rows[0].playlistId == 7)
        #expect(rows[0].source.groupTitle == "News")
        #expect(rows[1].flags == ChannelFlags())
    }

    @Test func importCarriesUserStateByIdentity() {
        var previous = ChannelEntity(playlistId: 1, number: 5, sortIndex: 4,
                                     source: ChannelSource(name: "Old", streamUrl: "a", tvgId: "n1"))
        previous.flags.favorite = true
        previous.overrides.customName = "My Name"
        let rows = ChannelImporter.importChannels(
            playlistId: 1,
            parsed: [parsed("New", "a", tvgID: "n1"), parsed("Fresh", "z")],
            previous: [previous])
        #expect(rows[0].flags.favorite)
        #expect(rows[0].overrides.customName == "My Name")
        #expect(rows[0].number == 1)              // renumbered from new order
        #expect(rows[1].flags == ChannelFlags())  // no prior state
        #expect(ChannelImporter.keyOf(previous) == "n1")
    }
}
