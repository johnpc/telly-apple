import SwiftUI

/// The live playback stage driven by ``LivePlaybackModel``: the VLC surface, the
/// zap/info/quick-bar/panel/track-picker overlays, and the engine-state chrome,
/// gated so a held frame shows no spinner. The only coroutine seam is the tick
/// loop here; all decisions live in the model. tvOS forwards remote keys via
/// `onKey`; iPhone/iPad map taps/swipes onto that same vocabulary (S7).
struct LivePlaybackScreen: View {
    @State var model: LivePlaybackModel
    /// Custom groups surfaced in the panel's group column, forwarded to
    /// ``ChannelPanelView``; empty by default so existing call sites are unchanged.
    let customGroups: [CustomGroup]
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    init(model: LivePlaybackModel, customGroups: [CustomGroup] = []) {
        _model = State(initialValue: model)
        self.customGroups = customGroups
    }

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
            #if os(iOS)
            pipLifecycle
            #endif
            #if !os(tvOS)
            PlaybackCloseButton()
            #endif
        }
        .animation(Motion.gated(Motion.overlayIn, reduceMotion: reduceMotion), value: model.overlay)
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

    @ViewBuilder private var surface: some View {
        if let vlc = model.engine as? VLCKitPlayerEngine {
            VideoSurfaceView(engine: vlc).ignoresSafeArea()
        }
    }

    @ViewBuilder private var infoOverlay: some View {
        switch model.overlay {
        case .info:
            InfoOverlayView(channel: model.current, nowNext: model.currentInfo,
                            nowMs: model.now(), expanded: false)
                .overlayTransition(reduceMotion: reduceMotion)
        case .infoTransport:
            InfoOverlayView(channel: model.current, nowNext: model.currentInfo,
                            nowMs: model.now(), expanded: true,
                            transportFocus: model.transportFocus,
                            isPaused: model.engine.paused,
                            onTransport: { model.tapTransport($0) })
                .overlayTransition(reduceMotion: reduceMotion)
        default:
            EmptyView()
        }
    }
}
