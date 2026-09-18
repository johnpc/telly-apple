#if DEBUG
import SwiftUI

/// DEBUG-only channel-list load-state proof: shows the list with `autoStart`
/// off and pins the requested `LoadPhase`, so `simctl launch -tellyLoadState …`
/// captures the skeleton / empty / error+Retry states with no real playlist.
/// The injected refresh throws so pressing Retry loops back through the failure.
extension ContentView {
    @ViewBuilder func loadStateDemo(_ demo: DebugLaunch.LoadStateDemo) -> some View {
        makeChannelListScreen(autoStart: false).task {
            env.channelListModel.refresh = { throw TimeoutError() }
            env.channelListModel.phase = demo.phase
        }
    }
}
#endif
