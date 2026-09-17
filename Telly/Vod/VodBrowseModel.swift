import Foundation

/// The Movies browser's observable state (Apple mirror of Android's VOD browse
/// view-model): the category column, the selected category, its cards, and an
/// `isEmpty` flag. `load` reads items and positions ONCE from the injected
/// stores and republishes — the explicit-snapshot convention of
/// ``HistoryListModel``, not reactive Flows. `select` swaps the visible cards.
@MainActor
@Observable
final class VodBrowseModel {
    let itemStore: VodItemStore
    let positionStore: VodPositionStore
    var categories: [String] = []
    var selected: String?
    var cards: [VodCard] = []

    private var items: [VodItem] = []
    private var positions: [VodPosition] = []

    var isEmpty: Bool { items.isEmpty }

    init(itemStore: VodItemStore, positionStore: VodPositionStore) {
        self.itemStore = itemStore
        self.positionStore = positionStore
    }

    /// (Re)loads the movies and resume positions, defaulting the selection to
    /// the first category and republishing that category's cards.
    func load() {
        items = (try? itemStore.all()) ?? []
        positions = (try? positionStore.all()) ?? []
        categories = VodBrowse.categories(items)
        select(categories.first)
    }

    /// Switches the visible category and republishes its cards.
    func select(_ category: String?) {
        selected = category
        cards = VodBrowse.cards(items: items, positions: positions, category: category)
    }
}
