import Testing
@testable import Telly

/// The pure panel group derivation: "All channels" first, distinct playlist
/// groups in first-appearance order (nils dropped), and the per-group filter.
struct ChannelPanelGroupsTests {
    private func ch(_ id: Int, group: String?) -> ChannelEntity {
        ChannelEntity(id: id, playlistId: 1, number: id, sortIndex: id,
                      source: ChannelSource(name: "Ch\(id)", groupTitle: group,
                                            streamUrl: "http://127.0.0.1/\(id).ts"))
    }

    @Test func leadsWithAllChannels() {
        #expect(ChannelPanelGroups.groupNames([ch(1, group: "Live")]).first == "All channels")
    }

    @Test func preservesFirstAppearanceOrderDropsNil() {
        let names = ChannelPanelGroups.groupNames([
            ch(1, group: "Live"), ch(2, group: nil),
            ch(3, group: "VOD"), ch(4, group: "Live")])
        #expect(names == ["All channels", "Live", "VOD"])
    }

    @Test func channelsInAllReturnsEverything() {
        let all = [ch(1, group: "Live"), ch(2, group: "VOD")]
        #expect(ChannelPanelGroups.channels(all, in: "All channels").map(\.id) == [1, 2])
    }

    @Test func channelsInGroupFilters() {
        let all = [ch(1, group: "Live"), ch(2, group: "VOD"), ch(3, group: "Live")]
        #expect(ChannelPanelGroups.channels(all, in: "Live").map(\.id) == [1, 3])
    }
}
