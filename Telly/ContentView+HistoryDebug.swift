#if DEBUG
import SwiftUI

/// DEBUG-only recently-watched screenshot route for `ContentView`, split out to
/// keep `ContentView+Debug` within the source-line budget. `-tellyHistorySeed`
/// seeds the fixture playlist, records its first three channels newest-first into
/// the watch-history store, then presents `HistoryScreen` directly (independent
/// of the toolbar navigation) so the three-row list can be captured on a
/// simulator without decoding any live stream.
extension ContentView {
    @ViewBuilder var historyDemo: some View {
        if let historyModel {
            NavigationStack {
                HistoryScreen(model: historyModel, liveStage: env.liveStage)
            }
        } else {
            Color.black.ignoresSafeArea().task { prepareHistoryDemo() }
        }
    }

    func prepareHistoryDemo() {
        seedDebugFixtures()
        let channels = (try? env.channelStore.visibleChannels()) ?? []
        DebugLaunch.seedHistoryIfRequested(into: env.watchHistoryStore, channels: channels,
                                           args: debugArgs,
                                           now: Int(Date().timeIntervalSince1970 * 1_000))
        historyModel = env.makeHistoryModel()
    }
}
#endif
