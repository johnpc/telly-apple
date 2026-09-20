import SwiftUI

/// The EPG guide layered over the live player. Reuses the full interactive
/// ``GuideGridScreen`` but rebinds channel selection to tune the SHARED engine
/// and drop back to fullscreen (`onLiveTune`) instead of opening a fresh cover —
/// so browsing → picking a channel is a seamless zap on the same engine. On the
/// roomy platforms (Apple TV, regular-width iPad; see ``MiniPlayerPlacement``) a
/// corner ``MiniPlayerInsetView`` keeps the current channel visible while you
/// browse; the compact iPhone width gives the grid the whole screen.
struct LivePlayerGuideOverlayView: View {
    let store: LiveEngineStore
    let makeGuideModel: () -> GuideGridModel
    let makeEngine: () -> VLCKitPlayerEngine
    let makeCatchupModel: (CatchupRequest) -> CatchupPlaybackModel
    #if !os(tvOS)
    @Environment(\.horizontalSizeClass) private var sizeClass
    #endif

    var body: some View {
        ZStack(alignment: .topTrailing) {
            GuideGridScreen(model: makeGuideModel(), makeEngine: makeEngine,
                            makeCatchupModel: makeCatchupModel,
                            onLiveTune: { store.play($0.source.streamUrl); store.hideGuide() })
            if showInset, let vlc = store.engine as? VLCKitPlayerEngine {
                MiniPlayerInsetView(engine: vlc) { store.hideGuide() }.padding()
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
