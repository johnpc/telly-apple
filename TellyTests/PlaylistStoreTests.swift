import Testing
import GRDB
@testable import Telly

/// Playlist persistence + the re-add channel refresh with flag carry-over.
struct PlaylistStoreTests {
    private func fixture() throws -> (AppDatabase, PlaylistStore, ChannelStore) {
        let db = try AppDatabase.makeInMemory()
        return (db, PlaylistStore(db: db), ChannelStore(db: db))
    }

    private func channel(_ name: String, tvg: String? = nil, group: String? = nil) -> M3uChannel {
        M3uChannel(title: name, streamURL: "http://x/\(name)", tvgID: tvg, tvgName: nil,
                   tvgLogo: nil, groupTitle: group, catchup: nil, catchupSource: nil, catchupDays: nil)
    }

    @Test func addStoresPlaylistAndNumbersChannels() throws {
        let (_, playlists, channels) = try fixture()
        let pl = M3uPlaylist(epgURL: "http://epg", channels: [channel("A"), channel("B")])
        let id = try playlists.add(sourceUrl: "http://list", playlist: pl, name: "Mine", nowMs: 100)
        let stored = try playlists.all()
        #expect(stored.count == 1)
        #expect(stored[0].name == "Mine")
        #expect(stored[0].epgUrl == "http://epg")
        #expect(stored[0].lastUpdatedMs == 100)
        let rows = try channels.channels(playlistId: Int(id))
        #expect(rows.map(\.source.name) == ["A", "B"])
        #expect(rows.map(\.number) == [1, 2])
        #expect(rows.map(\.sortIndex) == [0, 1])
    }

    @Test func reAddReplacesChannelsAndCarriesUserFlags() throws {
        let (db, playlists, channels) = try fixture()
        let first = M3uPlaylist(channels: [channel("A", tvg: "a"), channel("B", tvg: "b")])
        _ = try playlists.add(sourceUrl: "u", playlist: first, name: nil, nowMs: 1)
        try db.queue.write {
            try $0.execute(sql: "UPDATE channels SET favorite = 1, hidden = 1 WHERE tvgId = 'a'")
        }
        // Re-add with A reordered + regrouped: its flags carry over by tvg-id.
        let second = M3uPlaylist(channels: [channel("B", tvg: "b"), channel("A", tvg: "a", group: "News")])
        let id = try playlists.add(sourceUrl: "u", playlist: second, name: nil, nowMs: 2)
        let rows = try channels.channels(playlistId: Int(id))
        #expect(rows.count == 2)
        let a = try #require(rows.first { $0.source.tvgId == "a" })
        #expect(a.flags.favorite)
        #expect(a.flags.hidden)
        #expect(a.number == 2)
        #expect(a.source.groupTitle == "News")
        #expect(try playlists.all().count == 1)
    }

    @Test func defaultNameIsLastPathSegment() throws {
        let (_, playlists, _) = try fixture()
        _ = try playlists.add(sourceUrl: "http://host/path/mylist.m3u?token=x",
                             playlist: M3uPlaylist(channels: []), name: nil, nowMs: 0)
        #expect(try playlists.all()[0].name == "mylist.m3u")
    }

    @Test func renameUpdatesTheName() throws {
        let (_, playlists, _) = try fixture()
        _ = try playlists.add(sourceUrl: "u", playlist: M3uPlaylist(channels: []), name: "Old", nowMs: 0)
        try playlists.rename(sourceUrl: "u", name: "New")
        #expect(try playlists.all()[0].name == "New")
    }

    @Test func changeUrlMovesInPlaceAndRejectsCollisions() throws {
        let (_, playlists, _) = try fixture()
        _ = try playlists.add(sourceUrl: "old", playlist: M3uPlaylist(channels: []), name: "P", nowMs: 0)
        #expect(try playlists.changeUrl(oldUrl: "old", newUrl: "new"))
        #expect(try playlists.all()[0].url == "new")
        #expect(try !playlists.changeUrl(oldUrl: "missing", newUrl: "x"))
        _ = try playlists.add(sourceUrl: "other", playlist: M3uPlaylist(channels: []), name: "Q", nowMs: 0)
        #expect(try !playlists.changeUrl(oldUrl: "other", newUrl: "new"))
    }

    @Test func deleteRemovesPlaylistAndCascadesChannels() throws {
        let (_, playlists, channels) = try fixture()
        _ = try playlists.add(sourceUrl: "u", playlist: M3uPlaylist(channels: [channel("A")]),
                             name: nil, nowMs: 0)
        try playlists.delete(sourceUrl: "u")
        #expect(try playlists.all().isEmpty)
        #expect(try channels.totalCount() == 0)
    }
}
