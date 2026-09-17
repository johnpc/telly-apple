import Testing
@testable import Telly

/// Unit coverage for `CatchupRequest.durationMs` and Equatable semantics.
struct CatchupRequestTests {

    private var channel: ChannelEntity {
        ChannelEntity(playlistId: 1, number: 1, sortIndex: 0,
                      source: ChannelSource(name: "N", streamUrl: "u"))
    }

    @Test func durationIsEndMinusStart() {
        let req = CatchupRequest(channel: channel, url: "http://a",
                                 title: "Show", startMs: 1_000, endMs: 4_000)
        #expect(req.durationMs == 3_000)
    }

    @Test func equatableComparesAllFields() {
        let a = CatchupRequest(channel: channel, url: "u", title: nil, startMs: 0, endMs: 1)
        let b = CatchupRequest(channel: channel, url: "u", title: nil, startMs: 0, endMs: 1)
        #expect(a == b)
        #expect(a != CatchupRequest(channel: channel, url: "u2", title: nil, startMs: 0, endMs: 1))
    }
}
