import SwiftUI

/// The corner mini-player shown in the guide overlay: the SHARED live engine's
/// surface re-parented into a small rounded inset so the current channel keeps
/// playing while the EPG is browsed. On the touch platforms tapping it returns to
/// fullscreen; tvOS dismisses via the remote's Menu/Back (handled by the host),
/// so there the inset is a non-focusable preview only.
struct MiniPlayerInsetView: View {
    let engine: VLCKitPlayerEngine
    let onTap: () -> Void

    var body: some View {
        #if os(tvOS)
        surface
        #else
        Button(action: onTap) { surface }
            .buttonStyle(.plain)
            .accessibilityLabel("Back to full screen")
        #endif
    }

    private var surface: some View {
        VideoSurfaceView(engine: engine)
            .frame(width: 320, height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.6), lineWidth: 2))
            .shadow(radius: 8)
    }
}
