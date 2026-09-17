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
}
