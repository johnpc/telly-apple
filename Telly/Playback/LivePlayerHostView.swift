import SwiftUI

/// The production LIVE stage: the full TiviMate-style ``LivePlaybackScreen``
/// (zap / info / quick-bar / panel / multiview / pickers) driven by ONE
/// ``LivePlaybackModel`` built over the store's shared engine, with the EPG guide
/// layered on top on demand (``LivePlayerGuideOverlayView``). The model lives in
/// this host — not in the screen — so showing the guide only swaps the surface
/// for the mini-player: the engine keeps decoding and nothing reconnects. BACK at
/// bare playback opens the guide (TiviMate); BACK on the guide (or the iOS close
/// button) leaves live, which tears the engine down via `store.exit()`.
struct LivePlayerHostView: View {
    let stage: LiveStagePresentation
    @State private var model: LivePlaybackModel
    @Environment(\.dismiss) private var dismiss

    init(stage: LiveStagePresentation, target: LiveStageTarget) {
        self.stage = stage
        _model = State(initialValue: stage.makeLiveModel(target))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if stage.store.guideVisible {
                LivePlayerGuideOverlayView(model: model, stage: stage)
            } else {
                LivePlaybackScreen(model: model, hosted: true, onGuide: { stage.store.showGuide() })
            }
        }
        .task { model.start() }
        .ticking(every: 0.2) { model.tick() }
        .onDisappear { stage.store.exit() }
        #if os(tvOS)
        .onExitCommand { dismiss() }   // reached only while the guide overlay owns focus
        #endif
    }
}
