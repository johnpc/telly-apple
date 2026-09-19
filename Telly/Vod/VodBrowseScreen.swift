import SwiftUI

/// The Movies browser (Apple mirror of Android's VOD screen): a horizontal
/// category chip strip above a full-width adaptive poster grid that fills the
/// canvas on every platform, an empty state when no movies are imported, and a
/// "Movies" navigation title. Selecting a card presents ``VodPlaybackScreen``
/// full-screen, built via the injected `makePlaybackModel` factory; on exit the
/// browser reloads so a just-watched card's Continue-watching bar updates. Layout
/// lives in ``VodBrowseScreen`` `+Grid`; logic in ``VodBrowseModel``.
struct VodBrowseScreen: View {
    @State var model: VodBrowseModel
    @State var target: VodPlayTarget?
    @Environment(\.horizontalSizeClass) var sizeClass
    let makePlaybackModel: (String, @escaping () -> Void) -> VodPlaybackModel

    init(model: VodBrowseModel,
         makePlaybackModel: @escaping (String, @escaping () -> Void) -> VodPlaybackModel) {
        _model = State(initialValue: model)
        self.makePlaybackModel = makePlaybackModel
    }

    var body: some View {
        VStack(spacing: 0) {
            if !model.categories.isEmpty { categoryChips }
            grid
        }
        .navigationTitle("Movies")
        .overlay { emptyState }
        .task { model.load() }
        .fullScreenCover(item: $target) { player($0) }
    }

    func player(_ target: VodPlayTarget) -> some View {
        VodPlaybackScreen(model: makePlaybackModel(target.key) {
            self.target = nil
            model.load()
        })
    }
}

/// Boxes the tapped movie's `itemKey` so `.fullScreenCover(item:)` has an
/// `Identifiable` handle to build the playback model from.
struct VodPlayTarget: Identifiable {
    let key: String
    var id: String { key }
}
