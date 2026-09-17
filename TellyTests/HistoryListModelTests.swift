import Testing
import GRDB
@testable import Telly

/// The recently-watched screen's model: `load` joins raw watch-history events
/// (newest first) to the visible channels via ``WatchHistoryRows``, dropping
/// keys with no visible channel; `clear` empties both the store and the
/// published rows.
@MainActor
struct HistoryListModelTests {
    private func seed() throws -> (WatchHistoryStore, ChannelStore) {
        let db = try AppDatabase.makeInMemory()
        let playlists = PlaylistStore(db: db)
        let list = M3uPlaylist(channels: [m("A", "aaa"), m("B", "bbb"), m("C", "ccc")])
        _ = try playlists.add(sourceUrl: "u", playlist: list, name: nil, nowMs: 0)
        return (WatchHistoryStore(db: db), ChannelStore(db: db))
    }

    private func m(_ name: String, _ tvg: String) -> M3uChannel {
        M3uChannel(title: name, streamURL: "http://x/\(name)", tvgID: tvg, tvgName: nil,
                   tvgLogo: nil, groupTitle: "Live", catchup: nil, catchupSource: nil, catchupDays: nil)
    }

    @Test func loadJoinsNewestFirstToVisibleChannels() throws {
        let (store, channels) = try seed()
        try store.record(channelKey: "aaa", atMs: 100)
        try store.record(channelKey: "ccc", atMs: 300)
        try store.record(channelKey: "bbb", atMs: 200)
        let model = HistoryListModel(store: store, channelStore: channels)
        model.load()
        #expect(model.rows.map(\.source.name) == ["C", "B", "A"])
    }

    @Test func loadDropsUnresolvedKeys() throws {
        let (store, channels) = try seed()
        try store.record(channelKey: "aaa", atMs: 100)
        try store.record(channelKey: "gone", atMs: 200)  // no visible channel
        let model = HistoryListModel(store: store, channelStore: channels)
        model.load()
        #expect(model.rows.map(\.source.name) == ["A"])
    }

    @Test func clearEmptiesStoreAndRows() throws {
        let (store, channels) = try seed()
        try store.record(channelKey: "aaa", atMs: 100)
        let model = HistoryListModel(store: store, channelStore: channels)
        model.load()
        #expect(!model.rows.isEmpty)
        model.clear()
        #expect(model.rows.isEmpty)
        #expect(try store.recent().isEmpty)
    }
}
