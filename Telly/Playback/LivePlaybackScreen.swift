import SwiftUI

/// The live playback stage driven by ``LivePlaybackModel``: the VLC surface, the
/// zap/info/quick-bar/panel/track-picker overlays, and the engine-state chrome,
/// gated so a held frame shows no spinner. The only coroutine seam is the tick
/// loop here; all decisions live in the model. tvOS forwards remote keys via
/// `onKey`; iPhone/iPad map taps/swipes onto that same vocabulary (S7).
struct LivePlaybackScreen: View {
    @State var model: LivePlaybackModel

    init(model: LivePlaybackModel) { _model = State(initialValue: model) }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            surface
            zapOverlay
            infoOverlay
            quickBarOverlay
            panelOverlay
            multiviewOverlay
            trackPickerOverlay
            stateOverlay
            #if !os(tvOS)
            PlaybackCloseButton()
            #endif
        }
        .task {
            model.start()
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(200))
                model.tick()
            }
        }
        .onDisappear { model.close() }
        .fullScreenCover(isPresented: $model.searchRequested) {
            if let make = model.makeSearchModel { SearchScreen(model: make()) }
        }
        .playbackKeyForwarder(model)
        #if !os(tvOS)
        .gesture(DragGesture(minimumDistance: 0).onEnded { v in
            let g = TouchGesture.swipe(dx: v.translation.width, dy: v.translation.height)
            _ = model.onKey(TouchKeyMap.key(for: g, overlay: model.overlay))
        })
        #endif
    }

    @ViewBuilder private var multiviewOverlay: some View {
        if case .multiview = model.overlay, let session = model.multiview {
            MultiviewGridView(session: session)
        }
    }

    @ViewBuilder private var surface: some View {
        if let vlc = model.engine as? VLCKitPlayerEngine {
            VideoSurfaceView(engine: vlc).ignoresSafeArea()
        }
    }

    @ViewBuilder private var zapOverlay: some View {
        if case .zapInfo = model.overlay {
            ZapOverlayView(channel: model.current)
        }
    }

    @ViewBuilder private var infoOverlay: some View {
        switch model.overlay {
        case .info:
            InfoOverlayView(channel: model.current, nowNext: model.currentInfo,
                            nowMs: model.now(), expanded: false)
        case .infoTransport:
            InfoOverlayView(channel: model.current, nowNext: model.currentInfo,
                            nowMs: model.now(), expanded: true)
        default:
            EmptyView()
        }
    }

    @ViewBuilder private var quickBarOverlay: some View {
        if case .quickBar = model.overlay {
            QuickBarView(video: model.engine.video, subtitles: model.quickBarSubtitles,
                         sync: model.quickBarSync, onAction: { model.onQuickBarAction($0) })
        }
    }

    @ViewBuilder private var panelOverlay: some View {
        if case .panel = model.overlay {
            ChannelPanelView(channels: model.channels, current: model.current,
                             nowNext: model.nowNext, nowMs: model.now())
        }
    }

    @ViewBuilder private var stateOverlay: some View {
        if !model.holdsLastFrame {
            PlaybackStateOverlay(state: model.engine.state)
        }
    }
}
