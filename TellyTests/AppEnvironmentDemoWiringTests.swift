import Testing
@testable import Telly

/// The composition-root wiring for the built-in demo: one install lands the
/// playlist, its channels, and a guide that answers now/next — all through the
/// same stores and refresh path a real provider uses, with no network.
@MainActor
struct AppEnvironmentDemoWiringTests {
    @Test func installDemoPopulatesPlaylistChannelsAndGuide() async throws {
        let db = try AppDatabase.makeInMemory()
        let env = AppEnvironment(database: db, settings: SettingsStore(backing: InMemoryKeyValueStore()),
                                 syncedConfig: InMemorySyncedConfigStore())
        #expect(env.playlists.isEmpty)
        await env.installDemoPlaylist()
        #expect(env.playlists.map(\.url) == [DemoContent.playlistUrl])
        #expect(env.playlists.first?.name == DemoContent.playlistName)
        let names = try env.channelStore.visibleChannels().map(\.source.name)
        #expect(names == DemoContent.liveChannels.map(\.title))  // VOD files go to the Movies shelf
        #expect(env.guideEpgStore.nowNext(forEpgId: "news-one-1.demo")?.now != nil)
        #expect(env.channelListModel.phase == .loaded)
    }

    @Test func installIsIdempotentAndMirrorsTheSyncedConfig() async throws {
        let synced = InMemorySyncedConfigStore()
        let env = AppEnvironment(database: try AppDatabase.makeInMemory(),
                                 settings: SettingsStore(backing: InMemoryKeyValueStore()), syncedConfig: synced)
        await env.installDemoPlaylist()
        await env.installDemoPlaylist()
        #expect(env.playlists.count == 1)
        #expect(synced.load()?.playlists.map(\.url) == [DemoContent.playlistUrl])
    }
}
