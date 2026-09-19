import SwiftUI

/// Movies-browser layout: a horizontal category chip strip (the channel-list
/// group-strip idiom, ``ChannelGroupPickerView``) above a full-width adaptive
/// poster grid that fills the canvas on every platform. Replaces the old
/// sidebar-column split that stranded most of the width and drew a lone divider
/// hairline in the empty state; the grid's column minimum narrows on compact
/// iPhone so portrait still lands ≥3 poster columns.
extension VodBrowseScreen {
    var columns: [GridItem] {
        [GridItem(.adaptive(minimum: CompactLayout.posterColumnMinimum(sizeClass)), spacing: 16)]
    }

    @ViewBuilder var categoryChips: some View {
        ChannelGroupPickerView(groups: model.categories,
                               selected: model.selected ?? "",
                               onSelect: { model.select($0) })
    }

    var grid: some View {
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

    @ViewBuilder var emptyState: some View {
        if model.isEmpty {
            ContentUnavailableView("No movies", systemImage: "film")
        }
    }
}
