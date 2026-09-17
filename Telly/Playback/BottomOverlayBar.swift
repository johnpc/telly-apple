import SwiftUI

/// The shared bottom-scrim container for the fullscreen playback overlays: a
/// bottom-anchored bar carrying arbitrary content over a top-to-bottom black
/// gradient, spanning the safe area. Extracted from ``ZapOverlayView`` so the
/// richer ``InfoOverlayView`` reuses the exact same scrim idiom in one place
/// (the ``PlaybackStateOverlay`` precedent) rather than duplicating it.
struct BottomOverlayBar<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        VStack {
            Spacer()
            content
                .foregroundStyle(.white)
                .padding(.horizontal, 48)
                .padding(.vertical, 44)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(scrim)
        }
        .ignoresSafeArea()
    }

    private var scrim: some View {
        LinearGradient(colors: [.black.opacity(0), .black.opacity(0.85)],
                       startPoint: .top, endPoint: .bottom)
    }
}
