import Testing
@testable import Telly

/// The channel-list group derivation: leads with Favorites then All channels,
/// then playlist groups; the Favorites pseudo-group returns favourites in
/// managed order.
struct ChannelListGroupsTests {
    private func ch(_ id: Int, group: String?, favorite: Bool = false, order: Int = 0) -> ChannelEntity {
        ChannelEntity(id: id, playlistId: 1, number: id, sortIndex: id,
                      source: ChannelSource(name: "Ch\(id)", groupTitle: group,
                                            streamUrl: "http://x/\(id)"),
                      flags: ChannelFlags(favorite: favorite, favoriteOrder: order))
    }

    @Test func leadsWithFavoritesThenAllChannels() {
        let names = ChannelListGroups.groupNames([ch(1, group: "Live"), ch(2, group: "VOD")])
        #expect(names == ["Favorites", "All channels", "Live", "VOD"])
    }

    @Test func favoritesGroupReturnsFavoritesInManagedOrder() {
        let list = [ch(1, group: "Live", favorite: true, order: 1),
                    ch(2, group: "VOD"),
                    ch(3, group: "Live", favorite: true, order: 0)]
        #expect(ChannelListGroups.channels(list, in: "Favorites").map(\.id) == [3, 1])
    }

    @Test func realGroupFiltersLikeThePanel() {
        let list = [ch(1, group: "Live"), ch(2, group: "VOD"), ch(3, group: "Live")]
        #expect(ChannelListGroups.channels(list, in: "Live").map(\.id) == [1, 3])
    }
}
