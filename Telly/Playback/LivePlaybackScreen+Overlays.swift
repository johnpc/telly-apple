import SwiftUI

/// The transient overlay layers for ``LivePlaybackScreen`` (zap flash, quick-bar,
/// multiview) plus the engine-state chrome, split out so the screen stays within
/// the source-line budget. Each `model.overlay`-driven layer carries the shared
/// `overlayTransition` — a graceful fade + rise in, a quick fade out — animated by
/// the host ZStack's ambient `Motion.overlayIn` transaction. The state chrome
/// reflects `engine.state`, not the overlay, so it is not part of that motion.
extension LivePlaybackScreen {
    @ViewBuilder var zapOverlay: some View {
        if case .zapInfo = model.overlay {
            ZapOverlayView(channel: model.current)
                .overlayTransition(reduceMotion: reduceMotion)
        }
    }

    @ViewBuilder var quickBarOverlay: some View {
        if case .quickBar = model.overlay {
            QuickBarView(video: model.engine.video, subtitles: model.quickBarSubtitles,
                         sync: model.quickBarSync, onAction: { model.onQuickBarAction($0) })
                .overlayTransition(reduceMotion: reduceMotion)
        }
    }

    @ViewBuilder var multiviewOverlay: some View {
        if case .multiview = model.overlay, let session = model.multiview {
            MultiviewGridView(session: session)
                .overlayTransition(reduceMotion: reduceMotion)
        }
    }

    @ViewBuilder var stateOverlay: some View {
        if !model.holdsLastFrame {
            PlaybackStateOverlay(state: model.engine.state)
        }
    }
}
