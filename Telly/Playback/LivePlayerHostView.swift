import SwiftUI

/// The production LIVE player stage: a fullscreen VLC surface fed by the shared
/// ``LiveEngineStore`` engine, with a "Guide" affordance that layers the EPG over
/// the still-playing channel (``LivePlayerGuideOverlayView``). Because the engine
/// lives in the store — not this view — bringing the guide up and dismissing it
/// only toggles `store.guideVisible`; the engine keeps decoding and its drawable
/// re-parents between the fullscreen surface and the mini-player inset with no
/// reconnect. The engine is torn down only when this host itself disappears
/// (a real exit from live), never when the guide covers it.
struct LivePlayerHostView: View {
    let store: LiveEngineStore
    let url: String
    let makeGuideModel: () -> GuideGridModel
    let makeEngine: () -> VLCKitPlayerEngine
    let makeCatchupModel: (CatchupRequest) -> CatchupPlaybackModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if store.guideVisible {
                LivePlayerGuideOverlayView(store: store, makeGuideModel: makeGuideModel,
                                           makeEngine: makeEngine, makeCatchupModel: makeCatchupModel)
            } else {
                fullscreen
            }
        }
        .task { store.play(url) }
        .onDisappear { store.exit() }
        #if os(tvOS)
        .onExitCommand { if store.guideVisible { store.hideGuide() } else { dismiss() } }
        #endif
    }

    @ViewBuilder private var fullscreen: some View {
        surface.ignoresSafeArea()
        PlaybackStateOverlay(state: store.engine?.state ?? .idle)
        chrome
    }

    @ViewBuilder private var surface: some View {
        if let vlc = store.engine as? VLCKitPlayerEngine { VideoSurfaceView(engine: vlc) }
    }

    private var chrome: some View {
        VStack {
            HStack {
                #if !os(tvOS)
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill").font(.title).foregroundStyle(.white)
                }
                #endif
                Spacer()
                Button { store.showGuide() } label: {
                    Label("Guide", systemImage: "tv").foregroundStyle(.white)
                }
            }
            Spacer()
        }
        .padding()
    }
}
