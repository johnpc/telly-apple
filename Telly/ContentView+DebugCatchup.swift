#if DEBUG
import SwiftUI

/// DEBUG-only catch-up / archive screenshot route for `ContentView`, split out to
/// keep `ContentView+Debug` within the source-line budget. `-tellyCatchup` seeds
/// the single catch-up fixture channel plus an already-aired programme, resolves
/// the archive URL through the same `ChannelEntity.catchupAttributes()` +
/// `CatchupUrlBuilder` path the guide uses (mirroring `TuneController.tune`),
/// then presents `PlaybackScreen` with a `CatchupBadge` so the "Catch-up" pill
/// can be captured over the black player stage — no real provider, no decode.
extension ContentView {
    @ViewBuilder var catchupDemo: some View {
        if let catchupTarget {
            PlaybackScreen(streamUrl: catchupTarget.url, engine: env.makeEngine(),
                           catchup: catchupTarget.catchup, is24h: env.settings.use24hClock)
        } else {
            Color.black.ignoresSafeArea().task { prepareCatchupDemo() }
        }
    }

    func prepareCatchupDemo() {
        let nowMs = Int(Date().timeIntervalSince1970 * 1_000)
        let base = DebugLaunch.value(for: "-tellySeedBase", in: debugArgs) ?? "http://127.0.0.1:8000/"
        _ = try? env.playlistStore.add(sourceUrl: base + "playlist.m3u",
                                       playlist: DebugLaunch.catchupFixturePlaylist(base: base),
                                       name: "Catch-up", nowMs: Int64(nowMs))
        env.reload()
        try? env.programStore.upsertReplacing(
            document: DebugLaunch.catchupEpgDocument(nowMs: nowMs), keepDescriptions: false)
        env.guideEpgStore.refresh()
        let start = nowMs - 90 * 60_000, end = nowMs - 30 * 60_000
        guard let channel = (try? env.channelStore.visibleChannels())?.first,
              let attributes = channel.catchupAttributes(),
              let url = CatchupUrlBuilder.build(streamUrl: channel.source.streamUrl,
                                                attributes: attributes,
                                                startMs: start, endMs: end, nowMs: nowMs)
        else { return }
        catchupTarget = GuidePlaybackTarget(
            id: channel.id, url: url,
            catchup: CatchupBadge(title: "Aired Documentary", startMs: start, endMs: end))
    }
}
#endif
