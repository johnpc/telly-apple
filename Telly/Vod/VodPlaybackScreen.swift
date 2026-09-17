import SwiftUI

/// The VOD playback stage driven by ``VodPlaybackModel`` (Apple mirror of the
/// Android `VodPlaybackScreen`): the VLC surface, the engine-state chrome, and —
/// switched on ``VodPlaybackModel/stage`` — either the auto-hiding transport or
/// the Resume/Start-over prompt (see the `+Layers` sibling). The only coroutine
/// seam is the 500 ms tick loop here, which samples position, persists past the
/// threshold and finishes an ended movie; every decision lives in the model.
/// tvOS forwards remote keys through ``VodPlaybackKeys``; iPhone/iPad add a Close
/// button and a tap/swipe mapped onto the same vocabulary. BACK persists+exits.
struct VodPlaybackScreen: View {
    @State var model: VodPlaybackModel

    init(model: VodPlaybackModel) { _model = State(initialValue: model) }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            surface
            PlaybackStateOverlay(state: model.engine.state)
            layers
            #if !os(tvOS)
            Button { model.exit() } label: {
                Image(systemName: "xmark.circle.fill").font(.title).foregroundStyle(.white)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            #endif
        }
        .task {
            model.start()
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                model.tick()
            }
        }
        .onDisappear { model.exit() }
        .vodPlaybackKeys(model)
    }

    @ViewBuilder private var surface: some View {
        if let vlc = model.engine as? VLCKitPlayerEngine {
            VideoSurfaceView(engine: vlc).ignoresSafeArea()
        }
    }
}
