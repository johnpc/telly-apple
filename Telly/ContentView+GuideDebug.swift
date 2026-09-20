#if DEBUG
import SwiftUI

/// DEBUG-only guide-grid screenshot route for `ContentView`, split out of
/// `ContentView+Debug` so the at-cap file stays within the source-line budget.
/// `-tellyGuide` seeds the synthetic guide EPG, builds the grid model, and
/// presents `GuideGridScreen` — the base the catch-up proof builds on — without
/// ever touching the real provider.
extension ContentView {
    @ViewBuilder var guideDemo: some View {
        if let guideModel {
            GuideGridScreen(model: guideModel, makeEngine: env.makeEngine,
                            makeCatchupModel: env.makeCatchupPlaybackModel)
        } else {
            Color.black.ignoresSafeArea().task { prepareGuideDemo() }
        }
    }

    func prepareGuideDemo() {
        seedDebugFixtures()
        if let use24h = DebugLaunch.clock24hOverride(in: debugArgs) { env.settings.use24hClock = use24h }
        DebugLaunch.seedGuideEpg(into: env.programStore, args: debugArgs,
                                 now: { Int(Date().timeIntervalSince1970 * 1_000) })
        let model = env.makeGuideGridModel()
        model.load()
        if let group = DebugLaunch.forcedChannelGroup(in: debugArgs) { model.selectGroup(group) }
        guideModel = model
    }
}
#endif
