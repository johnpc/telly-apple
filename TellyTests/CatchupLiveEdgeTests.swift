import Testing
@testable import Telly

/// Unit coverage for `CatchupLiveEdge.requestFor` — builds a request from the
/// airing programme, and the nil paths (no airing / no catch-up attributes /
/// no epgId). Pure: `nowNext`/`clock` are injected, no DB or VLCKit.
struct CatchupLiveEdgeTests {
    private let now = 10_000_000_000

    private func channel(catchup: Bool = true, tvgId: String? = "news.tv") -> ChannelEntity {
        ChannelEntity(
            playlistId: 1, number: 1, sortIndex: 0,
            source: ChannelSource(name: "News", groupTitle: nil, logoUrl: nil,
                                  streamUrl: "http://127.0.0.1/live/news.ts", tvgId: tvgId),
            catchup: catchup
                ? ChannelCatchup(catchupType: "default",
                                 catchupSource: "http://127.0.0.1/a?utc=${start}", catchupDays: 7)
                : ChannelCatchup())
    }

    private func airing() -> ProgramEntity {
        ProgramEntity(channelTvgId: "news.tv", startMs: now - 600_000, endMs: now + 600_000,
                      details: ProgramDetails(title: "The Airing Show"))
    }

    private func liveEdge(_ lookup: @escaping (String, Int) -> NowNext?) -> CatchupLiveEdge {
        CatchupLiveEdge(nowNext: lookup, clock: { self.now })
    }

    @Test func buildsRequestFromAiringProgramme() {
        let edge = liveEdge { _, _ in NowNext(now: self.airing()) }
        let req = edge.requestFor(channel())
        #expect(req?.title == "The Airing Show")
        #expect(req?.startMs == now - 600_000)
        #expect(req?.endMs == now + 600_000)
        #expect(req?.url != nil)
    }

    @Test func nilWhenNoAiringProgramme() {
        let edge = liveEdge { _, _ in NowNext(now: nil, next: nil) }
        #expect(edge.requestFor(channel()) == nil)
    }

    @Test func nilWhenLookupMisses() {
        let edge = liveEdge { _, _ in nil }
        #expect(edge.requestFor(channel()) == nil)
    }

    @Test func nilWhenChannelHasNoCatchupAttributes() {
        let edge = liveEdge { _, _ in NowNext(now: self.airing()) }
        #expect(edge.requestFor(channel(catchup: false)) == nil)
    }

    @Test func nilWhenChannelHasNoEpgId() {
        let edge = liveEdge { _, _ in NowNext(now: self.airing()) }
        #expect(edge.requestFor(channel(tvgId: nil)) == nil)
    }
}
