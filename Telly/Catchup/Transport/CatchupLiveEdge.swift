import Foundation

/// Resolves "rewind live into catch-up": the airing programme of the tuned
/// catch-up channel, built into a request whose stream starts at the programme
/// start — the caller then seeks to live edge minus the skip step. Ports the
/// Android `CatchupLiveEdge` (`CatchupLiveEdge.kt:18-29`); `nowNext`/`clock` are
/// injected so the resolution stays pure and unit-testable.
struct CatchupLiveEdge {
    /// The now/next lookup for a single tvg-id at a given instant.
    let nowNext: (_ tvgId: String, _ atMs: Int) -> NowNext?
    let clock: () -> Int

    func requestFor(_ channel: ChannelEntity) -> CatchupRequest? {
        guard let attributes = channel.catchupAttributes(),
              let tvgId = channel.epgId else { return nil }
        let now = clock()
        guard let airing = nowNext(tvgId, now)?.now,
              let url = CatchupUrlBuilder.build(streamUrl: channel.source.streamUrl,
                                                attributes: attributes, startMs: airing.startMs,
                                                endMs: airing.endMs, nowMs: now) else { return nil }
        return CatchupRequest(channel: channel, url: url, title: airing.details.title,
                              startMs: airing.startMs, endMs: airing.endMs)
    }
}
