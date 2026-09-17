#if DEBUG
import SwiftUI

/// DEBUG-only launch-argument routing for `ContentView`: seeds local fixtures and
/// jumps to a prepared route per proof (live player, autoplay, guide, locked-
/// channel PIN challenge — see `+ParentalDebug`), never touching the real provider.
extension ContentView {
    var debugArgs: [String] { ProcessInfo.processInfo.arguments }

    @ViewBuilder var debugRoot: some View {
        if DebugLaunch.settingsRequested(in: debugArgs) {
            SettingsScreen(settings: env.settings, parental: env.parentalStore,
                           backup: env.makeSettingsBackupModel(),
                           playlists: env.makePlaylistsSettingsModel(),
                           makeVisibilityEditModel: env.makeVisibilityEditModel, clearVodPositions: env.clearVodPositions, onClose: {})
        } else if DebugLaunch.playlistDebugRequested(in: debugArgs) {
            playlistsDebug
        } else if DebugLaunch.forcedGuide(in: debugArgs) {
            guideDemo
        } else if DebugLaunch.historyDemoRequested(in: debugArgs) {
            historyDemo
        } else if DebugLaunch.searchDebugRequested(in: debugArgs) {
            searchDebug
        } else if DebugLaunch.groupsDebugRequested(in: debugArgs) {
            groupsDebug
        } else if DebugLaunch.vodBrowseRequested(in: debugArgs) {
            vodBrowseDemo
        } else if DebugLaunch.vodPlaybackRequested(in: debugArgs) { vodPlaybackDemo
        } else if DebugLaunch.parentalChallengeRequested(in: debugArgs) {
            parentalChallengeDemo
        } else if DebugLaunch.catchupTransportRequested(in: debugArgs) {
            catchupTransportDemo
        } else if DebugLaunch.catchupDemoRequested(in: debugArgs) {
            catchupDemo
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
        applyKeymapOverrideIfRequested()
        seedDebugFixtures()
        let model = env.makeLivePlaybackModel()
        if DebugLaunch.forcedZapOverlay(in: debugArgs) { model.debugPresentZapOverlay() }
        if DebugLaunch.forcedMultiviewOverlay(in: debugArgs) { model.debugPresentMultiviewOverlay() }
        if DebugLaunch.forcedQuickBarOverlay(in: debugArgs) { model.debugPresentQuickBarOverlay() }
        if let kind = DebugLaunch.forcedTrackPicker(in: debugArgs) { model.debugPresentTrackPicker(kind) }
        seedInfoOverlayIfRequested(model)
        seedPanelOverlayIfRequested(model)
        deliverKeymapProofKeyIfNeeded(model)
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

    func seedDebugFixtures() {
        DebugLaunch.seedIfRequested(into: env.playlistStore, args: debugArgs,
                                    now: { Int64(Date().timeIntervalSince1970 * 1000) })
        env.reload()
        DebugLaunch.seedFavoritesIfRequested(into: env.channelStore, args: debugArgs)
        if let group = DebugLaunch.forcedChannelGroup(in: debugArgs) {
            env.channelListModel.select(group)
        }
        env.channelListModel.load()
        if let q = DebugLaunch.forcedChannelSearch(in: debugArgs) {
            env.channelListModel.query = q
        }
    }
}
#endif
