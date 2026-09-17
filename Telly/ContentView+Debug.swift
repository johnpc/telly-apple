#if DEBUG
import SwiftUI

/// DEBUG-only launch-argument routing for `ContentView`: seeds local fixtures and
/// jumps straight to the live player, an autoplay stream, or the guide grid for
/// deterministic screenshot capture — one prepared route per proof, never
/// touching the real provider. Compiled out of release builds.
extension ContentView {
    var debugArgs: [String] { ProcessInfo.processInfo.arguments }

    @ViewBuilder var debugRoot: some View {
        if DebugLaunch.forcedGuide(in: debugArgs) {
            guideDemo
        } else if debugArgs.contains("-tellyMultiviewDemo") {
            multiviewDemo
        } else if DebugLaunch.liveDemoRequested(in: debugArgs) {
            liveDemo
        } else if let url = DebugLaunch.autoplayUrl(in: debugArgs) {
            PlaybackScreen(streamUrl: url, engine: env.makeEngine())
        } else {
            mainContent.task { seedDebugFixtures() }
        }
    }

    @ViewBuilder var liveDemo: some View {
        if let liveModel {
            LivePlaybackScreen(model: liveModel)
        } else {
            Color.black.ignoresSafeArea().task { prepareLiveDemo() }
        }
    }

    func prepareLiveDemo() {
        seedDebugFixtures()
        let model = env.makeLivePlaybackModel()
        if DebugLaunch.forcedZapOverlay(in: debugArgs) { model.debugPresentZapOverlay() }
        if DebugLaunch.forcedQuickBarOverlay(in: debugArgs) { model.debugPresentQuickBarOverlay() }
        if let kind = DebugLaunch.forcedTrackPicker(in: debugArgs) { model.debugPresentTrackPicker(kind) }
        seedInfoOverlayIfRequested(model)
        seedPanelOverlayIfRequested(model)
        liveModel = model
    }

    func seedPanelOverlayIfRequested(_ model: LivePlaybackModel) {
        guard DebugLaunch.forcedPanelOverlay(in: debugArgs) else { return }
        let nowMs = Int(Date().timeIntervalSince1970 * 1_000)
        try? env.programStore.upsertReplacing(
            document: DebugLaunch.guideEpgDocument(nowMs: nowMs), keepDescriptions: false)
        env.guideEpgStore.refresh()
        model.debugPresentPanelOverlay()
    }

    func seedInfoOverlayIfRequested(_ model: LivePlaybackModel) {
        guard DebugLaunch.forcedInfoOverlay(in: debugArgs) else { return }
        let nowMs = Int(Date().timeIntervalSince1970 * 1_000)
        try? env.programStore.upsertReplacing(
            document: DebugLaunch.infoFixtureDocument(nowMs: nowMs), keepDescriptions: false)
        env.guideEpgStore.refresh()
        model.debugPresentInfoOverlay()
    }

    @ViewBuilder var guideDemo: some View {
        if let guideModel {
            GuideGridScreen(model: guideModel, makeEngine: env.makeEngine)
        } else {
            Color.black.ignoresSafeArea().task { prepareGuideDemo() }
        }
    }

    func prepareGuideDemo() {
        seedDebugFixtures()
        DebugLaunch.seedGuideEpg(into: env.programStore, args: debugArgs,
                                 now: { Int(Date().timeIntervalSince1970 * 1_000) })
        guideModel = env.makeGuideGridModel()
    }

    func seedDebugFixtures() {
        DebugLaunch.seedIfRequested(into: env.playlistStore, args: debugArgs,
                                    now: { Int64(Date().timeIntervalSince1970 * 1000) })
        env.reload()
        DebugLaunch.seedFavoritesIfRequested(into: env.channelStore, args: debugArgs)
        if let group = DebugLaunch.forcedChannelGroup(in: debugArgs) {
            env.channelListModel.select(group)
        }
        env.channelListModel.load()
    }
}
#endif
