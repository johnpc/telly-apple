#if DEBUG
import SwiftUI

/// DEBUG-only Movies-browser screenshot route for `ContentView`, split out to keep
/// `ContentView+Debug` within the source-line budget. `-tellyVodBrowse` seeds a few
/// movies across two categories plus one resume position into the shared database
/// (via ``DebugLaunch/seedVodIfRequested``), then presents ``VodBrowseScreen``
/// directly so the category column, poster grid and a Continue-watching bar can be
/// captured on a simulator without decoding any video.
extension ContentView {
    @ViewBuilder var vodBrowseDemo: some View {
        if let vodModel {
            NavigationStack { VodBrowseScreen(model: vodModel) }
        } else {
            Color.black.ignoresSafeArea().task { prepareVodBrowseDemo() }
        }
    }

    func prepareVodBrowseDemo() {
        DebugLaunch.seedVodIfRequested(
            items: VodItemStore(db: env.channelStore.db),
            positions: env.makeVodPositionStore(), args: debugArgs)
        vodModel = env.makeVodBrowseModel()
    }
}
#endif
