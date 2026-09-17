import Foundation

/// Resolves the EPG neighbours of an archived programme for the transport's
/// ⏮/⏭ buttons: previous = the newest programme ending at or before the
/// archive's start, next = the oldest one starting at or after its end. Only
/// fully-aired programmes inside the catchup-days horizon build an archive;
/// anything newer (the airing programme, an EPG edge) is `.live`. Ports the
/// Android `CatchupNeighbours` (`CatchupNeighbours.kt:31-71`); `programs`/`clock`
/// are injected so the hop logic stays pure and unit-testable.
struct CatchupNeighbours {
    /// EPG lookup: programmes for the tvg-ids within `[fromMs, toMs)`.
    let programs: (_ tvgIds: [String], _ fromMs: Int, _ toMs: Int) -> [ProgramEntity]
    let clock: () -> Int

    /// Neighbour lookup window; programmes are at most 90 min in practice.
    private static let scanMs = 6 * 3_600_000

    /// The playable previous programme's request, or nil (= stay put).
    func previous(_ request: CatchupRequest) -> CatchupRequest? {
        window(request, request.startMs - Self.scanMs, request.startMs)
            .filter { $0.endMs <= request.startMs }
            .max { $0.startMs < $1.startMs }
            .flatMap { archiveOf(channel: request.channel, programme: $0) }
    }

    /// The next programme's archive, or `.live` at the newest end.
    func next(_ request: CatchupRequest) -> CatchupJump {
        let upcoming = window(request, request.endMs, request.endMs + Self.scanMs)
            .filter { $0.startMs >= request.endMs }
            .min { $0.startMs < $1.startMs }
        guard let neighbour = upcoming, neighbour.endMs <= clock() else { return .live }
        return archiveOf(channel: request.channel, programme: neighbour)
            .map(CatchupJump.archive) ?? .live
    }

    private func window(_ request: CatchupRequest, _ fromMs: Int, _ toMs: Int) -> [ProgramEntity] {
        guard let tvgId = request.channel.epgId else { return [] }
        return programs([tvgId], fromMs, toMs)
    }

    /// Builds the neighbour's request; nil outside the catchup-days horizon.
    private func archiveOf(channel: ChannelEntity, programme: ProgramEntity) -> CatchupRequest? {
        let now = clock()
        guard let attributes = channel.catchupAttributes(),
              CatchupPlayability.playable(channel: channel, startMs: programme.startMs,
                                          endMs: programme.endMs, hasInfo: true, nowMs: now),
              let url = CatchupUrlBuilder.build(streamUrl: channel.source.streamUrl,
                                                attributes: attributes, startMs: programme.startMs,
                                                endMs: programme.endMs, nowMs: now) else { return nil }
        return CatchupRequest(channel: channel, url: url, title: programme.details.title,
                              startMs: programme.startMs, endMs: programme.endMs)
    }
}
