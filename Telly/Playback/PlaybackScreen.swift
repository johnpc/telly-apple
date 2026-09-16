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
            overlay
            #if !os(tvOS)
            closeButton
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

    @ViewBuilder private var overlay: some View {
        switch engine.state {
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
