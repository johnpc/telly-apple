import SwiftUI

/// The search surface: a `.searchable` query field over a NavigationStack that
/// recomputes results on every keystroke. An empty query lands on the recent-
/// query history (tap a row to re-run it, the trash button clears it); a
/// non-empty query shows the Channels shelf then the Programs master-lane via
/// ``SearchResultsView``. Selecting any result tunes it through the same
/// `.fullScreenCover` → ``PlaybackScreen`` path History uses. Pure presentation
/// — logic lives in ``SearchModel``.
struct SearchScreen: View {
    @State private var model: SearchModel
    let makeEngine: @MainActor () -> VLCKitPlayerEngine

    init(model: SearchModel, makeEngine: @escaping @MainActor () -> VLCKitPlayerEngine = { VLCKitPlayerEngine() }) {
        _model = State(initialValue: model)
        self.makeEngine = makeEngine
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Search")
                .searchable(text: $model.query, prompt: "Search channels and programmes")
                .onChange(of: model.query) { model.search() }
        }
        .onAppear { model.load() }
        .fullScreenCover(item: $model.tuneTarget) { target in
            PlaybackScreen(streamUrl: target.url, engine: makeEngine())
        }
    }

    @ViewBuilder private var content: some View {
        if model.query.isEmpty { historyList } else { SearchResultsView(model: model) }
    }

    @ViewBuilder private var historyList: some View {
        List(model.historyEntries, id: \.self) { entry in
            Button(entry) { model.onHistoryEntry(entry) }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Clear", systemImage: "trash") { model.clearHistory() }
            }
        }
        .overlay { historyEmptyState }
    }

    /// Shown when nothing has been searched yet so the empty List isn't blank.
    @ViewBuilder private var historyEmptyState: some View {
        if model.historyEntries.isEmpty {
            ContentUnavailableView("No recent searches", systemImage: "magnifyingglass")
        }
    }
}
