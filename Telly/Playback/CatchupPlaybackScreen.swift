import SwiftUI

/// The archive playback stage driven by ``CatchupPlaybackModel``: the VLC
/// surface, the engine-state chrome, and the read-only ``CatchupTransportRow``.
/// The shared 200 ms ``ticking`` clock drives `tick()` (position sample + the
/// finished-archive check); every decision lives in the model. tvOS forwards
/// play/pause + D-pad through the model; iPhone/iPad add a Close button and a
/// swipe→seek gesture. Mirrors ``LivePlaybackScreen`` beside it, keeping
/// ``LivePlaybackModel`` untouched.
struct CatchupPlaybackScreen: View {
    @State var model: CatchupPlaybackModel
    let request: CatchupRequest
    @Environment(\.dismiss) private var dismiss

    init(model: CatchupPlaybackModel, request: CatchupRequest) {
        _model = State(initialValue: model)
        self.request = request
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            surface
            PlaybackStateOverlay(state: model.engine.state)
            CatchupTransportRow(title: model.state?.request.title,
                                positionMs: model.positionMs,
                                durationMs: model.durationMs,
                                isPaused: model.isPaused)
            #if !os(tvOS)
            PlaybackCloseButton()
            #endif
        }
        .task {
            model.onExitToGuide = { dismiss() }
            model.start(request)
        }
        .ticking(every: 0.2) { model.tick() }
        .onDisappear { model.close() }
        .catchupKeys(model)
    }

    @ViewBuilder private var surface: some View {
        if let vlc = model.engine as? VLCKitPlayerEngine {
            VideoSurfaceView(engine: vlc).ignoresSafeArea()
        }
    }
}
