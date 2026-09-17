import Testing
import GRDB
@testable import Telly

/// The guide/group read queries: number order, hidden filtering, group counts.
struct ChannelStoreTests {
    private func seeded() throws -> (AppDatabase, ChannelStore) {
        let db = try AppDatabase.makeInMemory()
        let playlists = PlaylistStore(db: db)
        let list = M3uPlaylist(channels: [m("A", "News"), m("B", "News"), m("C", "Sport")])
        _ = try playlists.add(sourceUrl: "u", playlist: list, name: nil, nowMs: 0)
        try db.queue.write { try $0.execute(sql: "UPDATE channels SET hidden = 1 WHERE name = 'B'") }
        return (db, ChannelStore(db: db))
    }

    private func m(_ name: String, _ group: String) -> M3uChannel {
        M3uChannel(title: name, streamURL: "http://x/\(name)", tvgID: name, tvgName: nil,
                   tvgLogo: nil, groupTitle: group, catchup: nil, catchupSource: nil, catchupDays: nil)
    }

    @Test func channelsForPlaylistAreNumberOrderedIncludingHidden() throws {
        let (_, store) = try seeded()
        #expect(try store.channels(playlistId: 1).map(\.source.name) == ["A", "B", "C"])
    }

    @Test func groupQueryHidesHiddenChannels() throws {
        let (_, store) = try seeded()
        #expect(try store.channels(playlistId: 1, groupTitle: "News").map(\.source.name) == ["A"])
    }

    @Test func groupCountsSkipHiddenAndOrderByAppearance() throws {
        let (_, store) = try seeded()
        let groups = try store.groups(playlistId: 1)
        #expect(groups == [ChannelGroupCount(groupTitle: "News", channelCount: 1),
                           ChannelGroupCount(groupTitle: "Sport", channelCount: 1)])
    }

    @Test func visibleAndAllDifferOnHidden() throws {
        let (_, store) = try seeded()
        #expect(try store.visibleChannels().map(\.source.name) == ["A", "C"])
        #expect(try store.allChannels().map(\.source.name) == ["A", "B", "C"])
        #expect(try store.totalCount() == 3)
    }

    @Test func updatePersistsFavoriteHiddenOrder() throws {
        let (_, store) = try seeded()
        var channel = try #require(try store.allChannels().first { $0.source.name == "A" })
        channel.flags.favorite = true
        channel.flags.favoriteOrder = 5
        try store.update(channel)
        let reloaded = try #require(try store.allChannels().first { $0.source.name == "A" })
        #expect(reloaded.flags.favorite)
        #expect(reloaded.flags.favoriteOrder == 5)
    }

    @Test func hideRemovesFromVisibleKeepsInAll() throws {
        let (_, store) = try seeded()
        var channel = try #require(try store.allChannels().first { $0.source.name == "C" })
        channel.flags.hidden = true
        try store.update(channel)
        #expect(try store.visibleChannels().map(\.source.name) == ["A"])
        #expect(try store.allChannels().map(\.source.name) == ["A", "B", "C"])
    }

    @Test func batchUpdatePersistsAllRows() throws {
        let (_, store) = try seeded()
        let updated = try store.allChannels().enumerated().map { index, channel -> ChannelEntity in
            var copy = channel
            copy.flags.favoriteOrder = index + 10
            return copy
        }
        try store.update(updated)
        #expect(try store.allChannels().map(\.flags.favoriteOrder) == [10, 11, 12])
    }
}
