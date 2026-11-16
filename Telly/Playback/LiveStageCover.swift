import SwiftUI

/// The single presentation seam every live entry point shares: a fullscreen
/// cover over the shared live stage (``LivePlayerHostView``), fed by the
/// app-lifetime ``LiveEngineStore`` inside ``LiveStagePresentation``. Routing
/// home, History, My List, Search and the pushed Guide through this one modifier
/// means every live launch reuses the SAME engine and the SAME overlay machine.
extension View {
    func liveStageCover(_ item: Binding<LiveStageTarget?>,
                        using stage: LiveStagePresentation) -> some View {
        fullScreenCover(item: item) { target in
            LivePlayerHostView(stage: stage, target: target)
        }
    }
}
