import SwiftUI

/// The Movies browser (Apple mirror of Android's VOD screen): a category column
/// beside an adaptive poster grid for the selected category, an empty state when
/// no movies are imported, and a "Movies" navigation title. Selecting a card
/// hits the `onPlay` seam — a lightweight placeholder cover this slice, wired to
/// real playback in a later slice. Logic lives in ``VodBrowseModel``.
struct VodBrowseScreen: View {
    @State private var model: VodBrowseModel
    @State private var target: VodPlayTarget?
    private let columns = [GridItem(.adaptive(minimum: 120), spacing: 16)]

    init(model: VodBrowseModel) { _model = State(initialValue: model) }

    var body: some View {
        HStack(spacing: 0) {
            categoryColumn
            Divider()
            grid
        }
        .navigationTitle("Movies")
        .overlay { emptyState }
        .task { model.load() }
        .fullScreenCover(item: $target) { placeholder($0) }
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

    private func placeholder(_ target: VodPlayTarget) -> some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 16) {
                Text("Playback lands in a later slice").foregroundStyle(.white)
                Button("Close") { self.target = nil }
            }
        }
    }
}

/// Boxes the tapped movie's `itemKey` so `.fullScreenCover(item:)` has an
/// `Identifiable` — the `onPlay` seam a later slice swaps for real playback.
struct VodPlayTarget: Identifiable {
    let key: String
    var id: String { key }
}
