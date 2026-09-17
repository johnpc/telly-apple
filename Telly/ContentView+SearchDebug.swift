#if DEBUG
import SwiftUI

/// DEBUG-only Search screenshot routes (Slice 8), split out to keep
/// `ContentView+Debug` within budget. Seeds the synthetic playlist + now/next
/// programmes + recent-query history once (`DebugLaunch.seedSearchFixtures`),
/// then presents `SearchScreen` directly: `-tellySearch` lands on the empty-
/// query history list, `-tellySearchResults <query>` prefills the query and runs
/// `search()` so the Channels shelf + Programs master-lane + detail card render —
/// never touching the real provider.
extension ContentView {
    @ViewBuilder var searchDebug: some View {
        if let searchModel {
            SearchScreen(model: searchModel, makeEngine: env.makeEngine)
        } else {
            Color.black.ignoresSafeArea().task { prepareSearchDebug() }
        }
    }

    func prepareSearchDebug() {
        DebugLaunch.seedSearchFixtures(
            playlistStore: env.playlistStore, programStore: env.programStore,
            store: env.settings.backing, now: { Int(Date().timeIntervalSince1970 * 1_000) })
        env.reload()
        let model = env.makeSearchModel()
        model.load()
        if let query = DebugLaunch.searchResultsQuery(in: debugArgs) {
            model.query = query
            model.search()
        }
        searchModel = model
    }
}
#endif
