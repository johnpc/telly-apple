import Testing
import GRDB
@testable import Telly

/// The backup manager composed over an in-memory database + fake key-value
/// store: export gathers settings/playlists/sources; import restores settings
/// and re-creates zero-channel playlists with their custom EPG sources, never
/// crashing on malformed JSON.
@MainActor
struct SettingsBackupManagerTests {
    private func manager(db: AppDatabase, kv: KeyValueStore) -> SettingsBackupManager {
        SettingsBackupManager(playlistStore: PlaylistStore(db: db),
                              epgSourceStore: EpgSourceStore(db: db), settings: kv, now: { 1 })
    }

    private func chan(_ name: String) -> M3uChannel {
        M3uChannel(title: name, streamURL: "http://127.0.0.1:8000/\(name)", tvgID: name,
                   tvgName: nil, tvgLogo: nil, groupTitle: nil, catchup: nil,
                   catchupSource: nil, catchupDays: nil)
    }

    @Test func exportListsSettingsPlaylistsAndSources() throws {
        let db = try AppDatabase.makeInMemory()
        let kv = InMemoryKeyValueStore()
        kv.writeInt(12, SettingsKey.epgRefreshHours.rawValue)
        let a = "http://127.0.0.1:8000/a.m3u"
        try PlaylistStore(db: db).add(sourceUrl: a,
            playlist: M3uPlaylist(epgURL: "http://127.0.0.1:8000/epg.xml", channels: [chan("A1")]),
            name: "A", nowMs: 0)
        try EpgSourceStore(db: db).add(playlistUrl: a, url: "http://127.0.0.1:8000/x.xml", nowMs: 0)
        let payload = try #require(BackupCodec.decode(manager(db: db, kv: kv).exportJson()))
        #expect(payload.settings[SettingsKey.epgRefreshHours.rawValue] == "12")
        #expect(payload.playlists.map(\.url) == [a])
        #expect(payload.epgSources.map(\.url) == ["http://127.0.0.1:8000/x.xml"])
    }

    @Test func importRestoresSettingsAndZeroChannelPlaylists() throws {
        let srcDb = try AppDatabase.makeInMemory()
        let srcKv = InMemoryKeyValueStore()
        srcKv.writeBool(false, SettingsKey.use24hClock.rawValue)
        let a = "http://127.0.0.1:8000/a.m3u"
        try PlaylistStore(db: srcDb).add(sourceUrl: a,
            playlist: M3uPlaylist(epgURL: nil, channels: [chan("A1"), chan("A2")]), name: "A", nowMs: 0)
        try EpgSourceStore(db: srcDb).add(playlistUrl: a, url: "http://127.0.0.1:8000/x.xml", nowMs: 0)
        let json = try manager(db: srcDb, kv: srcKv).exportJson()

        let db = try AppDatabase.makeInMemory()
        let kv = InMemoryKeyValueStore()
        #expect(try manager(db: db, kv: kv).importJson(json))
        #expect(kv.readBool(SettingsKey.use24hClock.rawValue) == false)
        #expect(try PlaylistStore(db: db).all().map(\.url) == [a])
        #expect(try ChannelStore(db: db).visibleChannels().isEmpty)  // channels re-fetch pending
        #expect(try EpgSourceStore(db: db).forPlaylist(a).map(\.url) == ["http://127.0.0.1:8000/x.xml"])
    }

    @Test func importReturnsFalseOnMalformedJson() throws {
        let db = try AppDatabase.makeInMemory()
        #expect(try manager(db: db, kv: InMemoryKeyValueStore()).importJson("garbage") == false)
    }
}
