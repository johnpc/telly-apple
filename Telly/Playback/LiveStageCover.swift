import SwiftUI

/// The single presentation seam every live entry point shares: a fullscreen
/// cover over the shared live stage (``LivePlayerHostView``), fed by the
/// app-lifetime ``LiveEngineStore`` inside ``LiveStagePresentation``. Routing
/// home, History, My List, Search and the pushed Guide through this one modifier
/// means every live launch reuses the SAME engine (seamless, with the guide
/// overlay + mini-player) rather than minting a fresh per-screen engine that
/// would reconnect the stream.
extension View {
    func liveStageCover(_ item: Binding<LiveStageTarget?>,
                        using stage: LiveStagePresentation) -> some View {
        fullScreenCover(item: item) { target in
            LivePlayerHostView(store: stage.store, url: target.url,
                               makeGuideModel: stage.makeGuideModel,
                               makeEngine: stage.makeEngine,
                               makeCatchupModel: stage.makeCatchupModel)
        }
    }
}
