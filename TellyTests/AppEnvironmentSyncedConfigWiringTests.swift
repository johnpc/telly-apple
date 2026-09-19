import Testing
import GRDB
@testable import Telly

/// Composition-root wiring for cross-reinstall config: `mirrorSyncedConfig` must
/// derive the config from the environment's real stores and write it through to
/// the injected synced store (clearing when the last playlist goes), and
/// `recreate` must re-create the empty playlist + EPG-source records a restore
/// brings back. Fake `example.com` URLs only — never a real provider token.
@MainActor
struct AppEnvironmentSyncedConfigWiringTests {
    private func makeEnv() throws -> (AppEnvironment, InMemorySyncedConfigStore) {
        let store = InMemorySyncedConfigStore()
        let env = AppEnvironment(database: try AppDatabase.makeInMemory(), syncedConfig: store)
        return (env, store)
    }

    private static let url = "https://example.com/p.m3u"

    @Test func mirrorWritesCurrentConfigThrough() throws {
        let (env, store) = try makeEnv()
        _ = try env.playlistStore.add(
            sourceUrl: Self.url, playlist: M3uPlaylist(epgURL: "https://example.com/e.xml", channels: []),
            name: "Home", nowMs: 0)
        try env.epgSourceStore.add(playlistUrl: Self.url, url: "https://example.com/x.xml", nowMs: 0)

        #expect(env.currentSyncedConfig().playlists.map(\.url) == [Self.url])
        env.mirrorSyncedConfig()
        let saved = try #require(store.load())
        #expect(saved.playlists == [BackupPlaylist(name: "Home", url: Self.url, epgUrl: "https://example.com/e.xml")])
        #expect(saved.epgSources == [BackupEpgSource(playlistUrl: Self.url, url: "https://example.com/x.xml")])
    }

    @Test func mirrorClearsWhenNoPlaylistsRemain() throws {
        let (env, store) = try makeEnv()
        store.save(SyncedConfig(playlists: [BackupPlaylist(name: "old", url: Self.url, epgUrl: nil)], epgSources: []))
        env.mirrorSyncedConfig()  // local DB is empty → clear, never persist empty
        #expect(store.load() == nil)
        #expect(store.clears == 1)
    }

    @Test func recreateReinstatesEmptyRecords() throws {
        let (env, _) = try makeEnv()
        let config = SyncedConfig(
            playlists: [BackupPlaylist(name: "Home", url: Self.url, epgUrl: "https://example.com/e.xml")],
            epgSources: [BackupEpgSource(playlistUrl: Self.url, url: "https://example.com/x.xml")])
        env.recreate(from: config)
        #expect(try env.playlistStore.all().map(\.url) == [Self.url])
        #expect(try env.playlistStore.all().first?.epgUrl == "https://example.com/e.xml")
        #expect(try env.epgSourceStore.forPlaylist(Self.url).map(\.url) == ["https://example.com/x.xml"])
        // Re-created empty: a subsequent re-fetch lands channels.
        #expect(try env.channelStore.visibleChannels().isEmpty)
    }

    @Test func restorerIsWiredToRealStores() throws {
        let (env, store) = try makeEnv()
        store.save(SyncedConfig(playlists: [BackupPlaylist(name: "Home", url: Self.url, epgUrl: nil)], epgSources: []))
        // Building the restorer must not throw or mutate; the decision seams read
        // the injected synced store and the env's (empty) local DB.
        _ = env.makeSyncedConfigRestorer()
        #expect(store.load() != nil)
    }
}
