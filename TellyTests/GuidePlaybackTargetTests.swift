import Testing
@testable import Telly

/// The guide's two-case playback target: identity and URL derive from whichever
/// case is active, and the catch-up badge is built from the request alone — no
/// parallel optionals to keep in step.
struct GuidePlaybackTargetTests {
    private let channel = ChannelEntity(
        id: 7, playlistId: 1, number: 7, sortIndex: 7,
        source: ChannelSource(name: "News", groupTitle: "Live", streamUrl: "http://127.0.0.1/live.ts"))

    @Test func liveTargetCarriesChannelIdAndStreamUrl() {
        let target = GuidePlaybackTarget.live(channelId: 7, url: "http://127.0.0.1/live.ts")
        #expect(target.id == 7)
        #expect(target.url == "http://127.0.0.1/live.ts")
    }

    @Test func catchupTargetDerivesIdentityFromRequest() {
        let request = CatchupRequest(channel: channel, url: "http://127.0.0.1/archive.ts",
                                     title: "Aired", startMs: 1_000, endMs: 4_000)
        let target = GuidePlaybackTarget.catchup(request)
        #expect(target.id == 7)
        #expect(target.url == "http://127.0.0.1/archive.ts")
    }

    @Test func badgeIsBuiltFromTheRequestWindow() {
        let request = CatchupRequest(channel: channel, url: "u", title: "Aired", startMs: 1_000, endMs: 4_000)
        #expect(CatchupBadge(request) == CatchupBadge(title: "Aired", startMs: 1_000, endMs: 4_000))
    }
}
