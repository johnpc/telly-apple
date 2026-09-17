import Testing
import GRDB
@testable import Telly

/// The composition-root wiring for playlist updates: `makePlaylistUpdater` must
/// build an updater over the environment's real `PlaylistStore`, so re-importing
/// through it lands channels in the same in-memory database the env exposes.
@MainActor
struct AppEnvironmentPlaylistWiringTests {
    @Test func makePlaylistUpdaterReimportsThroughEnvironmentStore() async throws {
        let db = try AppDatabase.makeInMemory()
        let env = AppEnvironment(database: db)
        let url = "http://127.0.0.1:8000/a/playlist.m3u"
        _ = try env.playlistStore.add(sourceUrl: url, playlist: M3uParser.parse("#EXTM3U\n"),
                                      name: nil, nowMs: 0)
        // Re-import through the factory-produced updater's store with a fake fetch,
        // proving the factory wires the environment's real PlaylistStore.
        let store = env.makePlaylistUpdater().store
        let updater = PlaylistUpdater(
            fetch: { _ in "#EXTM3U\n#EXTINF:-1 tvg-id=\"A\",A\nhttp://127.0.0.1:8000/A\n" },
            store: store, now: { 1 })
        #expect(await updater.update(url))
        #expect(try env.channelStore.visibleChannels().map(\.source.name) == ["A"])
    }
}
