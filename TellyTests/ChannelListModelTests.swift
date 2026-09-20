import Testing
import GRDB
@testable import Telly

/// The channel-list model: loading, group derivation/filtering, and the
/// favourite/hide actions persisting through the store.
@MainActor
struct ChannelListModelTests {
    private func seededModel() throws -> ChannelListModel {
        let db = try AppDatabase.makeInMemory()
        let playlists = PlaylistStore(db: db)
        let list = M3uPlaylist(channels: [m("A", "Live"), m("B", "Live"), m("C", "Sport")])
        _ = try playlists.add(sourceUrl: "u", playlist: list, name: nil, nowMs: 0)
        let model = ChannelListModel(store: ChannelStore(db: db))
        model.load()
        return model
    }

    private func m(_ name: String, _ group: String) -> M3uChannel {
        M3uChannel(title: name, streamURL: "http://x/\(name)", tvgID: name, tvgName: nil,
                   tvgLogo: nil, groupTitle: group, catchup: nil, catchupSource: nil, catchupDays: nil)
    }

    @Test func loadsVisibleChannels() throws {
        #expect(try seededModel().channels.count == 3)
    }

    @Test func groupsLeadWithFavoritesThenAll() throws {
        #expect(try seededModel().groups == ["Favorites", "All channels", "Live", "Sport"])
    }

    @Test func selectGroupFiltersRows() throws {
        let model = try seededModel()
        model.select("Live")
        #expect(model.rows.map(\.source.name) == ["A", "B"])
    }

    @Test func channelSortReordersRowsAndDefaultPreservesPlaylistOrder() throws {
        let db = try AppDatabase.makeInMemory()
        let playlists = PlaylistStore(db: db)
        let list = M3uPlaylist(channels: [m("Zeta", "Live"), m("Alpha", "Live"), m("Mid", "Live")])
        _ = try playlists.add(sourceUrl: "u", playlist: list, name: nil, nowMs: 0)
        let model = ChannelListModel(store: ChannelStore(db: db))
        model.load()
        model.channelSort = { .default }
        #expect(model.rows.map(\.source.name) == ["Zeta", "Alpha", "Mid"])
        model.channelSort = { .nameAZ }
        #expect(model.rows.map(\.source.name) == ["Alpha", "Mid", "Zeta"])
    }

    @Test func favoritesGroupEmptyUntilToggled() throws {
        let model = try seededModel()
        model.select("Favorites")
        #expect(model.rows.isEmpty)
    }

    @Test func toggleFavoriteAddsPersistsShowsInFavorites() throws {
        let model = try seededModel()
        model.toggleFavorite(model.channels[0])
        model.select("Favorites")
        #expect(model.rows.map(\.source.name) == ["A"])
        // A fresh model over the same store sees the persisted favourite.
        let reloaded = ChannelListModel(store: model.store)
        reloaded.load()
        #expect(reloaded.channels.first { $0.source.name == "A" }?.flags.favorite == true)
    }

    @Test func toggleFavoriteRemoves() throws {
        let model = try seededModel()
        model.toggleFavorite(model.channels[0])
        let favorite = try #require(model.channels.first { $0.source.name == "A" })
        model.toggleFavorite(favorite)
        model.select("Favorites")
        #expect(model.rows.isEmpty)
    }

    @Test func hideRemovesFromRows() throws {
        let model = try seededModel()
        model.hide(model.channels[0])
        #expect(model.rows.map(\.source.name) == ["B", "C"])
    }

    @Test func visibilityOffDropsPseudoGroup() throws {
        let model = try seededModel()
        model.visibility.favorites = false
        #expect(!model.groups.contains("Favorites"))
        #expect(model.groups.contains("All channels"))
    }

    @Test func queryFiltersRowsGlobally() throws {
        let model = try seededModel()
        model.query = "A"
        #expect(model.rows.map(\.source.name) == ["A"])
    }

    @Test func queryOverridesSelectedGroup() throws {
        let model = try seededModel()
        model.select("Live")           // A, B
        model.query = "C"              // C is in Sport — global search finds it anyway
        #expect(model.rows.map(\.source.name) == ["C"])
    }

    @Test func emptyQueryRestoresGroupRows() throws {
        let model = try seededModel()
        model.select("Live")
        model.query = "C"
        model.query = "  "             // whitespace-only restores the group filter
        #expect(model.rows.map(\.source.name) == ["A", "B"])
    }

    @Test func queryWithNoMatchEmptiesRows() throws {
        let model = try seededModel()
        model.query = "zzz"
        #expect(model.rows.isEmpty)
    }

    @Test func customGroupListedAfterPlaylistGroups() throws {
        let model = try seededModel()
        let groups = CustomGroupStore(db: model.store.db)
        let id = try groups.create(name: "Kids")
        try groups.addMembers(id: id, keys: ["A", "C"])
        model.load()  // reloads custom groups alongside channels
        #expect(model.groups == ["Favorites", "All channels", "Live", "Sport", "Kids"])
    }

    @Test func selectingCustomGroupShowsItsMembers() throws {
        let model = try seededModel()
        let groups = CustomGroupStore(db: model.store.db)
        let id = try groups.create(name: "Kids")
        try groups.addMembers(id: id, keys: ["A", "C"])  // keyOf == tvg-id here
        model.load()
        model.select("Kids")
        #expect(model.rows.map(\.source.name) == ["A", "C"])
    }
}
