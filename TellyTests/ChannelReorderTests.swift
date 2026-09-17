import Testing
@testable import Telly

/// The pure favourites/reorder math: stable favourite ordering, editor rows,
/// toggling, and the two move operations (favourite reindex + in-group swap).
struct ChannelReorderTests {
    private func ch(_ id: Int, favorite: Bool = false, order: Int = 0, sortIndex: Int? = nil) -> ChannelEntity {
        ChannelEntity(id: id, playlistId: 1, number: id, sortIndex: sortIndex ?? id,
                      source: ChannelSource(name: "Ch\(id)", streamUrl: "http://x/\(id)"),
                      flags: ChannelFlags(favorite: favorite, favoriteOrder: order))
    }

    @Test func favoritesSortedByOrderStableOnTies() {
        let list = [ch(1, favorite: true, order: 1), ch(2), ch(3, favorite: true, order: 0),
                    ch(4, favorite: true, order: 1)]
        // order 0 first (id 3), then the two order-1 favourites in original order (1, 4).
        #expect(ChannelReorder.favorites(list).map(\.id) == [3, 1, 4])
    }

    @Test func editorRowsFavoritesFirst() {
        let list = [ch(1), ch(2, favorite: true, order: 0), ch(3)]
        #expect(ChannelReorder.editorRows(list).map(\.id) == [2, 1, 3])
    }

    @Test func toggledAddAppendsMaxPlusOne() {
        let list = [ch(1, favorite: true, order: 3), ch(2)]
        let toggled = ChannelReorder.toggled(list, list[1])
        #expect(toggled.flags.favorite)
        #expect(toggled.flags.favoriteOrder == 4)
    }

    @Test func toggledAddFirstFavoriteGetsZero() {
        let list = [ch(1), ch(2)]
        #expect(ChannelReorder.toggled(list, list[0]).flags.favoriteOrder == 0)
    }

    @Test func toggledRemoveClearsFavoriteKeepsOrder() {
        let list = [ch(1, favorite: true, order: 7)]
        let toggled = ChannelReorder.toggled(list, list[0])
        #expect(!toggled.flags.favorite)
        #expect(toggled.flags.favoriteOrder == 7)
    }

    @Test func moveFavoriteSwapsReindexesReturnsChangedOnly() {
        let list = [ch(1, favorite: true, order: 0), ch(2, favorite: true, order: 1),
                    ch(3, favorite: true, order: 2)]
        let changed = ChannelReorder.moveFavorite(list, channelId: 3, delta: -1)
        // 3 moves ahead of 2: their orders swap; row 1 (order 0) is unchanged.
        #expect(Set(changed.map(\.id)) == [2, 3])
        #expect(changed.first { $0.id == 3 }?.flags.favoriteOrder == 1)
        #expect(changed.first { $0.id == 2 }?.flags.favoriteOrder == 2)
    }

    @Test func moveFavoriteOutOfBoundsEmpty() {
        let list = [ch(1, favorite: true, order: 0)]
        #expect(ChannelReorder.moveFavorite(list, channelId: 1, delta: -1).isEmpty)
        #expect(ChannelReorder.moveFavorite(list, channelId: 99, delta: 1).isEmpty)
    }

    @Test func moveInGroupSwapsSortIndex() {
        let ordered = [ch(1, sortIndex: 10), ch(2, sortIndex: 20)]
        let changed = ChannelReorder.moveInGroup(ordered, channelId: 1, delta: 1)
        #expect(changed.first { $0.id == 1 }?.sortIndex == 20)
        #expect(changed.first { $0.id == 2 }?.sortIndex == 10)
    }

    @Test func moveInGroupOutOfBoundsEmpty() {
        let ordered = [ch(1, sortIndex: 10), ch(2, sortIndex: 20)]
        #expect(ChannelReorder.moveInGroup(ordered, channelId: 2, delta: 1).isEmpty)
        #expect(ChannelReorder.moveInGroup(ordered, channelId: 5, delta: -1).isEmpty)
    }
}
