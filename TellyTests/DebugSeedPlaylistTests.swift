#if DEBUG
import Testing
@testable import Telly

/// The DEBUG real-provider seed's pure env→config mapping and the offline import
/// path. Every URL here is a FAKE `example.com` placeholder — never a real
/// provider — so the test proves the seam without any real network or token.
@MainActor
struct DebugSeedPlaylistTests {
    @Test func mapsPlaylistAndEpgFromEnvironment() {
        let seed = DebugSeedPlaylist.from(environment: [
            DebugSeedPlaylist.playlistKey: "http://example.com/p.m3u",
            DebugSeedPlaylist.epgKey: "http://example.com/epg.xml",
        ])
        #expect(seed == DebugSeedPlaylist(playlistUrl: "http://example.com/p.m3u",
                                          epgUrl: "http://example.com/epg.xml"))
    }

    @Test func nilWhenPlaylistMissingOrInvalid() {
        #expect(DebugSeedPlaylist.from(environment: [:]) == nil)
        #expect(DebugSeedPlaylist.from(environment: [DebugSeedPlaylist.playlistKey: "not a url"]) == nil)
    }

    @Test func dropsInvalidEpgButKeepsPlaylist() {
        let seed = DebugSeedPlaylist.from(environment: [
            DebugSeedPlaylist.playlistKey: "http://example.com/p.m3u",
            DebugSeedPlaylist.epgKey: "nonsense",
        ])
        #expect(seed?.playlistUrl == "http://example.com/p.m3u")
        #expect(seed?.epgUrl == nil)
    }

    @Test func seedImportsChannelsThroughRealStore() async throws {
        let env = AppEnvironment(database: try AppDatabase.makeInMemory())
        let m3u = "#EXTM3U\n#EXTINF:-1,Example One\nhttp://example.com/one.ts\n"
        await env.seedRealPlaylistIfRequested(
            environment: [DebugSeedPlaylist.playlistKey: "http://example.com/p.m3u"],
            fetch: { _ in m3u })
        #expect(env.playlists.count == 1)
        #expect(try env.channelStore.visibleChannels().map(\.source.name) == ["Example One"])
    }

    @Test func noOpWhenEnvironmentUnset() async throws {
        let env = AppEnvironment(database: try AppDatabase.makeInMemory())
        await env.seedRealPlaylistIfRequested(environment: [:], fetch: { _ in "#EXTM3U\n" })
        #expect(env.playlists.isEmpty)
    }
}
#endif
