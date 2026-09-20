import Foundation

/// The environment's ``LiveStagePresentation`` — the shared live engine store
/// plus the factories the live stage's guide overlay reuses — assembled once so
/// every live entry point (the DEBUG screenshot routes here, the toolbar via
/// ``ChannelListScreen``) launches live on the SAME persistent engine.
extension AppEnvironment {
    var liveStage: LiveStagePresentation {
        LiveStagePresentation(store: liveEngineStore, makeGuideModel: makeGuideGridModel,
                              makeEngine: makeEngine, makeCatchupModel: makeCatchupPlaybackModel)
    }
}
