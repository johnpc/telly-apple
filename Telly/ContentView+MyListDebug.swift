#if DEBUG
import SwiftUI

/// DEBUG-only My List screenshot route for `ContentView`, split out to keep
/// `ContentView+Debug` within the source-line budget. `-tellyMyListSeed` seeds
/// the fixture playlist, saves one airing-now and one future programme into the
/// `my_list` store, then presents `MyListScreen` directly (independent of the
/// toolbar navigation) so the two-row list can be captured on a simulator
/// without decoding any live stream (the `+HistoryDebug` precedent).
extension ContentView {
    @ViewBuilder var myListDemo: some View {
        if let myListModel {
            NavigationStack {
                MyListScreen(model: myListModel, liveStage: env.liveStage)
            }
        } else {
            Color.black.ignoresSafeArea().task { prepareMyListDemo() }
        }
    }

    func prepareMyListDemo() {
        seedDebugFixtures()
        let channels = (try? env.channelStore.visibleChannels()) ?? []
        DebugLaunch.seedMyListIfRequested(into: MyListStore(db: env.channelStore.db),
                                          channels: channels, args: debugArgs,
                                          now: Int(Date().timeIntervalSince1970 * 1_000))
        myListModel = env.makeMyListModel()
    }
}
#endif
