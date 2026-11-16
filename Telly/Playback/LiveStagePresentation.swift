import Foundation

/// The dependencies every live entry point needs to present the SHARED live stage
/// (``LivePlayerHostView``): the app-lifetime engine store, the factory that
/// builds the full ``LivePlaybackModel`` over the store's engine for a tapped
/// channel, and the factories its guide overlay reuses (guide model, catch-up
/// model, and a fresh engine for terminal catch-up/VOD covers). Bundling them
/// lets Home, History, My List, Search and the pushed Guide funnel through one
/// `.liveStageCover` instead of each threading five parameters.
struct LiveStagePresentation {
    let store: LiveEngineStore
    let makeLiveModel: (LiveStageTarget) -> LivePlaybackModel
    let makeGuideModel: () -> GuideGridModel
    let makeEngine: () -> VLCKitPlayerEngine
    let makeCatchupModel: (CatchupRequest) -> CatchupPlaybackModel
}
