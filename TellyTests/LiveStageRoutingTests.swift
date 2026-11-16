import Testing
@testable import Telly

/// The shared-live-stage routing every secondary entry point (History, My List,
/// Search, the pushed Guide) now funnels through: each maps the tapped channel
/// to a ``LiveStageTarget`` and hands its URL to the SAME app-lifetime
/// ``LiveEngineStore`` — so entering (or round-tripping) live from any of them
/// reuses one engine with no reconnect, exactly like the home path. VOD /
/// catch-up stays off this path (its own terminal per-screen engine).
@MainActor
struct LiveStageRoutingTests {
    private func channel(id: Int, url: String) -> ChannelEntity {
        ChannelEntity(id: id, playlistId: 1, number: id, sortIndex: 0,
                      source: ChannelSource(name: "C\(id)", streamUrl: url))
    }

    @Test func targetMapsChannelIdAndStreamUrl() {
        let target = LiveStageTarget(channel: channel(id: 7, url: "http://a"))
        #expect(target.id == 7)
        #expect(target.url == "http://a")
    }

    /// History, My List and Search all acquire the SAME engine instance from the
    /// store (never a fresh mint) until a real exit from live.
    @Test func secondaryEntryPointsReuseOneSharedEngine() {
        let store = LiveEngineStore(makeEngine: { FakePlayerEngine() })
        let engine = store.acquire() as AnyObject
        store.noteTuned(LiveStageTarget(channel: channel(id: 1, url: "http://a")).url)
        #expect(store.acquire() as AnyObject === engine)
        store.noteTuned(LiveStageTarget(channel: channel(id: 2, url: "http://b")).url)
        #expect(store.acquire() as AnyObject === engine)
        #expect(store.currentUrl == "http://b")
        store.exit()
        #expect(store.acquire() as AnyObject !== engine)
    }
}
