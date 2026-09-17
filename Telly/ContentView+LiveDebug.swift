#if DEBUG
import SwiftUI

/// DEBUG-only live-player screenshot route for `ContentView`, split out of
/// `ContentView+Debug` to keep that file within the source-line budget while a
/// new demo branch is added. `-tellyLiveDemo` seeds the fixture playlist and
/// presents `LivePlaybackScreen`, optionally pinning an overlay open (zap /
/// info / quick-bar / panel / track picker) for the capture — a pure move, no
/// behaviour change.
extension ContentView {
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
}
#endif
