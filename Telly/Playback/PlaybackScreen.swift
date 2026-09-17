import SwiftUI

/// The first live playback UI: a fullscreen black stage with the VLC surface and
/// a state overlay (buffering spinner, reconnecting pill, error message). Owns
/// its engine for the view's lifetime and drives load/stop/release. Per-platform
/// affordances differ — a Close button on iPhone/iPad, the Menu button on tvOS.
struct PlaybackScreen: View {
    let streamUrl: String
    @State private var engine: VLCKitPlayerEngine
    @Environment(\.dismiss) private var dismiss

    init(streamUrl: String, engine: VLCKitPlayerEngine) {
        self.streamUrl = streamUrl
        _engine = State(initialValue: engine)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VideoSurfaceView(engine: engine).ignoresSafeArea()
            PlaybackStateOverlay(state: engine.state)
            #if !os(tvOS)
            PlaybackCloseButton()
            #endif
        }
        .task { engine.load(streamUrl) }
        .onDisappear {
            engine.stop()
            engine.release()
        }
        #if os(tvOS)
        .onExitCommand { dismiss() }
        #endif
    }
}
