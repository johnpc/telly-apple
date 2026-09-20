import Foundation

/// The dependencies every live entry point needs to present the SHARED live
/// stage (``LivePlayerHostView``): the app-lifetime engine store plus the
/// factories its guide overlay + corner mini-player reuse. Bundling them lets
/// History, My List, Search and the pushed Guide funnel through one
/// `.liveStageCover` (see ``View/liveStageCover(_:using:)``) instead of each
/// threading four separate parameters — and keeps those screen files lean.
struct LiveStagePresentation {
    let store: LiveEngineStore
    let makeGuideModel: () -> GuideGridModel
    let makeEngine: () -> VLCKitPlayerEngine
    let makeCatchupModel: (CatchupRequest) -> CatchupPlaybackModel
}
