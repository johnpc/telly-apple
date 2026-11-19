import SwiftUI

/// The live playback stage driven by ``LivePlaybackModel``: the VLC surface, the
/// zap/info/quick-bar/panel/track-picker overlays, and the engine-state chrome,
/// gated so a held frame shows no spinner. The shared ``ticking`` clock is the
/// only timer; all decisions live in the model. tvOS forwards remote keys via
/// `onKey` from ``PlaybackKeyLayer`` — a sibling of the overlays, not their
/// parent (see its doc); iPhone/iPad map taps/swipes onto that same vocabulary (S7).
struct LivePlaybackScreen: View {
    @State var model: LivePlaybackModel
    /// Custom groups surfaced in the panel's group column, forwarded to
    /// ``ChannelPanelView``; empty by default so existing call sites are unchanged.
    let customGroups: [CustomGroup]
    /// `hosted`: the ``LivePlayerHostView`` owns start / tick / teardown (so the
    /// engine survives the guide overlay); standalone (DEBUG proofs) drives them here.
    let hosted: Bool
    /// Opens the guide overlay (touch platforms' affordance; tvOS uses BACK).
    let onGuide: (() -> Void)?
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    init(model: LivePlaybackModel, customGroups: [CustomGroup] = [],
         hosted: Bool = false, onGuide: (() -> Void)? = nil) {
        _model = State(initialValue: model)
        self.customGroups = customGroups
        self.hosted = hosted
        self.onGuide = onGuide
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            surface
            PlaybackKeyLayer(model: model)
            zapOverlay
            infoOverlay
            quickBarOverlay
            panelOverlay
            multiviewOverlay
            multiviewMenuOverlay
            multiviewPickerOverlay
            trackPickerOverlay
            resizePickerOverlay
            stateOverlay
            #if !os(tvOS)
            PlaybackCloseButton()
            guideButton
            #endif
        }
        .animation(Motion.gated(Motion.overlayIn, reduceMotion: reduceMotion), value: model.overlay)
        .task { if !hosted { model.start() } }
        .ticking(every: 0.2) { if !hosted { model.tick() } }
        .onDisappear { if !hosted { model.close() } }
        .fullScreenCover(isPresented: $model.searchRequested) {
            if let make = model.makeSearchModel { SearchScreen(model: make()) }
        }
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

    #if !os(tvOS)
    @ViewBuilder private var guideButton: some View {
        if let onGuide {
            Button(action: onGuide) { Label("Guide", systemImage: "tv").foregroundStyle(.white) }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
    }
    #endif

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
