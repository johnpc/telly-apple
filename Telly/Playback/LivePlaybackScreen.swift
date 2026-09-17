import SwiftUI

/// The live playback stage driven by ``LivePlaybackModel``: the VLC surface over
/// a black stage, the compact zap overlay, and the engine-state chrome (spinner /
/// reconnecting pill / error), gated so a held frame shows no spinner. The only
/// coroutine seam is the tick loop here; all decisions live in the model. tvOS
/// forwards remote keys through `onKey`; iPhone/iPad keep a Close button (the
/// rich touch layer arrives in S7).
struct LivePlaybackScreen: View {
    @State private var model: LivePlaybackModel

    init(model: LivePlaybackModel) { _model = State(initialValue: model) }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            surface
            zapOverlay
            infoOverlay
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
        #if os(tvOS)
        .focusable()
        .onMoveCommand { direction in
            switch direction {
            case .up: _ = model.onKey(.up)
            case .down: _ = model.onKey(.down)
            case .left: _ = model.onKey(.left)
            case .right: _ = model.onKey(.right)
            @unknown default: break
            }
        }
        .onTapGesture { _ = model.onKey(.ok) }
        .onExitCommand { _ = model.onKey(.back) }
        #endif
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

    @ViewBuilder private var stateOverlay: some View {
        if !model.holdsLastFrame {
            PlaybackStateOverlay(state: model.engine.state)
        }
    }
}
