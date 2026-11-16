import SwiftUI

/// The EPG guide layered over the live player. Reuses the full interactive
/// ``GuideGridScreen`` but rebinds channel selection to tune the hosted
/// ``LivePlaybackModel`` (same engine) and drop back to fullscreen — so browsing
/// → picking a channel is a seamless zap. On the roomy platforms (Apple TV,
/// regular-width iPad; see ``MiniPlayerPlacement``) a corner ``MiniPlayerInsetView``
/// keeps the current channel visible while you browse; the compact iPhone width
/// gives the grid the whole screen.
struct LivePlayerGuideOverlayView: View {
    let model: LivePlaybackModel
    let stage: LiveStagePresentation
    #if !os(tvOS)
    @Environment(\.horizontalSizeClass) private var sizeClass
    #endif

    var body: some View {
        ZStack(alignment: .topTrailing) {
            GuideGridScreen(model: stage.makeGuideModel(), makeEngine: stage.makeEngine,
                            makeCatchupModel: stage.makeCatchupModel,
                            onLiveTune: { model.tune($0); stage.store.hideGuide() })
            if showInset, let vlc = model.engine as? VLCKitPlayerEngine {
                MiniPlayerInsetView(engine: vlc) { stage.store.hideGuide() }.padding()
            }
        }
    }

    private var showInset: Bool {
        #if os(tvOS)
        MiniPlayerPlacement.shown(compact: false, tv: true)
        #else
        MiniPlayerPlacement.shown(compact: sizeClass == .compact, tv: false)
        #endif
    }
}
