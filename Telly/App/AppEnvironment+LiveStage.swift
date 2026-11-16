import Foundation

/// The environment's ``LiveStagePresentation`` — the shared live engine store, the
/// hosted-model factory over THAT store's engine, and the factories the stage's
/// guide overlay reuses — assembled once so every live entry point (the home
/// list, History, My List, Search, the pushed Guide, the DEBUG routes) launches
/// live on the SAME persistent engine with the SAME overlay machine.
extension AppEnvironment {
    var liveStage: LiveStagePresentation {
        LiveStagePresentation(store: liveEngineStore, makeLiveModel: makeLiveStageModel(for:),
                              makeGuideModel: makeGuideGridModel,
                              makeEngine: makeEngine, makeCatchupModel: makeCatchupPlaybackModel)
    }

    /// The hosted live model for a tapped channel: built over the store's one
    /// engine (minted on first use), tuning `target` first, reporting every tune
    /// back to the store, and opening the guide overlay on BACK (TiviMate).
    func makeLiveStageModel(for target: LiveStageTarget) -> LivePlaybackModel {
        makeLivePlaybackModel(engine: liveEngineStore.acquire(), initialChannelId: target.id,
                              tileEngine: { [weak self] in self?.makeEngine() ?? VLCKitPlayerEngine() },
                              onTuned: { [liveEngineStore] in liveEngineStore.noteTuned($0.source.streamUrl) },
                              onExitToGuide: { [liveEngineStore] in liveEngineStore.showGuide() })
    }
}
