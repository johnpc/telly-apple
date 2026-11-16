#if DEBUG
import SwiftUI

/// DEBUG-only live-player screenshot route for `ContentView`, split out of
/// `ContentView+Debug` to keep that file within the source-line budget while a
/// new demo branch is added. `-tellyLiveDemo` seeds the fixture playlist and
/// presents `LivePlaybackScreen`, optionally pinning ONE ``DebugLaunch/Overlay``
/// open (zap / info / transport / quick-bar / panel / multiview layers / track
/// pickers) for the capture.
extension ContentView {
    @ViewBuilder var liveDemo: some View {
        if let liveModel {
            LivePlaybackScreen(model: liveModel)
        } else {
            Color.black.ignoresSafeArea().task { await installDemoIfRequested(); prepareLiveDemo() }
        }
    }

    func prepareLiveDemo() {
        applyKeymapOverrideIfRequested()
        seedDebugFixtures()
        let model = env.makeLivePlaybackModel()
        if let overlay = DebugLaunch.forcedOverlay(in: debugArgs) { pin(overlay, on: model) }
        deliverKeymapProofKeyIfNeeded(model)
        liveModel = model
    }

    /// Pin exactly the requested layer open — exhaustive, so a new `Overlay`
    /// case must be given a presentation here to compile.
    private func pin(_ overlay: DebugLaunch.Overlay, on model: LivePlaybackModel) {
        switch overlay {
        case .zap: model.debugPresentZapOverlay()
        case .info: seedEpg(DebugLaunch.infoFixtureDocument); model.debugPresentInfoOverlay()
        case .transport: seedEpg(DebugLaunch.infoFixtureDocument); model.debugPresentTransportOverlay()
        case .quickBar: model.debugPresentQuickBarOverlay()
        case .panel: seedEpg(DebugLaunch.guideEpgDocument); model.debugPresentPanelOverlay()
        case .multiview: model.debugPresentMultiviewOverlay()
        case .multiviewMenu: model.debugPresentMultiviewPaneMenu()
        case .multiviewPicker: model.debugPresentMultiviewPicker()
        case .trackAudio, .trackSubtitles:
            overlay.trackPicker.map { model.debugPresentTrackPicker($0) }
        }
    }

    /// Seed the overlay's now/next from a synthetic document anchored to the clock.
    private func seedEpg(_ document: (Int) -> XmltvDocument) {
        let nowMs = Int(Date().timeIntervalSince1970 * 1_000)
        try? env.programStore.upsertReplacing(document: document(nowMs), keepDescriptions: false)
        env.guideEpgStore.refresh()
    }
}
#endif
