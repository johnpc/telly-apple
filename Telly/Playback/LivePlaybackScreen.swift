import SwiftUI

/// The live playback stage driven by ``LivePlaybackModel``: the VLC surface over
/// a black stage, the compact zap overlay, and the engine-state chrome (spinner /
/// reconnecting pill / error), gated so a held frame shows no spinner. The only
/// coroutine seam is the tick loop here; all decisions live in the model. tvOS
/// forwards remote keys through `onKey`; iPhone/iPad keep a Close button (the
/// rich touch layer arrives in S7).
struct LivePlaybackScreen: View {
    @State private var model: LivePlaybackModel
    @Environment(\.dismiss) private var dismiss

    init(model: LivePlaybackModel) { _model = State(initialValue: model) }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            surface
            zapOverlay
            stateOverlay
            #if !os(tvOS)
            closeButton
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

    @ViewBuilder private var stateOverlay: some View {
        if !model.holdsLastFrame {
            switch model.engine.state {
            case .buffering:
                ProgressView().controlSize(.large).tint(.white)
            case .reconnecting:
                Text("Reconnecting…")
                    .font(.headline).foregroundStyle(.white)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
            case let .error(message):
                Text(message).font(.headline).foregroundStyle(.white)
                    .multilineTextAlignment(.center).padding()
            default:
                EmptyView()
            }
        }
    }

    #if !os(tvOS)
    private var closeButton: some View {
        VStack {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title).foregroundStyle(.white)
                }
                .padding()
                Spacer()
            }
            Spacer()
        }
    }
    #endif
}
