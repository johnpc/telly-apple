import Testing
import GRDB
@testable import Telly

/// The Manage-Favorites / Reorder editor model: editor rows, mode-gated toggle,
/// and moves persisting reindexed order / swapped sort index.
@MainActor
struct ChannelEditModelTests {
    private func seed() throws -> ChannelStore {
        let db = try AppDatabase.makeInMemory()
        let playlists = PlaylistStore(db: db)
        let list = M3uPlaylist(channels: [m("A", "Live"), m("B", "Live"), m("C", "Live")])
        _ = try playlists.add(sourceUrl: "u", playlist: list, name: nil, nowMs: 0)
        return ChannelStore(db: db)
    }

    private func m(_ name: String, _ group: String) -> M3uChannel {
        M3uChannel(title: name, streamURL: "http://x/\(name)", tvgID: name, tvgName: nil,
                   tvgLogo: nil, groupTitle: group, catchup: nil, catchupSource: nil, catchupDays: nil)
    }

    @Test func editorRowsFavoritesFirst() throws {
        let store = try seed()
        let model = ChannelEditModel(store: store)
        model.load()
        model.toggle(model.channels[2])          // C becomes the only favourite
        #expect(model.rows.map(\.source.name) == ["C", "A", "B"])
    }

    @Test func toggleOnlyInFavoritesMode() throws {
        let store = try seed()
        let model = ChannelEditModel(store: store)
        #expect(model.togglesFavorites)
    }

    @Test func toggleInGroupModeInert() throws {
        let store = try seed()
        let model = ChannelEditModel(store: store, group: "Live")
        model.load()
        model.toggle(model.channels[0])
        #expect(model.channels.allSatisfy { !$0.flags.favorite })
    }

    @Test func moveFavoritePersistsReindex() throws {
        let store = try seed()
        let model = ChannelEditModel(store: store)
        model.load()
        model.toggle(model.channels[0])           // A order 0
        model.toggle(model.channels.first { $0.source.name == "B" }!)  // B order 1
        let b = try #require(model.channels.first { $0.source.name == "B" })
        model.move(b, delta: -1)                  // B ahead of A
        #expect(ChannelReorder.favorites(model.channels).map(\.source.name) == ["B", "A"])
    }

    @Test func moveInGroupSwapsSortIndexPersists() throws {
        let store = try seed()
        let model = ChannelEditModel(store: store, group: "Live")
        model.load()
        let first = model.rows[0]                 // A, sortIndex-first
        model.move(first, delta: 1)               // swap A with B → B, A, C
        #expect(model.rows.map(\.source.name) == ["B", "A", "C"])
    }

    @Test func reloadReflectsPersistedOrder() throws {
        let store = try seed()
        let model = ChannelEditModel(store: store)
        model.load()
        model.toggle(model.channels[1])
        let reloaded = ChannelEditModel(store: store)
        reloaded.load()
        #expect(reloaded.rows.first?.source.name == "B")
    }
}
