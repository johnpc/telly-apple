import SwiftUI

/// The standalone (pushed) Guide's live launch. Wraps ``GuideGridScreen`` so an
/// airing cell opens the SHARED live stage (``LivePlayerHostView`` via
/// `.liveStageCover`) instead of minting a fresh per-screen engine — matching
/// the home overlay's `onLiveTune`. Catch-up cells stay TERMINAL inside
/// ``GuideGridScreen`` (their own ``CatchupPlaybackScreen`` engine), so the
/// persistent live engine is used only for live and never leaks decoding VOD.
struct GuideStageScreen: View {
    let stage: LiveStagePresentation
    @State private var target: LiveStageTarget?

    var body: some View {
        GuideGridScreen(model: stage.makeGuideModel(), makeEngine: stage.makeEngine,
                        makeCatchupModel: stage.makeCatchupModel,
                        onLiveTune: { target = LiveStageTarget(channel: $0) })
            .liveStageCover($target, using: stage)
    }
}
