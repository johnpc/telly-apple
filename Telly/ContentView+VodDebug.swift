#if DEBUG
import SwiftUI

/// DEBUG-only Movies-browser screenshot route for `ContentView`, split out to keep
/// `ContentView+Debug` within the source-line budget. `-tellyVodBrowse` seeds a few
/// movies across two categories plus one resume position into the shared database
/// (via ``DebugLaunch/seedVodIfRequested``), then presents ``VodBrowseScreen``
/// directly so the category column, poster grid and a Continue-watching bar can be
/// captured on a simulator without decoding any video.
extension ContentView {
    @ViewBuilder var vodBrowseDemo: some View {
        if let vodModel {
            NavigationStack {
                VodBrowseScreen(model: vodModel, makePlaybackModel: env.makeVodPlaybackModel)
            }
        } else {
            Color.black.ignoresSafeArea().task { prepareVodBrowseDemo() }
        }
    }

    func prepareVodBrowseDemo() {
        DebugLaunch.seedVodIfRequested(
            items: VodItemStore(db: env.channelStore.db),
            positions: env.makeVodPositionStore(), args: debugArgs)
        vodModel = env.makeVodBrowseModel()
    }

    /// Routes to VOD playback held on a canned frame: `-tellyVodPlayback` shows the
    /// transport overlay, `-tellyVodResume` opens the Resume/Start-over prompt. Uses
    /// ``DebugVodEngine`` (no decode) and a frozen clock so the transport never
    /// auto-hides while the simulator captures the screenshot.
    @ViewBuilder var vodPlaybackDemo: some View {
        if let vodPlaybackModel {
            VodPlaybackScreen(model: vodPlaybackModel)
        } else {
            Color.black.ignoresSafeArea().task { prepareVodPlaybackDemo() }
        }
    }

    func prepareVodPlaybackDemo() {
        let items = VodItemStore(db: env.channelStore.db)
        let positions = env.makeVodPositionStore()
        try? items.replace(playlistId: DebugLaunch.vodPlaylistId, items: DebugLaunch.vodFixture())
        let resume = DebugLaunch.vodResumePromptRequested(in: debugArgs)
        let key = resume ? DebugLaunch.vodResumeKey : DebugLaunch.vodPlaybackKey
        if resume { try? positions.save(itemKey: key, positionMs: 30 * 60_000, durationMs: 90 * 60_000) }
        let progress = DebugLaunch.vodPlaybackProgress
        vodPlaybackModel = VodPlaybackModel(
            engine: DebugVodEngine(positionMs: progress.positionMs, durationMs: progress.durationMs),
            itemStore: items, positionStore: positions, itemKey: key, now: { 0 }, onExit: {})
    }
}
#endif
