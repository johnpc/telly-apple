import SwiftUI

/// The Movies browser (Apple mirror of Android's VOD screen): a category column
/// beside an adaptive poster grid for the selected category, an empty state when
/// no movies are imported, and a "Movies" navigation title. Selecting a card
/// presents ``VodPlaybackScreen`` full-screen, built via the injected
/// `makePlaybackModel` factory; on exit the browser reloads so a just-watched
/// card's Continue-watching bar updates. Logic lives in ``VodBrowseModel``.
struct VodBrowseScreen: View {
    @State private var model: VodBrowseModel
    @State private var target: VodPlayTarget?
    let makePlaybackModel: (String, @escaping () -> Void) -> VodPlaybackModel
    // A poster-sized adaptive minimum: 120 packed a 13" iPad / tvOS row with many
    // tiny columns and stranded wide trailing whitespace; ~168 fills the canvas
    // with fewer, poster-scale columns while iPhone still lands on a sensible 1–2.
    private let columns = [GridItem(.adaptive(minimum: 168), spacing: 16)]

    init(model: VodBrowseModel,
         makePlaybackModel: @escaping (String, @escaping () -> Void) -> VodPlaybackModel) {
        _model = State(initialValue: model)
        self.makePlaybackModel = makePlaybackModel
    }

    var body: some View {
        HStack(spacing: 0) {
            categoryColumn
            Divider()
            grid
        }
        .navigationTitle("Movies")
        .overlay { emptyState }
        .task { model.load() }
        .fullScreenCover(item: $target) { player($0) }
    }

    @ViewBuilder private var categoryColumn: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(model.categories, id: \.self) { category in
                    Button(category) { model.select(category) }
                        .buttonStyle(.plain)
                        .fontWeight(model.selected == category ? .bold : .regular)
                }
            }
            .padding()
        }
        .frame(maxWidth: 220)
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(model.cards) { card in
                    Button { target = VodPlayTarget(key: card.item.itemKey) } label: {
                        VodCardView(card: card)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }

    @ViewBuilder private var emptyState: some View {
        if model.isEmpty {
            ContentUnavailableView("No movies", systemImage: "film")
        }
    }

    private func player(_ target: VodPlayTarget) -> some View {
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
