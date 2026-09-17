#if DEBUG
import SwiftUI

/// DEBUG-only multiview screenshot route for `ContentView`, split out to keep
/// `ContentView+Debug` within the source-line budget. `-tellyMultiviewDemo`
/// builds a fake-tile grid (no engines, nothing decoded) from the seeded fixture
/// channels so the layout + active-cell ring can be captured on a simulator,
/// entirely independent of the live playback core.
extension ContentView {
    @ViewBuilder var multiviewDemo: some View {
        if let multiviewSession {
            ZStack {
                Color.black.ignoresSafeArea()
                MultiviewGridView(session: multiviewSession)
            }
        } else {
            Color.black.ignoresSafeArea().task { prepareMultiviewDemo() }
        }
    }

    func prepareMultiviewDemo() {
        seedDebugFixtures()
        let channels = env.channelListModel.channels
        multiviewSession = MultiviewGrid(channels: channels, capacity: 4,
                                         activeChannelId: channels.first?.id)
            .map { MultiviewSession(grid: $0) }
    }
}
#endif
